-- Row level security. Rule of thumb:
--   * content tables: readable by anon + authenticated, writable only by service role
--   * user tables: a user sees and edits only their own rows
--   * gamification, subscriptions, usage, and AI results: read-only to the user;
--     written only via SECURITY DEFINER functions or edge functions (service role),
--     so XP / premium status cannot be forged from the client.

-- Content (public read)
do $$
declare t text;
begin
  foreach t in array array[
    'surahs','ayahs','ayah_words','translations','ayah_translations','tafsir_sources',
    'ayah_tafsir','reciters','hadith_collections','hadiths','adhkar_categories','adhkar',
    'achievements','xp_rules','plan_limits'
  ] loop
    execute format('alter table public.%I enable row level security', t);
    execute format('create policy "%s_public_read" on public.%I for select to anon, authenticated using (true)', t, t);
  end loop;
end $$;

-- Embeddings: no direct client access (served through RPC / edge functions)
alter table public.content_embeddings enable row level security;

-- Profiles
alter table public.profiles enable row level security;
create policy profiles_select_own on public.profiles for select to authenticated using (id = auth.uid());
create policy profiles_update_own on public.profiles for update to authenticated using (id = auth.uid()) with check (id = auth.uid());
-- Columns a client may change. Everything else (xp, level, streaks, referral) is server-owned.
revoke update on public.profiles from authenticated;
grant update (display_name, locale, country_code, timezone, reciter_id, translation_id,
              onboarding_completed, notification_prefs) on public.profiles to authenticated;

-- Fully user-owned tables (CRUD on own rows)
do $$
declare t text;
begin
  foreach t in array array['goals','prayer_logs','adhkar_progress','reading_progress','bookmarks','hifz_plans'] loop
    execute format('alter table public.%I enable row level security', t);
    execute format('create policy "%s_own_all" on public.%I for all to authenticated using (user_id = auth.uid()) with check (user_id = auth.uid())', t, t);
  end loop;
end $$;

-- Read-only to owner (written by functions)
do $$
declare t text;
begin
  foreach t in array array['daily_activity','xp_events','user_achievements','hifz_items','hifz_reviews',
                           'ai_conversations','ai_messages','ai_usage','subscriptions'] loop
    execute format('alter table public.%I enable row level security', t);
    execute format('create policy "%s_own_read" on public.%I for select to authenticated using (user_id = auth.uid())', t, t);
    execute format('revoke insert, update, delete on public.%I from anon, authenticated', t);
  end loop;
end $$;
-- referrals uses referrer_id/referred_id
alter table public.referrals enable row level security;
revoke insert, update, delete on public.referrals from anon, authenticated;
create policy referrals_own_read on public.referrals for select to authenticated
  using (referrer_id = auth.uid() or referred_id = auth.uid());

-- Recitation sessions: the client creates the row (pending) after uploading audio;
-- scores are written by the recitation-analyze edge function only.
alter table public.recitation_sessions enable row level security;
create policy recitation_select_own on public.recitation_sessions for select to authenticated using (user_id = auth.uid());
create policy recitation_insert_own on public.recitation_sessions for insert to authenticated
  with check (user_id = auth.uid() and status = 'pending');
revoke insert, update, delete on public.recitation_sessions from anon, authenticated;
grant insert (id, user_id, mode, start_ayah_id, end_ayah_id, audio_path) on public.recitation_sessions to authenticated;

-- billing_events: service role only
alter table public.billing_events enable row level security;
revoke all on public.billing_events, public.content_embeddings from anon, authenticated;

-- ---------------------------------------------------------------------------
-- Storage: private bucket for recitation audio, 10 MB cap. The recitation-analyze
-- function deletes each file right after analysis (privacy + storage cost).
-- ---------------------------------------------------------------------------
insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values ('recitations', 'recitations', false, 10485760,
        array['audio/mp4', 'audio/m4a', 'audio/x-m4a', 'audio/aac', 'audio/wav', 'audio/webm', 'audio/mpeg'])
on conflict (id) do nothing;

create policy recitations_upload_own on storage.objects for insert to authenticated
  with check (bucket_id = 'recitations' and (storage.foldername(name))[1] = auth.uid()::text);
create policy recitations_read_own on storage.objects for select to authenticated
  using (bucket_id = 'recitations' and (storage.foldername(name))[1] = auth.uid()::text);
create policy recitations_delete_own on storage.objects for delete to authenticated
  using (bucket_id = 'recitations' and (storage.foldername(name))[1] = auth.uid()::text);
