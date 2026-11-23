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

rollback;
\echo 'ALL DB TESTS PASSED'
