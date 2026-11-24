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
  assert (public.get_my_quota() -> 'features' -> 'ask' ->> 'limit')::int = 15, 'free ask limit (weekly)';
  assert (public.get_my_quota() ->> 'clip_seconds')::int = 60, 'free clip length';
  assert (public.get_my_quota() ->> 'resets_at')::timestamptz > now(), 'weekly renewal in the future';
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

-- service-role weekly quota enforcement (renews Friday; hifz tests counted separately)
do $$
declare r jsonb; i int;
begin
  for i in 1..15 loop
    r := public.begin_ai_call('00000000-0000-0000-0000-000000000002', 'ask', 0.0001);
    assert (r ->> 'allowed')::boolean, 'within weekly quota ' || r::text;
  end loop;
  r := public.begin_ai_call('00000000-0000-0000-0000-000000000002', 'ask', 0.0001);
  assert not (r ->> 'allowed')::boolean and r ->> 'reason' = 'weekly_limit', 'weekly quota exhausted ' || r::text;
  assert extract(isodow from ((r ->> 'resets_at')::timestamptz at time zone 'UTC')) = 5, 'renews on Friday ' || r::text;
  assert ((r ->> 'resets_at')::timestamptz at time zone 'UTC')::time = '00:00', 'renews at midnight local';
  -- recitation and hifz tests have their own counters
  r := public.begin_ai_call('00000000-0000-0000-0000-000000000002', 'recitation', 0.0001);
  assert (r ->> 'allowed')::boolean and (r ->> 'remaining')::int = 9, 'recitation 10/week ' || r::text;
  for i in 1..5 loop
    r := public.begin_ai_call('00000000-0000-0000-0000-000000000002', 'hifz', 0.0001);
    assert (r ->> 'allowed')::boolean, 'hifz tests within quota ' || r::text;
  end loop;
  r := public.begin_ai_call('00000000-0000-0000-0000-000000000002', 'hifz', 0.0001);
  assert not (r ->> 'allowed')::boolean, 'hifz 5/week ' || r::text;
  -- the onboarding check is not counted, and cancelling it does not refund a count
  r := public.begin_ai_call('00000000-0000-0000-0000-000000000002', 'hifz', 0.0001, null, false);
  assert (r ->> 'allowed')::boolean, 'uncounted call allowed past the limit ' || r::text;
  perform public.cancel_ai_call((r ->> 'call_id')::bigint);
  assert (select count from public.ai_usage where user_id = '00000000-0000-0000-0000-000000000002' and feature = 'hifz') = 5,
    'uncounted cancel leaves the count alone';
  insert into public.subscriptions (user_id, status, current_period_end)
  values ('00000000-0000-0000-0000-000000000002', 'active', now() + interval '30 days');
  r := public.begin_ai_call('00000000-0000-0000-0000-000000000002', 'ask', 0.0001);
  assert (r ->> 'allowed')::boolean and (r ->> 'premium')::boolean, 'premium lifts quota ' || r::text;
  delete from public.subscriptions where user_id = '00000000-0000-0000-0000-000000000002';
end $$;

-- Friday-based weeks
do $$ begin
  assert public._week_start('2026-11-27') = '2026-11-27', 'friday starts a week';
  assert public._week_start('2026-11-28') = '2026-11-27', 'saturday';
  assert public._week_start('2026-11-26') = '2026-11-20', 'thursday belongs to last week';
end $$;

-- clients cannot call internal functions
set local role authenticated;
do $$ begin
  begin
    perform public.begin_ai_call('00000000-0000-0000-0000-000000000002', 'ask', 0);
    raise exception 'begin_ai_call should be service-only';
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
    r := public.begin_ai_call('00000000-0000-0000-0000-000000000003', 'recitation', 0.04);
    assert (r ->> 'allowed')::boolean, 'free call within budget ' || r::text;
    assert r ->> 'tier' = 'free', 'free tier';
  end loop;
  r := public.begin_ai_call('00000000-0000-0000-0000-000000000003', 'recitation', 0.04);
  assert not (r ->> 'allowed')::boolean and r ->> 'reason' = 'budget', 'free budget enforced ' || r::text;
  -- settling at the real (lower) cost frees the rest of the budget
  perform public.finish_ai_call((select id from public.ai_calls where user_id = '00000000-0000-0000-0000-000000000003' order by id limit 1), 0.001, 'test');
  r := public.begin_ai_call('00000000-0000-0000-0000-000000000003', 'recitation', 0.04);
  assert (r ->> 'allowed')::boolean, 'settled cost releases reservation ' || r::text;
  -- cancelling refunds the reservation and the daily count
  perform public.cancel_ai_call((r ->> 'call_id')::bigint);
  assert (select count from public.ai_usage where user_id = '00000000-0000-0000-0000-000000000003' and feature = 'recitation') = 3,
    'weekly count refunded on cancel';
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
  r := public.begin_ai_call('00000000-0000-0000-0000-000000000004', 'recitation', 0.60, 0.05);
  assert (r ->> 'allowed')::boolean and not (r ->> 'degraded')::boolean and (r ->> 'budget_usd')::numeric = 1.00,
    'premium budget is half of net ' || r::text;
  perform public.finish_ai_call((r ->> 'call_id')::bigint, 0.60);
  r := public.begin_ai_call('00000000-0000-0000-0000-000000000004', 'recitation', 0.60, 0.05);
  assert (r ->> 'allowed')::boolean and (r ->> 'degraded')::boolean, 'premium degrades to cheaper model ' || r::text;
  perform public.finish_ai_call((r ->> 'call_id')::bigint, 0.38);
  r := public.begin_ai_call('00000000-0000-0000-0000-000000000004', 'recitation', 0.60, 0.05);
  assert not (r ->> 'allowed')::boolean and r ->> 'reason' = 'budget', 'premium stops at half of payment ' || r::text;
  assert (r ->> 'resets_at')::timestamptz between now() + interval '19 days' and now() + interval '21 days', 'resets at renewal ' || r::text;
  select spent_usd + reserved_usd into v_spent from public.ai_spend where user_id = '00000000-0000-0000-0000-000000000004';
  assert v_spent <= 1.00, 'never above budget';

  -- annual plan: the year's budget is pooled (50% of net = 8.40), paced at 3x the monthly share (2.10)
  update public.subscriptions set net_revenue_usd = 16.80, period_months = 12, period_start = now() - interval '40 days',
         current_period_end = now() + interval '325 days'
   where user_id = '00000000-0000-0000-0000-000000000004';
  r := public.begin_ai_call('00000000-0000-0000-0000-000000000004', 'recitation', 1.50);
  assert (r ->> 'allowed')::boolean and (r ->> 'budget_usd')::numeric = 8.40, 'annual budget pooled ' || r::text;
  perform public.finish_ai_call((r ->> 'call_id')::bigint, 1.50);
  r := public.begin_ai_call('00000000-0000-0000-0000-000000000004', 'recitation', 0.50);
  assert (r ->> 'allowed')::boolean, 'more than the old 0.70 monthly cap is fine ' || r::text;
  perform public.finish_ai_call((r ->> 'call_id')::bigint, 0.50);
  r := public.begin_ai_call('00000000-0000-0000-0000-000000000004', 'recitation', 0.50);
  assert not (r ->> 'allowed')::boolean and r ->> 'reason' = 'budget', 'paced at 3x monthly share ' || r::text;
  assert (r ->> 'resets_at')::timestamptz < now() + interval '31 days', 'pace resets next month ' || r::text;

  -- ring-fence: Ask may use at most 60% of the budget (monthly plan, budget 1.00)
  update public.subscriptions set net_revenue_usd = 2.00, period_months = 1, period_start = now() - interval '1 day'
   where user_id = '00000000-0000-0000-0000-000000000004';
  r := public.begin_ai_call('00000000-0000-0000-0000-000000000004', 'ask', 0.55);
  assert (r ->> 'allowed')::boolean, 'ask within its share ' || r::text;
  perform public.finish_ai_call((r ->> 'call_id')::bigint, 0.55);
  r := public.begin_ai_call('00000000-0000-0000-0000-000000000004', 'ask', 0.10);
  assert not (r ->> 'allowed')::boolean, 'ask cannot eat the core share ' || r::text;
  r := public.begin_ai_call('00000000-0000-0000-0000-000000000004', 'recitation', 0.40);
  assert (r ->> 'allowed')::boolean, 'recitation still has its reserved share ' || r::text;
  perform public.cancel_ai_call((r ->> 'call_id')::bigint);

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

-- ===========================================================================
-- Audit fixes and value-first monetization (migrations 20261124000003/4)
-- ===========================================================================
insert into public.surahs values (114, 'الناس', 'Mankind', 'An-Nas', 'makkah', 6);
insert into public.ayahs (id, surah_id, ayah_number, text_uthmani, text_simple, juz, page)
select 7 + g, 114, g, 'nas ' || g, 'nas ' || g, 30, 604 from generate_series(1, 6) g;
insert into auth.users (id, raw_user_meta_data, created_at) values
  ('00000000-0000-0000-0000-000000000005', '{"timezone":"AST"}', now()),
  ('00000000-0000-0000-0000-000000000006', '{"timezone":"Asia/Riyadh"}', now() - interval '30 days');
update public.profiles set created_at = now() - interval '30 days' where id = '00000000-0000-0000-0000-000000000006';

-- time zones: abbreviations and offsets are rejected (AST would be read as UTC-4)
do $$ begin
  assert (select timezone from public.profiles where id = '00000000-0000-0000-0000-000000000005') = 'Asia/Riyadh',
    'invalid tz on signup falls back';
end $$;
set local role authenticated;
set local request.jwt.claim.sub = '00000000-0000-0000-0000-000000000005';
update public.profiles set timezone = '+03';
do $$ begin
  assert (select timezone from public.profiles) = 'Asia/Riyadh', 'client cannot store an offset tz';
end $$;
update public.profiles set timezone = 'Europe/London';
do $$ begin
  assert (select timezone from public.profiles) = 'Europe/London', 'valid IANA tz accepted';
end $$;
update public.profiles set timezone = 'UTC';

-- known surahs go straight to review, spread over the next days, and never fire a milestone
do $$
declare r jsonb; d jsonb;
begin
  r := public.seed_known_surahs(array[1]);
  assert (r ->> 'items')::int = 7, 'seeded al-fatiha ' || r::text;
  assert (select count(*) from public.hifz_items where status = 'review') = 7, 'seeded as review';
  assert (select min(due_date) from public.hifz_items) > (now() at time zone 'UTC')::date, 'first review tomorrow';
  d := public.get_dashboard();
  assert (d ->> 'hifz_memorized')::int = 7 and (d ->> 'hifz_has_plan')::boolean, 'dashboard sees seeded items ' || d::text;
  assert (d ->> 'value_days')::int = 0, 'seeding is not value';
  -- the review-only plan does not count towards the 3-plan limit
  perform public.create_hifz_plan(8, 13, 3::smallint, 'An-Nas');
  perform public.create_hifz_plan(8, 13, 3::smallint, 'x');
  perform public.create_hifz_plan(8, 13, 3::smallint, 'y');
end $$;

-- milestone: memorizing every ayah of An-Nas (6 ayahs) fires once, with XP
do $$
declare r jsonb; v_item bigint; v_milestones int := 0; i int;
begin
  for i in 1..2 loop
    for v_item in select id from public.hifz_items where ayah_id between 8 and 13 order by ayah_id loop
      r := public.hifz_record_review(v_item, 5::smallint);
      if r -> 'milestone' <> 'null'::jsonb then
        v_milestones := v_milestones + 1;
        assert (r -> 'milestone' ->> 'surah_id')::int = 114 and (r -> 'milestone' ->> 'first')::boolean,
          'first surah milestone ' || r::text;
      end if;
    end loop;
  end loop;
  assert v_milestones = 1, 'milestone fires exactly once, got ' || v_milestones;
  -- reviewing a seeded (known) surah does not celebrate
  r := public.hifz_record_review((select id from public.hifz_items where ayah_id = 1), 5::smallint);
  assert r -> 'milestone' = 'null'::jsonb, 'known surah is not a milestone ' || r::text;
  assert (public.get_dashboard() ->> 'value_days')::int = 1, 'reviews are value';
end $$;

-- weekly summary and weak words
reset role;
insert into public.recitation_sessions (user_id, start_ayah_id, end_ayah_id, audio_path, status, overall_score, mistakes, created_at)
values
  ('00000000-0000-0000-0000-000000000005', 1, 7, 'x', 'done', 81,
   '[{"type":"mispronounced","ayahId":2,"position":3,"expected":"رب"},{"type":"added_word","heard":"x"}]', now() - interval '1 day'),
  ('00000000-0000-0000-0000-000000000005', 1, 7, 'y', 'done', 92,
   '[{"type":"mispronounced","ayahId":2,"position":3,"expected":"رب"},{"type":"skipped","ayahId":4,"position":1,"expected":"مالك"},
     {"type":"wrong_word","ayahId":5,"position":2,"expected":"نعبد"},{"type":"unclear","ayahId":6,"position":1,"expected":"اهدنا"}]', now());
set local role authenticated;
set local request.jwt.claim.sub = '00000000-0000-0000-0000-000000000005';
do $$
declare r jsonb;
begin
  r := public.get_weekly_summary();
  assert (r ->> 'best_score')::numeric = 92 and (r ->> 'hifz_memorized')::int = 13, 'weekly summary ' || r::text;
  r := public.get_weak_words(10);
  assert (r ->> 'total')::int = 4, 'four weak words (added words have no position) ' || r::text;
  assert jsonb_array_length(r -> 'words') = 3 and (r ->> 'locked')::int = 1, 'free users see the top 3 ' || r::text;
  assert (r -> 'words' -> 0 ->> 'misses')::int = 2 and r -> 'words' -> 0 ->> 'word' = 'رب', 'most missed first ' || r::text;
  r := public.get_my_quota();
  assert not (r ->> 'onboarding_check_available')::boolean, 'onboarding check only before the first recitation';
end $$;
reset role;

-- referral rules: only new accounts, no mutual referrals
do $$
declare v_code5 text; v_code6 text; r jsonb;
begin
  select referral_code into v_code5 from public.profiles where id = '00000000-0000-0000-0000-000000000005';
  select referral_code into v_code6 from public.profiles where id = '00000000-0000-0000-0000-000000000006';
  set local role authenticated;
  set local request.jwt.claim.sub = '00000000-0000-0000-0000-000000000006';
  r := public.apply_referral(v_code5);
  assert r ->> 'reason' = 'too_late', 'old accounts cannot redeem ' || r::text;
  set local request.jwt.claim.sub = '00000000-0000-0000-0000-000000000003';
  r := public.apply_referral(v_code5);
  assert (r ->> 'ok')::boolean, 'new account redeems ' || r::text;
  set local request.jwt.claim.sub = '00000000-0000-0000-0000-000000000005';
  r := public.apply_referral((select referral_code from public.profiles where id = '00000000-0000-0000-0000-000000000003'));
  assert not (r ->> 'ok')::boolean, 'no mutual referral ' || r::text;
end $$;
reset role;

-- keyword search: wildcards are literal; all reciters free
do $$ begin
  assert (select count(*) from public.search_ayahs_keyword('%', 20, 20)) = 0, 'percent is not a wildcard';
  assert (select count(*) from public.search_ayahs_keyword('nas 3', 20, 20)) >= 1, 'keyword match';
  assert not exists (select 1 from public.reciters where is_premium), 'all reciters free';
end $$;

-- accuracy benchmark clips: own rows only, labels fixed once saved, audio path in own folder
do $$ begin
  set local role authenticated;
  set local request.jwt.claim.sub = '00000000-0000-0000-0000-000000000001';
  insert into public.benchmark_clips (id, user_id, start_ayah_id, end_ayah_id, audio_path, speaker_group,
    native_arabic, environment, mistakes, duration_ms, consented_at)
  values ('10000000-0000-0000-0000-000000000001', '00000000-0000-0000-0000-000000000001', 1, 7,
    '00000000-0000-0000-0000-000000000001/10000000-0000-0000-0000-000000000001.m4a', 'child', false, 'quiet',
    '[{"ayah_id": 2, "position": 3, "type": "wrong"}]', 30000, now());
  begin
    insert into public.benchmark_clips (id, user_id, start_ayah_id, end_ayah_id, audio_path, speaker_group,
      native_arabic, environment, consented_at)
    values (gen_random_uuid(), '00000000-0000-0000-0000-000000000002', 1, 1,
      '00000000-0000-0000-0000-000000000002/a.m4a', 'man', true, 'quiet', now());
    raise exception 'insert for another user should be denied';
  exception when insufficient_privilege then null;
  end;
  begin
    insert into public.benchmark_clips (id, user_id, start_ayah_id, end_ayah_id, audio_path, speaker_group,
      native_arabic, environment, consented_at)
    values (gen_random_uuid(), '00000000-0000-0000-0000-000000000001', 1, 1,
      '00000000-0000-0000-0000-000000000002/a.m4a', 'man', true, 'quiet', now());
    raise exception 'audio outside own folder should be rejected';
  exception when check_violation then null;
  end;
  begin
    update public.benchmark_clips set mistakes = '[]';
    raise exception 'labels should be fixed';
  exception when insufficient_privilege then null;
  end;
  assert (select count(*) from public.benchmark_clips) = 1, 'sees own clip';
  set local request.jwt.claim.sub = '00000000-0000-0000-0000-000000000002';
  assert (select count(*) from public.benchmark_clips) = 0, 'cannot see others'' clips';
end $$;
reset role;

rollback;
\echo 'ALL DB TESTS PASSED'
