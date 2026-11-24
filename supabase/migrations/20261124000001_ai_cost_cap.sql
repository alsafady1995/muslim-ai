-- AI cost cap: no user may cost more in AI than half of what they pay us.
--
-- How it works
--   * The RevenueCat webhook stores what each subscriber actually paid for the current
--     period (USD, after store commission and tax) on public.subscriptions.
--   * Each user gets an AI budget per window:
--       premium   cost_share x net revenue per month, in monthly windows from the purchase date
--                 (annual plans are split into 12 monthly windows)
--       trial     a small fixed budget for the whole free trial (they have paid nothing yet)
--       promo     promotional grants pay nothing, so they get the free-tier cap
--       free      a small fixed monthly budget (calendar month, UTC)
--   * Edge functions call begin_ai_call() before any paid AI work. It reserves the worst-case
--     cost of the call atomically (row lock), so concurrent calls cannot overshoot the budget.
--     finish_ai_call() replaces the reservation with the measured cost; cancel_ai_call()
--     releases it. If the full model does not fit but a cheaper one does, the call is allowed
--     in "degraded" mode and the function uses the cheaper model.
--   * Everything is server-side; the app only displays the result.

-- ---------------------------------------------------------------------------
-- Settings (change with SQL, no deploy needed)
-- ---------------------------------------------------------------------------
create table public.ai_budget_settings (
  key text primary key,
  value numeric not null check (value >= 0),
  note text
);
insert into public.ai_budget_settings (key, value, note) values
  ('cost_share',               0.50, 'Max share of a subscriber''s net payment that AI may cost per window'),
  ('free_monthly_usd',         0.15, 'AI budget for free users per calendar month (USD)'),
  ('trial_budget_usd',         0.25, 'AI budget for the whole 7-day free trial (USD); trial users have paid nothing yet'),
  ('promo_monthly_usd',        0.15, 'AI budget per month for promotional (unpaid) premium grants (USD)'),
  ('fallback_net_monthly_usd', 0.40, 'Net revenue per month assumed when the store did not report a price; set to the lowest regional tier so we never over-allow'),
  ('stale_reservation_minutes', 15,  'Reservations older than this are assumed spent (the function crashed mid-call)')
on conflict (key) do nothing;

create or replace function public._ai_setting(p_key text) returns numeric
language sql stable security definer set search_path = public as $$
  select value from public.ai_budget_settings where key = p_key
$$;

-- ---------------------------------------------------------------------------
-- What the subscriber paid for the current period (filled by revenuecat-webhook)
-- ---------------------------------------------------------------------------
alter table public.subscriptions
  add column price_usd numeric(10, 4),        -- gross price of the last transaction, USD
  add column net_revenue_usd numeric(10, 4),  -- after store commission and tax, USD; 0 after a refund
  add column period_start timestamptz,        -- purchase / renewal time of the last transaction
  add column period_months smallint,          -- 1 for monthly, 12 for annual
  add column country_code text,
  add column currency text;

-- ---------------------------------------------------------------------------
-- Spend per user per window, and a per-call ledger
-- ---------------------------------------------------------------------------
create table public.ai_spend (
  user_id uuid not null references public.profiles (id) on delete cascade,
  window_start timestamptz not null,
  window_end timestamptz not null,
  tier text not null check (tier in ('free', 'trial', 'premium', 'promo')),
  budget_usd numeric(12, 6) not null,
  spent_usd numeric(12, 6) not null default 0,
  reserved_usd numeric(12, 6) not null default 0,
  calls int not null default 0,
  updated_at timestamptz not null default now(),
  primary key (user_id, window_start)
);

create table public.ai_calls (
  id bigint generated always as identity primary key,
  user_id uuid not null references public.profiles (id) on delete cascade,
  feature public.ai_feature not null,
  window_start timestamptz not null,
  usage_date date not null,
  status text not null default 'reserved' check (status in ('reserved', 'settled', 'cancelled', 'expired')),
  degraded boolean not null default false,
  reserved_usd numeric(12, 6) not null,
  cost_usd numeric(12, 6),
  model text,
  details jsonb,
  created_at timestamptz not null default now(),
  settled_at timestamptz
);
create index ai_calls_user_open on public.ai_calls (user_id, created_at) where status = 'reserved';
create index ai_calls_user_time on public.ai_calls (user_id, created_at desc);

alter table public.ai_budget_settings enable row level security;
alter table public.ai_calls enable row level security;
alter table public.ai_spend enable row level security;
create policy ai_spend_own_read on public.ai_spend for select to authenticated using (user_id = auth.uid());
revoke all on public.ai_budget_settings, public.ai_calls from anon, authenticated;
revoke insert, update, delete on public.ai_spend from anon, authenticated;

-- ---------------------------------------------------------------------------
-- Budget window for a user right now
-- ---------------------------------------------------------------------------
create or replace function public._ai_budget_window(p_user uuid)
returns table (tier text, window_start timestamptz, window_end timestamptz, budget_usd numeric)
language plpgsql stable security definer set search_path = public as $$
declare
  s public.subscriptions%rowtype;
  v_month_start timestamptz := date_trunc('month', now() at time zone 'UTC') at time zone 'UTC';
  v_anchor timestamptz;
  v_n int;
  v_net_month numeric;
begin
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
    v_net_month := coalesce(
      s.net_revenue_usd / greatest(coalesce(s.period_months, 1), 1),
      public._ai_setting('fallback_net_monthly_usd'));
    budget_usd := round(greatest(v_net_month, 0) * public._ai_setting('cost_share'), 6);

    -- Monthly windows anchored on the purchase / renewal date.
    v_anchor := coalesce(s.period_start, v_month_start);
    if v_anchor > now() then v_anchor := v_month_start; end if;
    v_n := (extract(year from age(now(), v_anchor)) * 12 + extract(month from age(now(), v_anchor)))::int;
    if v_anchor + make_interval(months => v_n + 1) <= now() then v_n := v_n + 1; end if;
    window_start := v_anchor + make_interval(months => v_n);
    window_end := v_anchor + make_interval(months => v_n + 1);
    return next;
    return;
  end if;

  tier := 'free';
  window_start := v_month_start;
  window_end := v_month_start + interval '1 month';
  budget_usd := public._ai_setting('free_monthly_usd');
  return next;
end $$;

-- Reservations left open by a crashed function are counted as spent (we may have paid for them).
create or replace function public._expire_stale_ai_calls(p_user uuid) returns void
language plpgsql security definer set search_path = public as $$
declare r record;
begin
  for r in
    update public.ai_calls set status = 'expired', cost_usd = reserved_usd, settled_at = now()
     where user_id = p_user and status = 'reserved'
       and created_at < now() - make_interval(mins => public._ai_setting('stale_reservation_minutes')::int)
    returning window_start, reserved_usd
  loop
    update public.ai_spend
       set reserved_usd = greatest(reserved_usd - r.reserved_usd, 0),
           spent_usd = spent_usd + r.reserved_usd,
           updated_at = now()
     where user_id = p_user and window_start = r.window_start;
  end loop;
end $$;

-- ---------------------------------------------------------------------------
-- begin / finish / cancel (service role only, called by edge functions)
-- ---------------------------------------------------------------------------
-- p_reserve_usd: worst-case cost of the call with the premium model (or the only option).
-- p_fallback_reserve_usd: worst-case cost with the cheaper model, or null when there is none.
--   Free users always use the cheaper model. Premium users drop to it ("degraded") only when
--   the premium model no longer fits the remaining budget.
create or replace function public.begin_ai_call(
  p_user uuid,
  p_feature public.ai_feature,
  p_reserve_usd numeric,
  p_fallback_reserve_usd numeric default null
) returns jsonb language plpgsql security definer set search_path = public as $$
declare
  w record;
  sp public.ai_spend%rowtype;
  v_premium boolean := public.is_premium(p_user);
  v_today date := public._user_today(p_user);
  v_limit int;
  v_count int;
  v_available numeric;
  v_reserve numeric;
  v_degraded boolean := false;
  v_call bigint;
begin
  perform public._expire_stale_ai_calls(p_user);
  select * into w from public._ai_budget_window(p_user);

  insert into public.ai_spend (user_id, window_start, window_end, tier, budget_usd)
  values (p_user, w.window_start, w.window_end, w.tier, w.budget_usd)
  on conflict (user_id, window_start) do nothing;
  -- Lock the row so concurrent calls see each other's reservations. The budget is
  -- refreshed every call so a refund or plan change takes effect immediately.
  update public.ai_spend set budget_usd = w.budget_usd, tier = w.tier, window_end = w.window_end
   where user_id = p_user and window_start = w.window_start
  returning * into sp;

  v_available := sp.budget_usd - sp.spent_usd - sp.reserved_usd;
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
      'resets_at', w.window_end);
  end if;

  -- Daily fair-use count (unchanged behaviour from consume_ai_quota)
  select case when v_premium then premium_daily else free_daily end into v_limit
    from public.plan_limits where feature = p_feature;
  insert into public.ai_usage (user_id, usage_date, feature, count) values (p_user, v_today, p_feature, 0)
  on conflict do nothing;
  update public.ai_usage set count = count + 1
   where user_id = p_user and usage_date = v_today and feature = p_feature and count < v_limit
  returning count into v_count;
  if v_count is null then
    return jsonb_build_object('allowed', false, 'reason', 'daily_limit', 'premium', v_premium,
                              'tier', w.tier, 'limit', v_limit, 'remaining', 0);
  end if;

  update public.ai_spend set reserved_usd = reserved_usd + v_reserve, calls = calls + 1, updated_at = now()
   where user_id = p_user and window_start = w.window_start;
  insert into public.ai_calls (user_id, feature, window_start, usage_date, degraded, reserved_usd)
  values (p_user, p_feature, w.window_start, v_today, v_degraded, v_reserve)
  returning id into v_call;

  return jsonb_build_object(
    'allowed', true, 'call_id', v_call, 'degraded', v_degraded, 'premium', v_premium, 'tier', w.tier,
    'limit', v_limit, 'remaining', v_limit - v_count,
    'budget_usd', sp.budget_usd, 'spent_usd', sp.spent_usd + sp.reserved_usd + v_reserve,
    'resets_at', w.window_end);
end $$;

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
end $$;

-- The AI call failed on our side: release the reservation and give the daily count back.
-- p_cost_usd lets the caller record anything that was already spent (e.g. embeddings).
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
  update public.ai_usage set count = greatest(count - 1, 0)
   where user_id = c.user_id and usage_date = c.usage_date and feature = c.feature;
end $$;

-- ---------------------------------------------------------------------------
-- What the app shows ("you've used 80% of this month's AI allowance")
-- ---------------------------------------------------------------------------
create or replace function public.get_my_ai_budget()
returns jsonb language plpgsql stable security definer set search_path = public as $$
declare
  w record;
  v_used numeric := 0;
begin
  if auth.uid() is null then return null; end if;
  select * into w from public._ai_budget_window(auth.uid());
  select spent_usd + reserved_usd into v_used from public.ai_spend
   where user_id = auth.uid() and window_start = w.window_start;
  v_used := coalesce(v_used, 0);
  return jsonb_build_object(
    'tier', w.tier,
    'used_percent', case when w.budget_usd > 0 then least(round(v_used / w.budget_usd * 100), 100) else 100 end,
    'exhausted', v_used >= w.budget_usd,
    'resets_at', w.window_end);
end $$;

revoke execute on function
  public._ai_setting(text), public._ai_budget_window(uuid), public._expire_stale_ai_calls(uuid),
  public.begin_ai_call(uuid, public.ai_feature, numeric, numeric),
  public.finish_ai_call(bigint, numeric, text, jsonb), public.cancel_ai_call(bigint, numeric),
  public.get_my_ai_budget()
  from public, anon, authenticated;
grant execute on function public.get_my_ai_budget() to authenticated;
grant execute on all functions in schema public to service_role;
