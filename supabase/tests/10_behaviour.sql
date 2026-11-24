-- Behavioural tests for RPCs and RLS. Run after stubs + migrations:
--   psql -v ON_ERROR_STOP=1 -f tests/10_behaviour.sql
-- Any failed assertion raises and aborts.
\set ON_ERROR_STOP 1
begin;

-- minimal content
insert into public.surahs values (1, 'الفاتحة', 'The Opener', 'Al-Fatihah', 'makkah', 7);
insert into public.ayahs (id, surah_id, ayah_number, text_uthmani, text_simple, juz, page)
select g, 1, g, 'ayah ' || g, 'ayah ' || g, 1, 1 from generate_series(1, 7) g;

-- two users
insert into auth.users (id, raw_user_meta_data) values
  ('00000000-0000-0000-0000-000000000001', '{"locale":"en","timezone":"UTC"}'),
  ('00000000-0000-0000-0000-000000000002', '{"timezone":"UTC"}');

do $$ begin
  assert (select count(*) from public.profiles) = 2, 'profiles bootstrapped';
  assert (select count(*) from public.goals where user_id = '00000000-0000-0000-0000-000000000001') = 3, 'default goals';
end $$;

set local role authenticated;
set local request.jwt.claim.sub = '00000000-0000-0000-0000-000000000001';

-- RLS: user 1 sees only own profile, cannot raise own XP
do $$ begin
  assert (select count(*) from public.profiles) = 1, 'rls profiles';
end $$;
do $$ begin
  begin
    update public.profiles set xp = 99999;
    raise exception 'xp update should be denied';
  exception when insufficient_privilege then null;
  end;
end $$;

-- allowed profile columns + recitation insert
update public.profiles set display_name = 'Ahmad', locale = 'ar';
insert into public.recitation_sessions (user_id, start_ayah_id, end_ayah_id, audio_path)
values ('00000000-0000-0000-0000-000000000001', 1, 7, '00000000-0000-0000-0000-000000000001/x.m4a');
do $$ begin
  assert (select display_name from public.profiles) = 'Ahmad', 'profile update';
  begin
    update public.recitation_sessions set overall_score = 100;
    raise exception 'score update should be denied';
  exception when insufficient_privilege then null;
  end;
end $$;

-- activity + XP + streak + achievements
do $$
declare r jsonb;
begin
  r := public.log_activity('ayah_read', 5);
  assert (r ->> 'xp_awarded')::int = 10, 'ayah xp ' || r;
  assert (r ->> 'streak')::int = 1, 'streak starts at 1';
  assert jsonb_array_length(r -> 'new_achievements') >= 1, 'first_step unlocked';
  -- cap: 300 ayahs/day
  r := public.log_activity('ayah_read', 400);
  assert (r ->> 'xp_awarded')::int = 295 * 2, 'cap respected ' || r;
  begin
    perform public.log_activity('recitation', 1);
    raise exception 'recitation must not be client-loggable';
  exception when raise_exception then
    if sqlerrm like 'recitation must%' then raise; end if;
  end;
end $$;

-- prayers: duplicate gives no XP
do $$
declare r jsonb;
begin
  r := public.log_prayer('fajr');
  assert (r ->> 'xp_awarded')::int = 5, 'prayer xp';
  r := public.log_prayer('fajr');
  assert (r ->> 'duplicate')::boolean, 'duplicate prayer';
end $$;

-- adhkar: completing all of 'travel' (3 items) awards the set once
do $$
declare r jsonb;
begin
  perform public.complete_dhikr(5::smallint, 501);
  perform public.complete_dhikr(5::smallint, 502);
  r := public.complete_dhikr(5::smallint, 503);
  assert (r ->> 'category_completed')::boolean, 'travel set complete';
  assert (r ->> 'xp_awarded')::int = 15, 'set xp ' || r;
  r := public.complete_dhikr(5::smallint, 503);
  assert (r ->> 'xp_awarded')::int = 0, 'no double award';
end $$;

-- hifz: plan, queue, SM-2
do $$
declare
  v_plan uuid;
  q jsonb;
  r jsonb;
  v_item bigint;
begin
  v_plan := public.create_hifz_plan(1, 7, 3::smallint, 'Fatihah');
  q := public.get_hifz_queue();
  assert jsonb_array_length(q -> 'new') = 3, 'three new ayahs today ' || q;
  v_item := (q -> 'new' -> 0 ->> 'item_id')::bigint;
  r := public.hifz_record_review(v_item, 5::smallint);
  assert r ->> 'status' = 'learning' and (r ->> 'interval_days')::int = 1, 'first review ' || r;
  q := public.get_hifz_queue();
  assert jsonb_array_length(q -> 'new') = 2, 'new quota decremented ' || q;
  r := public.hifz_record_review(v_item, 4::smallint);
  assert r ->> 'status' = 'review' and (r ->> 'interval_days')::int = 3, 'second review ' || r;
  r := public.hifz_record_review(v_item, 1::smallint);
  assert (r ->> 'interval_days')::int = 1, 'lapse resets ' || r;
  assert (public.get_hifz_stats() ->> 'total')::int = 7, 'stats';
end $$;

-- dashboard + quota visibility
do $$
declare d jsonb;
begin
  d := public.get_dashboard();
  assert (d -> 'profile' ->> 'xp')::int > 0, 'dashboard xp';
  assert (d ->> 'premium')::boolean = false, 'not premium';
  assert (public.get_my_quota() -> 'features' -> 'ask' ->> 'limit')::int = 5, 'free ask limit';
end $$;

-- referral (user 1 refers user 2)
reset role;
set local role authenticated;
set local request.jwt.claim.sub = '00000000-0000-0000-0000-000000000002';
do $$
declare v_code text;
begin
  select referral_code into v_code from public.profiles where id = '00000000-0000-0000-0000-000000000001';
  -- user 2 cannot read user 1's profile through RLS
  assert v_code is null, 'rls hides other profiles';
end $$;
reset role;
do $$
declare v_code text; r jsonb;
begin
  select referral_code into v_code from public.profiles where id = '00000000-0000-0000-0000-000000000001';
  set local role authenticated;
  r := public.apply_referral(v_code);
  assert (r ->> 'ok')::boolean, 'referral ok ' || r;
  r := public.apply_referral(v_code);
  assert not (r ->> 'ok')::boolean, 'referral once';
end $$;
reset role;

-- service-role quota enforcement
do $$
declare r jsonb; i int;
begin
  for i in 1..5 loop
    r := public.consume_ai_quota('00000000-0000-0000-0000-000000000002', 'ask');
    assert (r ->> 'allowed')::boolean, 'within quota';
  end loop;
  r := public.consume_ai_quota('00000000-0000-0000-0000-000000000002', 'ask');
  assert not (r ->> 'allowed')::boolean, 'quota exhausted';
  insert into public.subscriptions (user_id, status, current_period_end)
  values ('00000000-0000-0000-0000-000000000002', 'active', now() + interval '30 days');
  r := public.consume_ai_quota('00000000-0000-0000-0000-000000000002', 'ask');
  assert (r ->> 'allowed')::boolean and (r ->> 'premium')::boolean, 'premium lifts quota ' || r;
end $$;

-- clients cannot call internal functions
set local role authenticated;
do $$ begin
  begin
    perform public.consume_ai_quota('00000000-0000-0000-0000-000000000002', 'ask');
    raise exception 'consume_ai_quota should be service-only';
  exception when insufficient_privilege then null;
  end;
end $$;
reset role;

-- AI cost cap: free users have a small fixed monthly budget
do $$
declare r jsonb; i int;
begin
  insert into auth.users (id, raw_user_meta_data) values ('00000000-0000-0000-0000-000000000003', '{"timezone":"UTC"}');
  -- budget 0.15: a 0.04 reservation fits three times, the fourth is refused
  for i in 1..3 loop
    r := public.begin_ai_call('00000000-0000-0000-0000-000000000003', 'search', 0.04);
    assert (r ->> 'allowed')::boolean, 'free call within budget ' || r::text;
    assert r ->> 'tier' = 'free', 'free tier';
  end loop;
  r := public.begin_ai_call('00000000-0000-0000-0000-000000000003', 'search', 0.04);
  assert not (r ->> 'allowed')::boolean and r ->> 'reason' = 'budget', 'free budget enforced ' || r::text;
  -- settling at the real (lower) cost frees the rest of the budget
  perform public.finish_ai_call((select id from public.ai_calls where user_id = '00000000-0000-0000-0000-000000000003' order by id limit 1), 0.001, 'test');
  r := public.begin_ai_call('00000000-0000-0000-0000-000000000003', 'search', 0.04);
  assert (r ->> 'allowed')::boolean, 'settled cost releases reservation ' || r::text;
  -- cancelling refunds the reservation and the daily count
  perform public.cancel_ai_call((r ->> 'call_id')::bigint);
  assert (select count from public.ai_usage where user_id = '00000000-0000-0000-0000-000000000003' and feature = 'search') = 3,
    'daily count refunded on cancel';
  -- free users always reserve with the cheap model (fallback) and are not "degraded"
  r := public.begin_ai_call('00000000-0000-0000-0000-000000000003', 'ask', 10, 0.001);
  assert (r ->> 'allowed')::boolean and not (r ->> 'degraded')::boolean, 'free uses cheap model ' || r::text;
end $$;

-- Premium: budget = 50% of net revenue per month; degrade, then stop
do $$
declare r jsonb; v_spent numeric;
begin
  insert into auth.users (id, raw_user_meta_data) values ('00000000-0000-0000-0000-000000000004', '{"timezone":"UTC"}');
  insert into public.subscriptions (user_id, status, store, period_type, current_period_end, net_revenue_usd, period_start, period_months)
  values ('00000000-0000-0000-0000-000000000004', 'active', 'play_store', 'normal', now() + interval '20 days', 2.00, now() - interval '10 days', 1);
  r := public.begin_ai_call('00000000-0000-0000-0000-000000000004', 'ask', 0.60, 0.05);
  assert (r ->> 'allowed')::boolean and not (r ->> 'degraded')::boolean and (r ->> 'budget_usd')::numeric = 1.00,
    'premium budget is half of net ' || r::text;
  perform public.finish_ai_call((r ->> 'call_id')::bigint, 0.60);
  r := public.begin_ai_call('00000000-0000-0000-0000-000000000004', 'ask', 0.60, 0.05);
  assert (r ->> 'allowed')::boolean and (r ->> 'degraded')::boolean, 'premium degrades to cheaper model ' || r::text;
  perform public.finish_ai_call((r ->> 'call_id')::bigint, 0.38);
  r := public.begin_ai_call('00000000-0000-0000-0000-000000000004', 'ask', 0.60, 0.05);
  assert not (r ->> 'allowed')::boolean and r ->> 'reason' = 'budget', 'premium stops at half of payment ' || r::text;
  assert (r ->> 'resets_at')::timestamptz between now() + interval '19 days' and now() + interval '21 days', 'resets at renewal ' || r::text;
  select spent_usd + reserved_usd into v_spent from public.ai_spend where user_id = '00000000-0000-0000-0000-000000000004';
  assert v_spent <= 1.00, 'never above budget';

  -- annual plan: 12 monthly windows of net/12
  update public.subscriptions set net_revenue_usd = 16.80, period_months = 12, period_start = now() - interval '40 days',
         current_period_end = now() + interval '325 days'
   where user_id = '00000000-0000-0000-0000-000000000004';
  r := public.begin_ai_call('00000000-0000-0000-0000-000000000004', 'ask', 0.10);
  assert (r ->> 'budget_usd')::numeric = 0.70, 'annual budget per month ' || r::text;
  assert (r ->> 'resets_at')::timestamptz < now() + interval '31 days', 'annual resets monthly ' || r::text;

  -- refund: net revenue 0 means no AI budget
  update public.subscriptions set net_revenue_usd = 0 where user_id = '00000000-0000-0000-0000-000000000004';
  r := public.begin_ai_call('00000000-0000-0000-0000-000000000004', 'search', 0.0001);
  assert not (r ->> 'allowed')::boolean, 'refunded subscriber has no budget ' || r::text;

  -- unknown price falls back to the lowest regional tier
  update public.subscriptions set net_revenue_usd = null, period_months = 1, period_start = now()
   where user_id = '00000000-0000-0000-0000-000000000004';
  r := public.begin_ai_call('00000000-0000-0000-0000-000000000004', 'search', 0.0001);
  assert (r ->> 'budget_usd')::numeric = 0.20, 'fallback budget ' || r::text;

  -- trial: small fixed budget
  update public.subscriptions set period_type = 'trial', current_period_end = now() + interval '7 days'
   where user_id = '00000000-0000-0000-0000-000000000004';
  r := public.begin_ai_call('00000000-0000-0000-0000-000000000004', 'search', 0.0001);
  assert r ->> 'tier' = 'trial' and (r ->> 'budget_usd')::numeric = 0.25, 'trial budget ' || r::text;
end $$;

-- Stale reservations (crashed function) are counted as spent
do $$
declare r jsonb;
begin
  update public.ai_calls set created_at = now() - interval '1 hour'
   where user_id = '00000000-0000-0000-0000-000000000003' and status = 'reserved';
  r := public.begin_ai_call('00000000-0000-0000-0000-000000000003', 'search', 0.0001);
  assert (select count(*) from public.ai_calls where user_id = '00000000-0000-0000-0000-000000000003' and status = 'expired') > 0,
    'stale reservations expired';
end $$;

-- the app can read its own budget, not other users' internals
set local role authenticated;
set local request.jwt.claim.sub = '00000000-0000-0000-0000-000000000003';
do $$
declare r jsonb;
begin
  r := public.get_my_ai_budget();
  assert r ->> 'tier' = 'free' and (r ->> 'used_percent')::numeric > 0, 'own budget visible ' || r::text;
  assert (select count(*) from public.ai_spend) = 1, 'ai_spend rls';
  begin
    perform public.begin_ai_call('00000000-0000-0000-0000-000000000003', 'ask', 0);
    raise exception 'begin_ai_call should be service-only';
  exception when insufficient_privilege then null;
  end;
  begin
    perform count(*) from public.ai_calls;
    raise exception 'ai_calls should be hidden';
  exception when insufficient_privilege then null;
  end;
end $$;
reset role;

rollback;
\echo 'ALL DB TESTS PASSED'
