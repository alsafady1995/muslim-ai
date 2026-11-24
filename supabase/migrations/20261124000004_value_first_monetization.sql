-- "Value first, ask second" monetization (docs/subscription-growth-audit.md, docs/full-audit.md).
--
--   * Weekly AI limits that renew every Friday 00:00 in the user's time zone (was daily).
--   * AI hifz tests get their own quota, separate from recitation checks.
--   * The onboarding Al-Fatiha check is free and does not count.
--   * 40% of every AI budget is reserved for recitation and hifz, so Ask can never pause
--     the coach a subscriber pays for.
--   * Annual subscribers get their whole year's budget (still 50% of what they paid),
--     spendable at up to 3x the monthly share in any one month.
--   * All reciters are free.
--   * Value gate, weekly summary, hifz milestones, weak words and known-surah seeding
--     for the new onboarding and paywall timing.
--
-- The money rule is unchanged: no user may cost more in AI than half of what they pay.

-- ---------------------------------------------------------------------------
-- Settings
-- ---------------------------------------------------------------------------
insert into public.ai_budget_settings (key, value, note) values
  ('core_share',          0.40, 'Share of every AI budget reserved for recitation and hifz tests; Ask and search may use the rest'),
  ('annual_pace_multiple', 3,   'Annual plans: max spend in one month, as a multiple of the monthly share of the yearly budget')
on conflict (key) do nothing;

-- ---------------------------------------------------------------------------
-- Weekly limits
-- ---------------------------------------------------------------------------
alter table public.plan_limits
  add column if not exists free_weekly int,
  add column if not exists premium_weekly int;
comment on column public.plan_limits.free_daily is 'Legacy (daily limits, before 2026-11-24). Limits are weekly now.';
comment on column public.plan_limits.premium_daily is 'Legacy (daily limits, before 2026-11-24). Limits are weekly now.';

insert into public.plan_limits (feature, free_daily, premium_daily, free_weekly, premium_weekly) values
  ('recitation', 10, 150, 10, 150),
  ('hifz',        5, 150,  5, 150),
  ('ask',        15, 100, 15, 100),
  ('search',     30, 300, 30, 300)
on conflict (feature) do update set free_daily = excluded.free_daily, premium_daily = excluded.premium_daily,
                                    free_weekly = excluded.free_weekly, premium_weekly = excluded.premium_weekly;
alter table public.plan_limits alter column free_weekly set not null, alter column premium_weekly set not null;

-- Weeks start on Friday (isodow 5) in the user's time zone.
create or replace function public._week_start(p_day date) returns date
language sql immutable as $$
  select p_day - ((extract(isodow from p_day)::int - 5 + 7) % 7)
$$;

create or replace function public._user_week_start(p_user uuid) returns date
language sql stable security definer set search_path = public as $$
  select public._week_start(public._user_today(p_user))
$$;

create or replace function public._user_week_resets_at(p_user uuid) returns timestamptz
language sql stable security definer set search_path = public as $$
  select ((public._user_week_start(p_user) + 7)::timestamp
          at time zone coalesce((select timezone from public.profiles where id = p_user), 'UTC'))
$$;

-- Uncounted calls (the onboarding check) must not refund a count on cancel.
alter table public.ai_calls add column if not exists counted boolean not null default true;

-- ---------------------------------------------------------------------------
-- Budget window (adds annual pooling with monthly pacing)
-- ---------------------------------------------------------------------------
create or replace function public._months_since(p_anchor timestamptz, p_now timestamptz) returns int
language plpgsql immutable as $$
declare v_n int;
begin
  if p_anchor > p_now then return 0; end if;
  v_n := (extract(year from age(p_now, p_anchor)) * 12 + extract(month from age(p_now, p_anchor)))::int;
  if p_anchor + make_interval(months => v_n + 1) <= p_now then v_n := v_n + 1; end if;
  return v_n;
end $$;

drop function if exists public._ai_budget_window(uuid);
create function public._ai_budget_window(p_user uuid)
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
    -- The whole period's payment is already received, so the whole period's budget is spendable
    -- (still cost_share of what the user paid).
    budget_usd := round(greatest(v_net, 0) * public._ai_setting('cost_share'), 6);

    v_anchor := coalesce(s.period_start, v_month_start);
    if v_anchor > now() then v_anchor := v_month_start; end if;
    v_n := public._months_since(v_anchor, now()) / v_months;   -- whole billing periods elapsed
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

  tier := 'free';
  window_start := v_month_start;
  window_end := v_month_start + interval '1 month';
  budget_usd := public._ai_setting('free_monthly_usd');
  return next;
end $$;

-- Spend recorded against a window (reserved calls at their reservation, the rest at cost).
create or replace function public._ai_window_used(p_user uuid, p_window timestamptz, p_core boolean, p_since timestamptz)
returns numeric language sql stable security definer set search_path = public as $$
  select coalesce(sum(case when status = 'reserved' then reserved_usd else coalesce(cost_usd, 0) end), 0)
    from public.ai_calls
   where user_id = p_user and window_start = p_window
     and (p_core is null or (feature in ('recitation', 'hifz')) = p_core)
     and (p_since is null or created_at >= p_since)
$$;

-- ---------------------------------------------------------------------------
-- begin / cancel (service role only)
-- ---------------------------------------------------------------------------
drop function if exists public.begin_ai_call(uuid, public.ai_feature, numeric, numeric);
create function public.begin_ai_call(
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

  v_window_left := sp.budget_usd - sp.spent_usd - sp.reserved_usd;
  v_available := v_window_left;
  v_budget_resets := w.window_end;
  -- Ring-fence: Ask and search may only use the non-core share of the budget.
  if not v_core then
    v_available := least(v_available,
      sp.budget_usd * (1 - public._ai_setting('core_share')) - public._ai_window_used(p_user, w.window_start, false, null));
  end if;
  -- Annual pacing: at most N x the monthly share in the current month of the year.
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

  -- Weekly fair-use count (renews Friday 00:00 local time)
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

  update public.ai_spend set reserved_usd = reserved_usd + v_reserve, calls = calls + 1, updated_at = now()
   where user_id = p_user and window_start = w.window_start;
  insert into public.ai_calls (user_id, feature, window_start, usage_date, degraded, reserved_usd, counted)
  values (p_user, p_feature, w.window_start, v_week, v_degraded, v_reserve, p_count_usage)
  returning id into v_call;

  return jsonb_build_object(
    'allowed', true, 'call_id', v_call, 'degraded', v_degraded, 'premium', v_premium, 'tier', w.tier,
    'limit', v_limit, 'remaining', greatest(v_limit - v_count, 0), 'period', 'week',
    'usage_resets_at', v_week_resets,
    'budget_usd', sp.budget_usd, 'spent_usd', sp.spent_usd + sp.reserved_usd + v_reserve,
    'resets_at', v_budget_resets);
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
  if c.counted then
    update public.ai_usage set count = greatest(count - 1, 0)
     where user_id = c.user_id and usage_date = c.usage_date and feature = c.feature;
  end if;
end $$;

-- ---------------------------------------------------------------------------
-- What the app shows: weekly counts, renewal time, clip length, budget
-- ---------------------------------------------------------------------------
create or replace function public.get_my_quota()
returns jsonb language plpgsql stable security definer set search_path = public as $$
declare
  v_user uuid := auth.uid();
  v_premium boolean;
  v_week date;
begin
  if v_user is null then raise exception 'not authenticated'; end if;
  v_premium := public.is_premium(v_user);
  v_week := public._user_week_start(v_user);
  return jsonb_build_object(
    'premium', v_premium,
    'period', 'week',
    'resets_at', public._user_week_resets_at(v_user),
    'clip_seconds', case when v_premium then 180 else 60 end,
    'onboarding_check_available', not exists (select 1 from public.recitation_sessions
                                               where user_id = v_user and status in ('processing', 'done')),
    'features', coalesce((select jsonb_object_agg(l.feature, jsonb_build_object(
        'limit', case when v_premium then l.premium_weekly else l.free_weekly end,
        'used', coalesce(u.count, 0)))
      from public.plan_limits l
      left join public.ai_usage u on u.feature = l.feature and u.user_id = v_user and u.usage_date = v_week), '{}'::jsonb));
end $$;

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

-- ---------------------------------------------------------------------------
-- All reciters are free (locking the Haram imams in a Saudi launch costs more in
-- reviews than it earns).
-- ---------------------------------------------------------------------------
update public.reciters set is_premium = false;

-- ---------------------------------------------------------------------------
-- Known surahs (onboarding) and hifz milestones
-- ---------------------------------------------------------------------------
alter table public.hifz_plans add column if not exists review_only boolean not null default false;

create table if not exists public.hifz_milestones (
  user_id uuid not null references public.profiles (id) on delete cascade,
  kind text not null check (kind in ('surah_memorized')),
  ref int not null,
  seeded boolean not null default false,   -- known before the user joined: never celebrated
  reached_at timestamptz not null default now(),
  primary key (user_id, kind, ref)
);
alter table public.hifz_milestones enable row level security;
create policy hifz_milestones_own_read on public.hifz_milestones for select to authenticated using (user_id = auth.uid());
revoke insert, update, delete on public.hifz_milestones from anon, authenticated;

create or replace function public.create_hifz_plan(p_start_ayah int, p_end_ayah int, p_daily_new smallint default 3, p_title text default null)
returns uuid language plpgsql security definer set search_path = public as $$
declare
  v_user uuid := auth.uid();
  v_plan uuid;
begin
  if v_user is null then raise exception 'not authenticated'; end if;
  if p_end_ayah < p_start_ayah or p_end_ayah - p_start_ayah > 6235 then raise exception 'invalid range'; end if;
  if (select count(*) from public.hifz_plans where user_id = v_user and active and not review_only) >= 3 then
    raise exception 'maximum 3 active plans';
  end if;
  insert into public.hifz_plans (user_id, title, start_ayah_id, end_ayah_id, daily_new_ayahs)
  values (v_user, p_title, p_start_ayah, p_end_ayah, p_daily_new) returning id into v_plan;
  insert into public.hifz_items (user_id, plan_id, ayah_id)
  select v_user, v_plan, a.id from public.ayahs a
   where a.id between p_start_ayah and p_end_ayah
  on conflict (user_id, ayah_id) do nothing;   -- ayah already in another plan
  return v_plan;
end $$;

-- Surahs the user already knows go straight into review, spread over the next 6 days
-- so day 1 has a short, achievable session.
create or replace function public.seed_known_surahs(p_surahs int[], p_title text default null)
returns jsonb language plpgsql security definer set search_path = public as $$
declare
  v_user uuid := auth.uid();
  v_today date;
  v_plan uuid;
  v_items int;
begin
  if v_user is null then raise exception 'not authenticated'; end if;
  if p_surahs is null or cardinality(p_surahs) = 0 then
    return jsonb_build_object('plan_id', null, 'items', 0);
  end if;
  if cardinality(p_surahs) > 114 or exists (select 1 from unnest(p_surahs) s where s not between 1 and 114) then
    raise exception 'invalid surahs';
  end if;
  v_today := public._user_today(v_user);
  insert into public.hifz_plans (user_id, title, start_ayah_id, end_ayah_id, daily_new_ayahs, review_only)
  select v_user, coalesce(p_title, 'known'), min(a.id), max(a.id), 1, true
    from public.ayahs a where a.surah_id = any (p_surahs)
  having count(*) > 0
  returning id into v_plan;
  if v_plan is null then return jsonb_build_object('plan_id', null, 'items', 0); end if;

  insert into public.hifz_items (user_id, plan_id, ayah_id, status, ease_factor, interval_days, repetitions,
                                 due_date, introduced_on, last_reviewed_at, last_score)
  select v_user, v_plan, a.id, 'review', 2.5, 3, 2,
         v_today + 1 + ((dense_rank() over (order by a.surah_id desc) - 1) % 6)::int,
         v_today, now() - interval '2 days', 4
    from public.ayahs a where a.surah_id = any (p_surahs)
  on conflict (user_id, ayah_id) do nothing;
  get diagnostics v_items = row_count;

  insert into public.hifz_milestones (user_id, kind, ref, seeded)
  select v_user, 'surah_memorized', s, true from unnest(p_surahs) s
  on conflict do nothing;
  return jsonb_build_object('plan_id', v_plan, 'items', v_items);
end $$;

-- SM-2 update (unchanged) + "surah memorized" milestone.
create or replace function public._hifz_apply_review(p_user uuid, p_item bigint, p_score smallint,
                                                    p_source public.review_source, p_recitation uuid)
returns jsonb language plpgsql security definer set search_path = public as $$
declare
  i public.hifz_items;
  v_today date := public._user_today(p_user);
  v_ef numeric;
  v_interval int;
  v_reps int;
  v_lapses int;
  v_status public.hifz_status;
  v_was_new boolean;
  v_activity jsonb;
  v_surah smallint;
  v_ayah_count int;
  v_done int;
  v_inserted int;
  v_milestone jsonb;
begin
  select * into i from public.hifz_items where id = p_item and user_id = p_user for update;
  if not found then raise exception 'item not found'; end if;
  if p_score < 0 or p_score > 5 then raise exception 'score out of range'; end if;
  v_was_new := i.status = 'new';

  v_ef := greatest(1.3, i.ease_factor + (0.1 - (5 - p_score) * (0.08 + (5 - p_score) * 0.02)));
  v_lapses := i.lapses;
  if p_score < 3 then
    v_reps := 0;
    v_interval := 1;
    if not v_was_new then v_lapses := v_lapses + 1; end if;
    v_status := 'learning';
  else
    v_reps := i.repetitions + 1;
    v_interval := case v_reps when 1 then 1 when 2 then 3 else ceil(greatest(i.interval_days, 1) * v_ef)::int end;
    v_interval := least(v_interval, 180);
    v_status := case when v_interval >= 30 then 'mastered'::public.hifz_status
                     when v_reps >= 2 then 'review'::public.hifz_status
                     else 'learning'::public.hifz_status end;
  end if;

  update public.hifz_items
     set ease_factor = v_ef, interval_days = v_interval, repetitions = v_reps, lapses = v_lapses,
         status = v_status, due_date = v_today + v_interval, last_reviewed_at = now(), last_score = p_score,
         introduced_on = coalesce(introduced_on, v_today)
   where id = p_item;

  insert into public.hifz_reviews (user_id, item_id, score, source, recitation_id)
  values (p_user, p_item, p_score, p_source, p_recitation);

  if v_was_new and p_score >= 3 then
    v_activity := public._log_activity(p_user, 'ayah_memorized', 1, p_item::text);
  else
    v_activity := public._log_activity(p_user, 'hifz_review', 1, p_item::text);
  end if;

  -- Milestone: every ayah of this surah is now memorized (review or mastered).
  if v_status in ('review', 'mastered') then
    select a.surah_id into v_surah from public.ayahs a where a.id = i.ayah_id;
    select s.ayah_count into v_ayah_count from public.surahs s where s.id = v_surah;
    select count(*) into v_done from public.hifz_items hi join public.ayahs a on a.id = hi.ayah_id
     where hi.user_id = p_user and a.surah_id = v_surah and hi.status in ('review', 'mastered');
    if v_done >= v_ayah_count then
      insert into public.hifz_milestones (user_id, kind, ref) values (p_user, 'surah_memorized', v_surah)
      on conflict do nothing;
      get diagnostics v_inserted = row_count;
      if v_inserted > 0 then
        perform public._award_xp(p_user, 100, 'surah_memorized', v_surah::text);
        select jsonb_build_object(
                 'kind', 'surah_memorized', 'surah_id', s.id, 'name_ar', s.name_ar, 'name_en', s.name_en,
                 'transliteration', s.transliteration, 'xp', 100,
                 'first', (select count(*) from public.hifz_milestones m
                            where m.user_id = p_user and m.kind = 'surah_memorized' and not m.seeded) = 1)
          into v_milestone from public.surahs s where s.id = v_surah;
      end if;
    end if;
  end if;

  return jsonb_build_object('item_id', p_item, 'status', v_status, 'interval_days', v_interval,
                            'due_date', v_today + v_interval, 'ease_factor', v_ef, 'milestone', v_milestone)
         || v_activity;
end $$;

-- ---------------------------------------------------------------------------
-- Dashboard: value gate, subscription state, at-risk count
-- ---------------------------------------------------------------------------
create or replace function public.get_dashboard()
returns jsonb language plpgsql stable security definer set search_path = public as $$
declare
  v_user uuid := auth.uid();
  v_today date;
  p public.profiles;
begin
  if v_user is null then raise exception 'not authenticated'; end if;
  v_today := public._user_today(v_user);
  select * into p from public.profiles where id = v_user;
  return jsonb_build_object(
    'profile', jsonb_build_object('display_name', p.display_name, 'xp', p.xp, 'level', p.level,
        'level_start_xp', public.xp_for_level(p.level), 'next_level_xp', public.xp_for_level(p.level + 1),
        'current_streak', case when p.last_active_date >= v_today - 1 then p.current_streak else 0 end,
        'longest_streak', p.longest_streak, 'streak_freezes', p.streak_freezes,
        'streak_active_today', p.last_active_date = v_today, 'referral_code', p.referral_code),
    'premium', public.is_premium(v_user),
    'today', coalesce((select to_jsonb(d) - 'user_id' from public.daily_activity d
                        where d.user_id = v_user and d.activity_date = v_today), '{}'::jsonb),
    'goals', coalesce((select jsonb_agg(jsonb_build_object('type', goal_type, 'target', daily_target))
                         from public.goals where user_id = v_user and active), '[]'::jsonb),
    'prayers_today', coalesce((select jsonb_agg(prayer) from public.prayer_logs
                                where user_id = v_user and log_date = v_today), '[]'::jsonb),
    'history', coalesce((select jsonb_agg(jsonb_build_object('date', activity_date, 'xp', xp_earned,
                                  'ayahs_read', ayahs_read, 'goals_met', goals_met) order by activity_date)
                           from public.daily_activity where user_id = v_user and activity_date > v_today - 30), '[]'::jsonb),
    'hifz_due', (select count(*) from public.hifz_items where user_id = v_user and status <> 'new' and due_date <= v_today),
    'hifz_memorized', (select count(*) from public.hifz_items where user_id = v_user and status in ('review', 'mastered')),
    'hifz_at_risk', (select count(*) from public.hifz_items where user_id = v_user and status <> 'new'
                       and public.hifz_retention(interval_days, last_reviewed_at) < 0.8),
    'hifz_has_plan', exists (select 1 from public.hifz_plans where user_id = v_user and active),
    'achievements_unlocked', (select count(*) from public.user_achievements where user_id = v_user),
    'achievements_total', (select count(*) from public.achievements),
    'last_ayah_id', (select last_ayah_id from public.reading_progress where user_id = v_user),
    'recent_recitations', coalesce((select jsonb_agg(jsonb_build_object('id', id, 'score', overall_score, 'created_at', created_at) order by created_at desc)
                                      from (select * from public.recitation_sessions
                                             where user_id = v_user and status = 'done'
                                             order by created_at desc limit 5) r), '[]'::jsonb),
    -- Value gate: days with a recitation check, an AI hifz test or a completed review.
    'value_days', (select count(*) from public.daily_activity
                    where user_id = v_user and (recitations > 0 or reviews_done > 0 or ayahs_memorized > 0)),
    'days_since_signup', v_today - (p.created_at at time zone p.timezone)::date,
    'subscription', (select jsonb_build_object('status', s.status, 'period_type', s.period_type,
                                               'will_renew', s.will_renew, 'current_period_end', s.current_period_end,
                                               'store', s.store, 'product_id', s.product_id)
                       from public.subscriptions s where s.user_id = v_user)
  );
end $$;

-- ---------------------------------------------------------------------------
-- Weekly summary (Home card from day 7; the first one is a paywall moment)
-- ---------------------------------------------------------------------------
create or replace function public.get_weekly_summary()
returns jsonb language plpgsql stable security definer set search_path = public as $$
declare
  v_user uuid := auth.uid();
  v_today date;
  v_from date;
  r record;
  p public.profiles;
begin
  if v_user is null then raise exception 'not authenticated'; end if;
  v_today := public._user_today(v_user);
  v_from := v_today - 6;
  select * into p from public.profiles where id = v_user;
  select count(*) filter (where xp_earned > 0) as active_days,
         coalesce(sum(ayahs_read), 0) as ayahs_read,
         coalesce(sum(reviews_done), 0) as reviews_done,
         coalesce(sum(ayahs_memorized), 0) as ayahs_memorized,
         coalesce(sum(recitations), 0) as recitations,
         coalesce(sum(minutes_listened), 0) as minutes_listened,
         coalesce(sum(adhkar_completed), 0) as adhkar_completed
    into r
    from public.daily_activity where user_id = v_user and activity_date between v_from and v_today;
  return jsonb_build_object(
    'from', v_from, 'to', v_today,
    'active_days', r.active_days, 'ayahs_read', r.ayahs_read, 'reviews_done', r.reviews_done,
    'ayahs_memorized', r.ayahs_memorized, 'recitations', r.recitations, 'minutes_listened', r.minutes_listened,
    'adhkar_completed', r.adhkar_completed,
    'best_score', (select max(overall_score) from public.recitation_sessions
                    where user_id = v_user and status = 'done' and created_at >= now() - interval '7 days'),
    'hifz_memorized', (select count(*) from public.hifz_items where user_id = v_user and status in ('review', 'mastered')),
    'at_risk', (select count(*) from public.hifz_items where user_id = v_user and status <> 'new'
                  and public.hifz_retention(interval_days, last_reviewed_at) < 0.8),
    'streak', case when p.last_active_date >= v_today - 1 then p.current_streak else 0 end,
    'days_since_signup', v_today - (p.created_at at time zone p.timezone)::date
  );
end $$;

-- ---------------------------------------------------------------------------
-- Weak words: the words this user gets wrong most often (last 90 days), from the
-- per-session mistakes we already store. Free users see the top 3; the drill is Premium.
-- ---------------------------------------------------------------------------
create or replace function public.get_weak_words(p_limit int default 20)
returns jsonb language plpgsql stable security definer set search_path = public as $$
declare
  v_user uuid := auth.uid();
  v_premium boolean;
  v_total int;
  v_words jsonb;
begin
  if v_user is null then raise exception 'not authenticated'; end if;
  v_premium := public.is_premium(v_user);
  with m as (
    select (e ->> 'ayahId')::int as ayah_id, (e ->> 'position')::int as position,
           e ->> 'expected' as expected, e ->> 'type' as kind, s.created_at
      from public.recitation_sessions s
      cross join lateral jsonb_array_elements(case when jsonb_typeof(s.mistakes) = 'array' then s.mistakes else '[]'::jsonb end) e
     where s.user_id = v_user and s.status = 'done' and s.created_at > now() - interval '90 days'
       and e ->> 'type' in ('mispronounced', 'wrong_word', 'skipped', 'unclear')
       and e ? 'ayahId' and e ? 'position'
  ), g as (
    select ayah_id, position, max(expected) as expected, count(*) as misses, max(created_at) as last_seen,
           mode() within group (order by kind) as kind
      from m group by ayah_id, position
  ), ranked as (
    select g.*, a.surah_id, a.ayah_number,
           row_number() over (order by g.misses desc, g.last_seen desc) as rn
      from g join public.ayahs a on a.id = g.ayah_id
  )
  select count(*), coalesce(jsonb_agg(jsonb_build_object(
           'ayah_id', ayah_id, 'surah_id', surah_id, 'ayah_number', ayah_number, 'position', position,
           'word', expected, 'misses', misses, 'kind', kind, 'last_seen', last_seen) order by rn)
           filter (where rn <= case when v_premium then least(greatest(p_limit, 1), 100) else 3 end), '[]'::jsonb)
    into v_total, v_words
    from ranked;
  return jsonb_build_object('premium', v_premium, 'total', v_total, 'words', v_words,
                            'locked', greatest(v_total - jsonb_array_length(v_words), 0));
end $$;

-- Daily-quota helpers replaced by begin_ai_call / cancel_ai_call (dead code since PR #2).
drop function if exists public.consume_ai_quota(uuid, public.ai_feature);
drop function if exists public.refund_ai_quota(uuid, public.ai_feature);

-- ---------------------------------------------------------------------------
-- Permissions
-- ---------------------------------------------------------------------------
revoke execute on all functions in schema public from public, anon, authenticated;
grant execute on function
  public.level_for_xp(int), public.xp_for_level(int), public.hifz_retention(int, timestamptz),
  public.search_ayahs_keyword(text, int, int)
  to anon, authenticated;
grant execute on function
  public.log_activity(text, int, text), public.log_prayer(public.prayer_name, boolean, date),
  public.complete_dhikr(smallint, int), public.create_hifz_plan(int, int, smallint, text),
  public.get_hifz_queue(), public.hifz_record_review(bigint, smallint), public.get_hifz_stats(),
  public.get_my_quota(), public.get_dashboard(), public.apply_referral(text), public.get_my_ai_budget(),
  public.seed_known_surahs(int[], text), public.get_weekly_summary(), public.get_weak_words(int)
  to authenticated;
grant execute on all functions in schema public to service_role;
