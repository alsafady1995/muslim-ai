-- Free-tier AI guard (docs/strategy/financial-viability.md, action #1).
--
-- Before this migration a free user could cost up to $0.15 a month in AI, about four times the
-- ≈ $0.04 a month an average active user brings in, every guest (anonymous) account got its own
-- $0.15, and nothing capped total free spend. A viral spike or a script creating guest accounts
-- could run up a bill no revenue covers. Three changes:
--
--   1. Free monthly AI budget $0.15 -> $0.05. Still enough for the whole free weekly recitation
--      allowance (10 checks of up to 60 s) at the conservative ASR rate the edge functions use.
--   2. Guest accounts get their own tier: the one free onboarding Al-Fatiha check works (it is
--      uncounted), every other AI call asks them to create a free account first. Linking the
--      account keeps the same month's spend, so signing in does not reset anything.
--   3. A global daily ceiling on free and guest AI spend (`free_daily_pool_usd`, UTC day).
--      When it is reached, free AI pauses until midnight UTC; Premium, trials and everything
--      that is not AI keep working. Raise it with SQL as the user base grows.
--
-- Paying users are unaffected: their budget stays 50% of what they paid.

-- ---------------------------------------------------------------------------
-- Settings
-- ---------------------------------------------------------------------------
-- Only lower the free budget if it is still the original default (respect a hand-tuned value).
update public.ai_budget_settings
   set value = 0.05,
       note = 'AI budget for free (signed-in) users per calendar month (USD). Keep below what an average user earns us'
 where key = 'free_monthly_usd' and value = 0.15;

insert into public.ai_budget_settings (key, value, note) values
  ('guest_monthly_usd',   0.01, 'AI budget for guest (anonymous) accounts per calendar month (USD); covers the onboarding check only'),
  ('free_daily_pool_usd', 20,   'Max total AI spend per UTC day across all free and guest users (USD). Raise as the user base grows')
on conflict (key) do nothing;

-- ---------------------------------------------------------------------------
-- Guest tier
-- ---------------------------------------------------------------------------
alter table public.ai_spend drop constraint if exists ai_spend_tier_check;
alter table public.ai_spend add constraint ai_spend_tier_check
  check (tier in ('free', 'guest', 'trial', 'premium', 'promo'));

-- Supabase marks anonymous sign-ins on auth.users.is_anonymous.
create or replace function public._is_guest(p_user uuid) returns boolean
language sql stable security definer set search_path = public, auth as $$
  select coalesce((select u.is_anonymous from auth.users u where u.id = p_user), false)
$$;
revoke execute on function public._is_guest(uuid) from public, anon, authenticated;

-- Same as 20261124000004 except the free branch, which now splits free and guest.
create or replace function public._ai_budget_window(p_user uuid)
returns table (tier text, window_start timestamptz, window_end timestamptz, budget_usd numeric,
               pace_start timestamptz, pace_end timestamptz, pace_budget_usd numeric)
language plpgsql stable security definer set search_path = public as $$
declare
  s public.subscriptions%rowtype;
  v_month_start timestamptz := date_trunc('month', now() at time zone 'UTC') at time zone 'UTC';
  v_anchor timestamptz;
  v_months int;
  v_n int;
  v_net numeric;
  v_m int;
begin
  pace_start := null; pace_end := null; pace_budget_usd := null;
  if public.is_premium(p_user) then
    select * into s from public.subscriptions where user_id = p_user;

    if s.period_type = 'trial' then
      tier := 'trial';
      window_start := coalesce(s.period_start, v_month_start);
      window_end := greatest(coalesce(s.current_period_end, window_start + interval '7 days'), window_start + interval '1 day');
      budget_usd := public._ai_setting('trial_budget_usd');
      return next;
      return;
    end if;

    if s.store = 'promotional' then
      tier := 'promo';
      window_start := v_month_start;
      window_end := v_month_start + interval '1 month';
      budget_usd := public._ai_setting('promo_monthly_usd');
      return next;
      return;
    end if;

    tier := 'premium';
    v_months := greatest(coalesce(s.period_months, 1), 1);
    v_net := coalesce(s.net_revenue_usd, public._ai_setting('fallback_net_monthly_usd') * v_months);
    budget_usd := round(greatest(v_net, 0) * public._ai_setting('cost_share'), 6);

    v_anchor := coalesce(s.period_start, v_month_start);
    if v_anchor > now() then v_anchor := v_month_start; end if;
    v_n := public._months_since(v_anchor, now()) / v_months;
    window_start := v_anchor + make_interval(months => v_n * v_months);
    window_end := v_anchor + make_interval(months => (v_n + 1) * v_months);

    if v_months > 1 then
      v_m := public._months_since(window_start, now());
      pace_start := window_start + make_interval(months => v_m);
      pace_end := least(window_start + make_interval(months => v_m + 1), window_end);
      pace_budget_usd := round(budget_usd / v_months * public._ai_setting('annual_pace_multiple'), 6);
    end if;
    return next;
    return;
  end if;

  window_start := v_month_start;
  window_end := v_month_start + interval '1 month';
  if public._is_guest(p_user) then
    tier := 'guest';
    budget_usd := public._ai_setting('guest_monthly_usd');
  else
    tier := 'free';
    budget_usd := public._ai_setting('free_monthly_usd');
  end if;
  return next;
end $$;

-- ---------------------------------------------------------------------------
-- Global daily pool for free and guest AI
-- ---------------------------------------------------------------------------
create table if not exists public.ai_free_pool (
  day date primary key,                                   -- UTC day
  used_usd numeric(12, 6) not null default 0,             -- reservations at reservation, the rest at cost
  calls int not null default 0,
  refused int not null default 0,                         -- calls turned away because the pool was full
  updated_at timestamptz not null default now()
);
alter table public.ai_free_pool enable row level security;
revoke all on public.ai_free_pool from anon, authenticated;

-- Which pool day a call was charged to (null for paid tiers), so settling adjusts the right row.
alter table public.ai_calls add column if not exists pool_day date;

-- ---------------------------------------------------------------------------
-- begin_ai_call: same as 20261124000004 plus the guest rule and the daily pool
-- ---------------------------------------------------------------------------
create or replace function public.begin_ai_call(
  p_user uuid,
  p_feature public.ai_feature,
  p_reserve_usd numeric,
  p_fallback_reserve_usd numeric default null,
  p_count_usage boolean default true
) returns jsonb language plpgsql security definer set search_path = public as $$
declare
  w record;
  sp public.ai_spend%rowtype;
  v_premium boolean := public.is_premium(p_user);
  v_week date := public._user_week_start(p_user);
  v_week_resets timestamptz := public._user_week_resets_at(p_user);
  v_core boolean := p_feature::text in ('recitation', 'hifz');
  v_limit int;
  v_count int := 0;
  v_available numeric;
  v_window_left numeric;
  v_pace_left numeric;
  v_reserve numeric;
  v_degraded boolean := false;
  v_budget_resets timestamptz;
  v_call bigint;
  v_pool_day date;
  v_pool_used numeric;
begin
  perform public._expire_stale_ai_calls(p_user);
  select * into w from public._ai_budget_window(p_user);

  -- Guests get the uncounted onboarding check only; everything else needs a free account.
  if w.tier = 'guest' and p_count_usage then
    return jsonb_build_object('allowed', false, 'reason', 'sign_in', 'premium', false, 'tier', 'guest');
  end if;

  insert into public.ai_spend (user_id, window_start, window_end, tier, budget_usd)
  values (p_user, w.window_start, w.window_end, w.tier, w.budget_usd)
  on conflict (user_id, window_start) do nothing;
  update public.ai_spend set budget_usd = w.budget_usd, tier = w.tier, window_end = w.window_end
   where user_id = p_user and window_start = w.window_start
  returning * into sp;

  v_window_left := sp.budget_usd - sp.spent_usd - sp.reserved_usd;
  v_available := v_window_left;
  v_budget_resets := w.window_end;
  if not v_core then
    v_available := least(v_available,
      sp.budget_usd * (1 - public._ai_setting('core_share')) - public._ai_window_used(p_user, w.window_start, false, null));
  end if;
  if w.pace_start is not null then
    v_pace_left := w.pace_budget_usd - public._ai_window_used(p_user, w.window_start, null, w.pace_start);
    if v_pace_left < v_available then
      v_available := v_pace_left;
      if v_pace_left < v_window_left then v_budget_resets := w.pace_end; end if;
    end if;
  end if;

  if not v_premium and p_fallback_reserve_usd is not null then
    v_reserve := case when p_fallback_reserve_usd <= v_available then p_fallback_reserve_usd end;
  elsif p_reserve_usd <= v_available then
    v_reserve := p_reserve_usd;
  elsif p_fallback_reserve_usd is not null and p_fallback_reserve_usd <= v_available then
    v_reserve := p_fallback_reserve_usd;
    v_degraded := true;
  end if;
  if v_reserve is null then
    return jsonb_build_object(
      'allowed', false, 'reason', 'budget', 'premium', v_premium, 'tier', w.tier,
      'budget_usd', sp.budget_usd, 'spent_usd', sp.spent_usd + sp.reserved_usd,
      'resets_at', v_budget_resets);
  end if;

  -- Daily pool for free and guest users. The row lock serialises free calls, so concurrent
  -- requests cannot overshoot the ceiling.
  if w.tier in ('free', 'guest') then
    v_pool_day := (now() at time zone 'UTC')::date;
    insert into public.ai_free_pool (day) values (v_pool_day) on conflict (day) do nothing;
    select used_usd into v_pool_used from public.ai_free_pool where day = v_pool_day for update;
    if v_pool_used + v_reserve > public._ai_setting('free_daily_pool_usd') then
      update public.ai_free_pool set refused = refused + 1, updated_at = now() where day = v_pool_day;
      return jsonb_build_object(
        'allowed', false, 'reason', 'free_pool', 'premium', false, 'tier', w.tier,
        'resets_at', ((v_pool_day + 1)::timestamp at time zone 'UTC'));
    end if;
  end if;

  select case when v_premium then premium_weekly else free_weekly end into v_limit
    from public.plan_limits where feature = p_feature;
  if p_count_usage then
    insert into public.ai_usage (user_id, usage_date, feature, count) values (p_user, v_week, p_feature, 0)
    on conflict do nothing;
    update public.ai_usage set count = count + 1
     where user_id = p_user and usage_date = v_week and feature = p_feature and count < v_limit
    returning count into v_count;
    if v_count is null then
      return jsonb_build_object('allowed', false, 'reason', 'weekly_limit', 'premium', v_premium,
                                'tier', w.tier, 'limit', v_limit, 'remaining', 0, 'period', 'week',
                                'resets_at', v_week_resets);
    end if;
  else
    select coalesce((select count from public.ai_usage
                      where user_id = p_user and usage_date = v_week and feature = p_feature), 0) into v_count;
  end if;

  if v_pool_day is not null then
    update public.ai_free_pool set used_usd = used_usd + v_reserve, calls = calls + 1, updated_at = now()
     where day = v_pool_day;
  end if;
  update public.ai_spend set reserved_usd = reserved_usd + v_reserve, calls = calls + 1, updated_at = now()
   where user_id = p_user and window_start = w.window_start;
  insert into public.ai_calls (user_id, feature, window_start, usage_date, degraded, reserved_usd, counted, pool_day)
  values (p_user, p_feature, w.window_start, v_week, v_degraded, v_reserve, p_count_usage, v_pool_day)
  returning id into v_call;

  return jsonb_build_object(
    'allowed', true, 'call_id', v_call, 'degraded', v_degraded, 'premium', v_premium, 'tier', w.tier,
    'limit', v_limit, 'remaining', greatest(v_limit - v_count, 0), 'period', 'week',
    'usage_resets_at', v_week_resets,
    'budget_usd', sp.budget_usd, 'spent_usd', sp.spent_usd + sp.reserved_usd + v_reserve,
    'resets_at', v_budget_resets);
end $$;

-- ---------------------------------------------------------------------------
-- finish / cancel: also move the pool from the reservation to the measured cost.
-- (Expired reservations count as spent at their reservation, which the pool already holds.)
-- ---------------------------------------------------------------------------
create or replace function public.finish_ai_call(p_call bigint, p_cost_usd numeric, p_model text default null,
                                                 p_details jsonb default null)
returns void language plpgsql security definer set search_path = public as $$
declare c public.ai_calls%rowtype;
begin
  update public.ai_calls set status = 'settled', cost_usd = greatest(p_cost_usd, 0), model = p_model,
                             details = p_details, settled_at = now()
   where id = p_call and status = 'reserved'
  returning * into c;
  if c.id is null then return; end if;
  update public.ai_spend
     set reserved_usd = greatest(reserved_usd - c.reserved_usd, 0),
         spent_usd = spent_usd + c.cost_usd,
         updated_at = now()
   where user_id = c.user_id and window_start = c.window_start;
  if c.pool_day is not null then
    update public.ai_free_pool set used_usd = greatest(used_usd - c.reserved_usd + c.cost_usd, 0), updated_at = now()
     where day = c.pool_day;
  end if;
end $$;

create or replace function public.cancel_ai_call(p_call bigint, p_cost_usd numeric default 0)
returns void language plpgsql security definer set search_path = public as $$
declare c public.ai_calls%rowtype;
begin
  update public.ai_calls set status = 'cancelled', cost_usd = greatest(p_cost_usd, 0), settled_at = now()
   where id = p_call and status = 'reserved'
  returning * into c;
  if c.id is null then return; end if;
  update public.ai_spend
     set reserved_usd = greatest(reserved_usd - c.reserved_usd, 0),
         spent_usd = spent_usd + c.cost_usd,
         updated_at = now()
   where user_id = c.user_id and window_start = c.window_start;
  if c.pool_day is not null then
    update public.ai_free_pool set used_usd = greatest(used_usd - c.reserved_usd + c.cost_usd, 0), updated_at = now()
     where day = c.pool_day;
  end if;
  if c.counted then
    update public.ai_usage set count = greatest(count - 1, 0)
     where user_id = c.user_id and usage_date = c.usage_date and feature = c.feature;
  end if;
end $$;

-- These stay service-role only, like the versions they replace.
revoke execute on function public.begin_ai_call(uuid, public.ai_feature, numeric, numeric, boolean) from public, anon, authenticated;
revoke execute on function public.finish_ai_call(bigint, numeric, text, jsonb) from public, anon, authenticated;
revoke execute on function public.cancel_ai_call(bigint, numeric) from public, anon, authenticated;
revoke execute on function public._ai_budget_window(uuid) from public, anon, authenticated;
grant execute on all functions in schema public to service_role;
grant all on public.ai_free_pool to service_role;
