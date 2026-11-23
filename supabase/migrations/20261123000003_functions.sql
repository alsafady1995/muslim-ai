-- Server-side business logic. Clients call these through supabase.rpc().
-- Internal helpers start with "_" and are not executable by clients.

-- ---------------------------------------------------------------------------
-- Helpers
-- ---------------------------------------------------------------------------
create or replace function public._user_today(p_user uuid) returns date
language sql stable as $$
  select (now() at time zone coalesce((select timezone from public.profiles where id = p_user), 'UTC'))::date
$$;

create or replace function public.level_for_xp(p_xp int) returns int
language sql immutable as $$ select floor(sqrt(greatest(p_xp, 0) / 50.0))::int + 1 $$;

create or replace function public.xp_for_level(p_level int) returns int
language sql immutable as $$ select (50 * power(greatest(p_level, 1) - 1, 2))::int $$;

create or replace function public.is_premium(p_user uuid) returns boolean
language sql stable security definer set search_path = public as $$
  select exists (
    select 1 from public.subscriptions s
    where s.user_id = p_user
      and s.status in ('active', 'grace_period', 'billing_issue')
      and (s.current_period_end is null or s.current_period_end > now() - interval '3 days')
  )
$$;

-- ---------------------------------------------------------------------------
-- New user bootstrap (fires for anonymous and full sign-ups)
-- ---------------------------------------------------------------------------
create or replace function public._handle_new_user() returns trigger
language plpgsql security definer set search_path = public as $$
declare
  v_locale text := coalesce(new.raw_user_meta_data ->> 'locale', 'ar');
begin
  if v_locale not in ('ar', 'en', 'ur', 'id', 'tr', 'fr') then v_locale := 'ar'; end if;
  insert into public.profiles (id, display_name, locale, timezone)
  values (new.id,
          new.raw_user_meta_data ->> 'display_name',
          v_locale,
          coalesce(new.raw_user_meta_data ->> 'timezone', 'Asia/Riyadh'))
  on conflict (id) do nothing;

  insert into public.goals (user_id, goal_type, daily_target) values
    (new.id, 'quran_read', 5),
    (new.id, 'adhkar', 2),
    (new.id, 'prayer', 5)
  on conflict do nothing;
  return new;
end $$;

create trigger on_auth_user_created after insert on auth.users
  for each row execute function public._handle_new_user();

-- ---------------------------------------------------------------------------
-- XP, levels, streaks, achievements
-- ---------------------------------------------------------------------------
create or replace function public._touch_streak(p_user uuid) returns int
language plpgsql security definer set search_path = public as $$
declare
  v_today date := public._user_today(p_user);
  p public.profiles;
begin
  select * into p from public.profiles where id = p_user for update;
  if p.last_active_date = v_today then
    return p.current_streak;
  elsif p.last_active_date = v_today - 1 then
    p.current_streak := p.current_streak + 1;
  elsif p.last_active_date = v_today - 2 and p.streak_freezes > 0 then
    -- one missed day is covered by a streak freeze
    p.current_streak := p.current_streak + 1;
    p.streak_freezes := p.streak_freezes - 1;
  else
    p.current_streak := 1;
  end if;
  -- earn a freeze every 7 days of streak (max 5)
  if p.current_streak % 7 = 0 then
    p.streak_freezes := least(p.streak_freezes + 1, 5);
  end if;
  update public.profiles
     set current_streak = p.current_streak,
         longest_streak = greatest(p.longest_streak, p.current_streak),
         streak_freezes = p.streak_freezes,
         last_active_date = v_today
   where id = p_user;
  return p.current_streak;
end $$;

create or replace function public._award_xp(p_user uuid, p_amount int, p_kind text, p_ref text)
returns void language plpgsql security definer set search_path = public as $$
begin
  if p_amount <= 0 then return; end if;
  insert into public.xp_events (user_id, amount, kind, ref) values (p_user, p_amount, p_kind, p_ref);
  update public.profiles
     set xp = xp + p_amount,
         level = public.level_for_xp(xp + p_amount)
   where id = p_user;
  insert into public.daily_activity (user_id, activity_date, xp_earned)
  values (p_user, public._user_today(p_user), p_amount)
  on conflict (user_id, activity_date) do update set xp_earned = daily_activity.xp_earned + excluded.xp_earned;
end $$;

create or replace function public._check_achievements(p_user uuid) returns jsonb
language plpgsql security definer set search_path = public as $$
declare
  a record;
  v_value int;
  v_new jsonb := '[]'::jsonb;
  p public.profiles;
  totals record;
begin
  select * into p from public.profiles where id = p_user;
  select coalesce(sum(ayahs_read), 0) as ayahs_read,
         coalesce(sum(ayahs_memorized), 0) as ayahs_memorized,
         coalesce(sum(adhkar_completed), 0) as adhkar,
         coalesce(sum(recitations), 0) as recitations,
         coalesce(sum(prayers_logged), 0) as prayers
    into totals
    from public.daily_activity where user_id = p_user;

  for a in
    select * from public.achievements ach
     where not exists (select 1 from public.user_achievements ua where ua.user_id = p_user and ua.achievement_id = ach.id)
     order by sort
  loop
    v_value := case a.metric
      when 'streak' then p.longest_streak
      when 'xp' then p.xp
      when 'level' then p.level
      when 'ayahs_read' then totals.ayahs_read
      when 'ayahs_memorized' then totals.ayahs_memorized
      when 'adhkar' then totals.adhkar
      when 'recitations' then totals.recitations
      when 'prayers' then totals.prayers
      else 0 end;
    if v_value >= a.threshold then
      insert into public.user_achievements (user_id, achievement_id) values (p_user, a.id) on conflict do nothing;
      v_new := v_new || jsonb_build_object('id', a.id, 'name_ar', a.name_ar, 'name_en', a.name_en, 'icon', a.icon, 'xp', a.xp_reward);
      if a.xp_reward > 0 then
        perform public._award_xp(p_user, a.xp_reward, 'achievement', a.id);
      end if;
    end if;
  end loop;
  return v_new;
end $$;

create or replace function public._evaluate_goals(p_user uuid) returns boolean
language plpgsql security definer set search_path = public as $$
declare
  v_today date := public._user_today(p_user);
  d public.daily_activity;
  g record;
  v_met boolean := true;
  v_any boolean := false;
  v_was boolean;
begin
  select * into d from public.daily_activity where user_id = p_user and activity_date = v_today;
  if not found then return false; end if;
  for g in select * from public.goals where user_id = p_user and active loop
    v_any := true;
    if (case g.goal_type
          when 'quran_read' then d.ayahs_read
          when 'memorize' then d.ayahs_memorized + d.reviews_done
          when 'adhkar' then d.adhkar_completed
          when 'prayer' then d.prayers_logged
          when 'listen' then d.minutes_listened
        end) < g.daily_target then
      v_met := false;
    end if;
  end loop;
  v_met := v_any and v_met;
  v_was := d.goals_met;
  if v_met and not v_was then
    update public.daily_activity set goals_met = true where user_id = p_user and activity_date = v_today;
    perform public._award_xp(p_user, 20, 'daily_goals', v_today::text);
  end if;
  return v_met;
end $$;

-- Core activity logger used by every feature. Units are capped per day by xp_rules,
-- so replaying requests cannot farm XP.
create or replace function public._log_activity(p_user uuid, p_kind text, p_units int, p_ref text)
returns jsonb language plpgsql security definer set search_path = public as $$
declare
  r public.xp_rules;
  v_today date := public._user_today(p_user);
  v_used int;
  v_units int;
  v_xp int;
  v_streak int;
  v_goals boolean;
  v_new jsonb;
  p public.profiles;
begin
  if p_units is null or p_units <= 0 or p_units > 1000 then
    raise exception 'invalid units';
  end if;
  select * into r from public.xp_rules where kind = p_kind;
  if not found then raise exception 'unknown activity kind: %', p_kind; end if;

  insert into public.daily_activity (user_id, activity_date) values (p_user, v_today) on conflict do nothing;

  execute format('select %I from public.daily_activity where user_id = $1 and activity_date = $2', r.activity_column)
    into v_used using p_user, v_today;
  execute format('update public.daily_activity set %I = %I + $3 where user_id = $1 and activity_date = $2',
                 r.activity_column, r.activity_column)
    using p_user, v_today, p_units;

  v_units := greatest(0, least(p_units, r.daily_unit_cap - coalesce(v_used, 0)));
  v_xp := v_units * r.xp_per_unit;
  perform public._award_xp(p_user, v_xp, p_kind, p_ref);
  v_streak := public._touch_streak(p_user);
  v_goals := public._evaluate_goals(p_user);
  v_new := public._check_achievements(p_user);
  select * into p from public.profiles where id = p_user;
  return jsonb_build_object(
    'xp_awarded', v_xp,
    'total_xp', p.xp,
    'level', p.level,
    'next_level_xp', public.xp_for_level(p.level + 1),
    'streak', v_streak,
    'goals_met', v_goals,
    'new_achievements', v_new
  );
end $$;

-- Client-facing wrapper. Only "honest-effort" kinds are client-loggable;
-- recitation XP is awarded by the server after analysis.
create or replace function public.log_activity(p_kind text, p_units int default 1, p_ref text default null)
returns jsonb language plpgsql security definer set search_path = public as $$
begin
  if auth.uid() is null then raise exception 'not authenticated'; end if;
  if p_kind not in ('ayah_read', 'listen_minute') then
    raise exception 'kind % cannot be logged from the client', p_kind;
  end if;
  return public._log_activity(auth.uid(), p_kind, p_units, p_ref);
end $$;

create or replace function public.log_prayer(p_prayer public.prayer_name, p_on_time boolean default true, p_date date default null)
returns jsonb language plpgsql security definer set search_path = public as $$
declare
  v_user uuid := auth.uid();
  v_date date;
  v_inserted int;
begin
  if v_user is null then raise exception 'not authenticated'; end if;
  v_date := coalesce(p_date, public._user_today(v_user));
  if v_date < public._user_today(v_user) - 1 or v_date > public._user_today(v_user) then
    raise exception 'can only log today or yesterday';
  end if;
  insert into public.prayer_logs (user_id, log_date, prayer, on_time) values (v_user, v_date, p_prayer, p_on_time)
  on conflict do nothing;
  get diagnostics v_inserted = row_count;
  if v_inserted = 0 then
    return jsonb_build_object('xp_awarded', 0, 'duplicate', true);
  end if;
  return public._log_activity(v_user, 'prayer', 1, p_prayer::text);
end $$;

create or replace function public.complete_dhikr(p_category_id smallint, p_dhikr_id int)
returns jsonb language plpgsql security definer set search_path = public as $$
declare
  v_user uuid := auth.uid();
  v_today date;
  v_ids int[];
  v_total int;
  v_done boolean;
  v_result jsonb;
begin
  if v_user is null then raise exception 'not authenticated'; end if;
  if not exists (select 1 from public.adhkar where id = p_dhikr_id and category_id = p_category_id) then
    raise exception 'dhikr not in category';
  end if;
  v_today := public._user_today(v_user);
  insert into public.adhkar_progress (user_id, progress_date, category_id, completed_ids)
  values (v_user, v_today, p_category_id, array[p_dhikr_id])
  on conflict (user_id, progress_date, category_id) do update
    set completed_ids = case when p_dhikr_id = any (adhkar_progress.completed_ids)
                             then adhkar_progress.completed_ids
                             else adhkar_progress.completed_ids || p_dhikr_id end
  returning completed_ids, completed into v_ids, v_done;

  select count(*) into v_total from public.adhkar where category_id = p_category_id;
  if not v_done and cardinality(v_ids) >= v_total then
    update public.adhkar_progress set completed = true
     where user_id = v_user and progress_date = v_today and category_id = p_category_id;
    v_result := public._log_activity(v_user, 'adhkar_set', 1, p_category_id::text);
    return v_result || jsonb_build_object('category_completed', true, 'completed_count', cardinality(v_ids), 'total', v_total);
  end if;
  return jsonb_build_object('category_completed', v_done, 'completed_count', cardinality(v_ids), 'total', v_total, 'xp_awarded', 0);
end $$;

-- ---------------------------------------------------------------------------
-- Hifz: plans, SM-2 spaced repetition, forgetting prediction
-- ---------------------------------------------------------------------------
create or replace function public.create_hifz_plan(p_start_ayah int, p_end_ayah int, p_daily_new smallint default 3, p_title text default null)
returns uuid language plpgsql security definer set search_path = public as $$
declare
  v_user uuid := auth.uid();
  v_plan uuid;
begin
  if v_user is null then raise exception 'not authenticated'; end if;
  if p_end_ayah < p_start_ayah or p_end_ayah - p_start_ayah > 6235 then raise exception 'invalid range'; end if;
  if (select count(*) from public.hifz_plans where user_id = v_user and active) >= 3 then
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

-- Predicted probability of recall (0..1) using an exponential forgetting curve
-- calibrated so recall = 0.9 when days elapsed = current interval (stability).
create or replace function public.hifz_retention(p_interval int, p_last timestamptz) returns numeric
language sql immutable as $$
  select case when p_last is null then null
              else round(power(0.9, (extract(epoch from (now() - p_last)) / 86400.0) / greatest(p_interval, 1))::numeric, 3)
         end
$$;

-- Today's queue: due reviews (most at-risk first) + new ayahs per plan quota.
create or replace function public.get_hifz_queue()
returns jsonb language plpgsql stable security definer set search_path = public as $$
declare
  v_user uuid := auth.uid();
  v_today date;
  v_reviews jsonb;
  v_new jsonb;
begin
  if v_user is null then raise exception 'not authenticated'; end if;
  v_today := public._user_today(v_user);
  select coalesce(jsonb_agg(x order by x.retention nulls first), '[]'::jsonb) into v_reviews from (
    select i.id as item_id, i.ayah_id, a.surah_id, a.ayah_number, a.text_uthmani, i.status, i.interval_days,
           public.hifz_retention(i.interval_days, i.last_reviewed_at) as retention
      from public.hifz_items i join public.ayahs a on a.id = i.ayah_id
     where i.user_id = v_user and i.status <> 'new' and i.due_date <= v_today
     limit 100) x;

  select coalesce(jsonb_agg(y order by y.ayah_id), '[]'::jsonb) into v_new from (
    select i.id as item_id, i.ayah_id, a.surah_id, a.ayah_number, a.text_uthmani, i.plan_id
      from public.hifz_plans p
      cross join lateral (
        select greatest(0, p.daily_new_ayahs - (select count(*) from public.hifz_items t
                                                 where t.plan_id = p.id and t.introduced_on = v_today)) as remaining
      ) q
      cross join lateral (
        select * from public.hifz_items i2
         where i2.plan_id = p.id and i2.status = 'new'
         order by i2.ayah_id limit q.remaining
      ) i
      join public.ayahs a on a.id = i.ayah_id
     where p.user_id = v_user and p.active) y;

  return jsonb_build_object('date', v_today, 'reviews', v_reviews, 'new', v_new);
end $$;

-- SM-2 update. score: 0 = blank, 1-2 = failed, 3 = hard, 4 = good, 5 = perfect.
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

  return jsonb_build_object('item_id', p_item, 'status', v_status, 'interval_days', v_interval,
                            'due_date', v_today + v_interval, 'ease_factor', v_ef) || v_activity;
end $$;

create or replace function public.hifz_record_review(p_item bigint, p_score smallint)
returns jsonb language plpgsql security definer set search_path = public as $$
begin
  if auth.uid() is null then raise exception 'not authenticated'; end if;
  return public._hifz_apply_review(auth.uid(), p_item, p_score, 'self', null);
end $$;

create or replace function public.get_hifz_stats()
returns jsonb language sql stable security definer set search_path = public as $$
  with items as (
    select i.*, public.hifz_retention(i.interval_days, i.last_reviewed_at) as retention
      from public.hifz_items i where i.user_id = auth.uid()
  )
  select jsonb_build_object(
    'total', count(*),
    'new', count(*) filter (where status = 'new'),
    'learning', count(*) filter (where status = 'learning'),
    'review', count(*) filter (where status = 'review'),
    'mastered', count(*) filter (where status = 'mastered'),
    'avg_retention', round(avg(retention), 3),
    'at_risk', count(*) filter (where retention < 0.8),
    'due_today', count(*) filter (where status <> 'new' and due_date <= public._user_today(auth.uid())),
    'at_risk_items', coalesce((select jsonb_agg(jsonb_build_object('item_id', id, 'ayah_id', ayah_id, 'retention', retention) order by retention)
                                 from (select * from items where retention < 0.8 order by retention limit 20) r), '[]'::jsonb)
  ) from items
$$;

-- ---------------------------------------------------------------------------
-- AI quotas (called by edge functions with the service role)
-- ---------------------------------------------------------------------------
create or replace function public.consume_ai_quota(p_user uuid, p_feature public.ai_feature)
returns jsonb language plpgsql security definer set search_path = public as $$
declare
  v_premium boolean := public.is_premium(p_user);
  v_limit int;
  v_today date := public._user_today(p_user);
  v_count int;
begin
  select case when v_premium then premium_daily else free_daily end into v_limit
    from public.plan_limits where feature = p_feature;
  insert into public.ai_usage (user_id, usage_date, feature, count) values (p_user, v_today, p_feature, 0)
  on conflict do nothing;
  update public.ai_usage set count = count + 1
   where user_id = p_user and usage_date = v_today and feature = p_feature and count < v_limit
  returning count into v_count;
  if v_count is null then
    return jsonb_build_object('allowed', false, 'premium', v_premium, 'limit', v_limit, 'remaining', 0);
  end if;
  return jsonb_build_object('allowed', true, 'premium', v_premium, 'limit', v_limit, 'remaining', v_limit - v_count);
end $$;

-- Give quota back when the AI call failed on our side.
create or replace function public.refund_ai_quota(p_user uuid, p_feature public.ai_feature)
returns void language sql security definer set search_path = public as $$
  update public.ai_usage set count = greatest(count - 1, 0)
   where user_id = p_user and usage_date = public._user_today(p_user) and feature = p_feature
$$;

create or replace function public.get_my_quota()
returns jsonb language sql stable security definer set search_path = public as $$
  select jsonb_build_object(
    'premium', public.is_premium(auth.uid()),
    'features', coalesce(jsonb_object_agg(l.feature, jsonb_build_object(
        'limit', case when public.is_premium(auth.uid()) then l.premium_daily else l.free_daily end,
        'used', coalesce(u.count, 0))), '{}'::jsonb))
  from public.plan_limits l
  left join public.ai_usage u on u.feature = l.feature and u.user_id = auth.uid()
                              and u.usage_date = public._user_today(auth.uid())
$$;

-- ---------------------------------------------------------------------------
-- Retrieval
-- ---------------------------------------------------------------------------
create or replace function public.match_content(
  p_embedding vector(1024),
  p_types public.content_source[] default array['ayah', 'tafsir', 'hadith']::public.content_source[],
  p_count int default 12,
  p_min_similarity float default 0.25
) returns table (source_type public.content_source, source_id bigint, source_variant int, language text, chunk text, similarity float)
language sql stable security definer set search_path = public as $$
  select e.source_type, e.source_id, e.source_variant, e.language, e.chunk,
         1 - (e.embedding <=> p_embedding) as similarity
    from public.content_embeddings e
   where e.source_type = any (p_types)
     and 1 - (e.embedding <=> p_embedding) >= p_min_similarity
   order by e.embedding <=> p_embedding
   limit least(p_count, 50)
$$;

-- Keyword fallback (no AI quota): Arabic text or translation match.
create or replace function public.search_ayahs_keyword(p_query text, p_translation_id int default 20, p_limit int default 20)
returns table (ayah_id int, surah_id smallint, ayah_number smallint, text_uthmani text, translation text, score real)
language sql stable as $$
  select a.id, a.surah_id, a.ayah_number, a.text_uthmani, t.text,
         greatest(similarity(a.text_simple, p_query), similarity(coalesce(t.text, ''), p_query)) as score
    from public.ayahs a
    left join public.ayah_translations t on t.ayah_id = a.id and t.translation_id = p_translation_id
   where a.text_simple % p_query or t.text ilike '%' || p_query || '%'
   order by score desc
   limit least(p_limit, 50)
$$;

-- ---------------------------------------------------------------------------
-- Dashboard (one round-trip for the home screen)
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
    'achievements_unlocked', (select count(*) from public.user_achievements where user_id = v_user),
    'achievements_total', (select count(*) from public.achievements),
    'last_ayah_id', (select last_ayah_id from public.reading_progress where user_id = v_user),
    'recent_recitations', coalesce((select jsonb_agg(jsonb_build_object('id', id, 'score', overall_score, 'created_at', created_at) order by created_at desc)
                                      from (select * from public.recitation_sessions
                                             where user_id = v_user and status = 'done'
                                             order by created_at desc limit 5) r), '[]'::jsonb)
  );
end $$;

-- ---------------------------------------------------------------------------
-- Referrals
-- ---------------------------------------------------------------------------
create or replace function public.apply_referral(p_code text)
returns jsonb language plpgsql security definer set search_path = public as $$
declare
  v_user uuid := auth.uid();
  v_referrer uuid;
begin
  if v_user is null then raise exception 'not authenticated'; end if;
  select id into v_referrer from public.profiles where referral_code = lower(trim(p_code));
  if v_referrer is null or v_referrer = v_user then
    return jsonb_build_object('ok', false, 'reason', 'invalid_code');
  end if;
  if exists (select 1 from public.referrals where referred_id = v_user) then
    return jsonb_build_object('ok', false, 'reason', 'already_referred');
  end if;
  insert into public.referrals (referrer_id, referred_id, rewarded) values (v_referrer, v_user, true);
  update public.profiles set referred_by = v_referrer where id = v_user;
  update public.profiles set streak_freezes = least(streak_freezes + 1, 5) where id = v_referrer;
  perform public._award_xp(v_referrer, 100, 'referral', v_user::text);
  perform public._award_xp(v_user, 50, 'referred', v_referrer::text);
  return jsonb_build_object('ok', true);
end $$;

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
  public.get_my_quota(), public.get_dashboard(), public.apply_referral(text)
  to authenticated;

grant execute on all functions in schema public to service_role;
alter default privileges in schema public revoke execute on functions from public, anon, authenticated;
