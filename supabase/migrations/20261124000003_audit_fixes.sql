-- Fixes from the full product audit (docs/full-audit.md, phase 5 and 6).

-- ---------------------------------------------------------------------------
-- 1. Time zones. The app used to send DateTime.timeZoneName ("AST", "+03",
--    "GMT+03:00"). Postgres reads "AST" as Atlantic Standard Time (UTC-4) and "+03"
--    as UTC-3 (POSIX sign), so a Saudi user's "today" was off by 6-7 hours: streaks,
--    goals and limits rolled over at 7 am. Only IANA names are accepted now.
-- ---------------------------------------------------------------------------

create or replace function public._valid_timezone(p_tz text) returns boolean
language sql stable as $$
  select p_tz is not null
     and (p_tz = 'UTC' or p_tz like '%/%')
     and exists (select 1 from pg_timezone_names where name = p_tz)
$$;

-- Security definer: the trigger also fires on client updates, and clients cannot
-- execute internal helpers.
create or replace function public._profiles_sanitize() returns trigger
language plpgsql security definer set search_path = public as $$
begin
  if not public._valid_timezone(new.timezone) then
    new.timezone := case
      when tg_op = 'UPDATE' and public._valid_timezone(old.timezone) then old.timezone
      else 'Asia/Riyadh'
    end;
  end if;
  return new;
end $$;

drop trigger if exists profiles_sanitize on public.profiles;
create trigger profiles_sanitize before insert or update of timezone on public.profiles
  for each row execute function public._profiles_sanitize();

-- Repair rows written before this fix (launch market default).
update public.profiles set timezone = 'Asia/Riyadh' where not public._valid_timezone(timezone);

-- ---------------------------------------------------------------------------
-- 2. Hifz queue: the 100-row limit was applied before ordering, so a user with a
--    large backlog could get an arbitrary 100 instead of the most at-risk ones.
-- ---------------------------------------------------------------------------
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
  select coalesce(jsonb_agg(x order by x.retention nulls first, x.ayah_id), '[]'::jsonb) into v_reviews from (
    select i.id as item_id, i.ayah_id, a.surah_id, a.ayah_number, a.text_uthmani, i.status, i.interval_days,
           public.hifz_retention(i.interval_days, i.last_reviewed_at) as retention
      from public.hifz_items i join public.ayahs a on a.id = i.ayah_id
     where i.user_id = v_user and i.status <> 'new' and i.due_date <= v_today
     order by public.hifz_retention(i.interval_days, i.last_reviewed_at) nulls first, i.ayah_id
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

-- ---------------------------------------------------------------------------
-- 3. Referrals could be farmed: every guest account is free to create, any account
--    of any age could redeem, two users could refer each other, and the referrer's
--    XP was unbounded. Now: only accounts younger than 14 days, no mutual referrals,
--    and the referrer is rewarded for the first 25 referrals.
-- ---------------------------------------------------------------------------
create or replace function public.apply_referral(p_code text)
returns jsonb language plpgsql security definer set search_path = public as $$
declare
  v_user uuid := auth.uid();
  v_referrer uuid;
  v_created timestamptz;
  v_rewarded int;
begin
  if v_user is null then raise exception 'not authenticated'; end if;
  select id into v_referrer from public.profiles where referral_code = lower(trim(p_code));
  if v_referrer is null or v_referrer = v_user then
    return jsonb_build_object('ok', false, 'reason', 'invalid_code');
  end if;
  if exists (select 1 from public.referrals where referred_id = v_user) then
    return jsonb_build_object('ok', false, 'reason', 'already_referred');
  end if;
  if exists (select 1 from public.referrals where referrer_id = v_user and referred_id = v_referrer) then
    return jsonb_build_object('ok', false, 'reason', 'invalid_code');
  end if;
  select created_at into v_created from public.profiles where id = v_user;
  if v_created < now() - interval '14 days' then
    return jsonb_build_object('ok', false, 'reason', 'too_late');
  end if;
  select count(*) into v_rewarded from public.referrals where referrer_id = v_referrer and rewarded;
  insert into public.referrals (referrer_id, referred_id, rewarded) values (v_referrer, v_user, v_rewarded < 25);
  update public.profiles set referred_by = v_referrer where id = v_user;
  if v_rewarded < 25 then
    update public.profiles set streak_freezes = least(streak_freezes + 1, 5) where id = v_referrer;
    perform public._award_xp(v_referrer, 100, 'referral', v_user::text);
  end if;
  perform public._award_xp(v_user, 50, 'referred', v_referrer::text);
  return jsonb_build_object('ok', true);
end $$;

-- ---------------------------------------------------------------------------
-- 4. Keyword search treated % and _ in the query as wildcards. The edge function now
--    also normalizes Arabic the same way the ingest did (diacritics, alif forms).
-- ---------------------------------------------------------------------------
create or replace function public.search_ayahs_keyword(p_query text, p_translation_id int default 20, p_limit int default 20)
returns table (ayah_id int, surah_id smallint, ayah_number smallint, text_uthmani text, translation text, score real)
language sql stable as $$
  with q as (
    select p_query as raw,
           '%' || replace(replace(replace(p_query, '\', '\\'), '%', '\%'), '_', '\_') || '%' as pattern
  )
  select a.id, a.surah_id, a.ayah_number, a.text_uthmani, t.text,
         greatest(similarity(a.text_simple, q.raw), similarity(coalesce(t.text, ''), q.raw),
                  case when a.text_simple like q.pattern then 0.6 else 0 end)::real as score
    from q, public.ayahs a
    left join public.ayah_translations t on t.ayah_id = a.id and t.translation_id = p_translation_id
   where a.text_simple % q.raw or a.text_simple like q.pattern or t.text ilike q.pattern
   order by score desc, a.id
   limit least(greatest(p_limit, 1), 50)
$$;

-- ---------------------------------------------------------------------------
-- 5. Store webhooks can arrive out of order (RevenueCat retries). Remember the
--    timestamp of the event that last changed the row so an older event cannot
--    overwrite a newer state (for example a late EXPIRATION after a RENEWAL).
-- ---------------------------------------------------------------------------
alter table public.subscriptions add column if not exists last_event_ms bigint;

grant execute on function public.search_ayahs_keyword(text, int, int) to anon, authenticated;
revoke execute on function public._valid_timezone(text), public._profiles_sanitize() from public, anon, authenticated;
grant execute on function public.get_hifz_queue(), public.apply_referral(text) to authenticated;
grant execute on all functions in schema public to service_role;
