-- Restore Supabase's classic table grants, then re-apply this schema's narrowing.
--
-- Every earlier migration assumes the old Supabase default: anon, authenticated and service_role
-- get all privileges on new public tables, and RLS + targeted revokes do the protecting. Newer
-- Supabase projects no longer grant these by default, so on production the edge functions
-- (service_role) and the app (anon / authenticated) got "permission denied" on every table, and
-- the earlier revokes were no-ops. RLS policies are unchanged and still decide which rows anyone sees.
-- Idempotent: safe to run on a project that already had the old defaults.

grant usage on schema public to anon, authenticated, service_role;

grant all on all tables in schema public to anon, authenticated, service_role;
grant all on all sequences in schema public to anon, authenticated, service_role;
alter default privileges in schema public grant all on tables to anon, authenticated, service_role;
alter default privileges in schema public grant all on sequences to anon, authenticated, service_role;

-- Re-apply the narrowing from earlier migrations (identical statements).
-- 20261123000002_rls_and_storage
revoke update on public.profiles from authenticated;
grant update (display_name, locale, country_code, timezone, reciter_id, translation_id,
              onboarding_completed, notification_prefs) on public.profiles to authenticated;
do $$
declare t text;
begin
  foreach t in array array['daily_activity','xp_events','user_achievements','hifz_items','hifz_reviews',
                           'ai_conversations','ai_messages','ai_usage','subscriptions'] loop
    execute format('revoke insert, update, delete on public.%I from anon, authenticated', t);
  end loop;
end $$;
revoke insert, update, delete on public.referrals from anon, authenticated;
revoke insert, update, delete on public.recitation_sessions from anon, authenticated;
grant insert (id, user_id, mode, start_ayah_id, end_ayah_id, audio_path) on public.recitation_sessions to authenticated;
revoke all on public.billing_events, public.content_embeddings from anon, authenticated;
-- 20261124000001_ai_cost_cap
revoke all on public.ai_budget_settings, public.ai_calls from anon, authenticated;
revoke insert, update, delete on public.ai_spend from anon, authenticated;
-- 20261124000004_value_first_monetization
revoke insert, update, delete on public.hifz_milestones from anon, authenticated;
-- 20261125000001_free_ai_guard
revoke all on public.ai_free_pool from anon, authenticated;
