-- Muslim AI: core schema
-- Content tables (Quran, translations, tafsir, hadith, adhkar) are public read-only.
-- User tables are protected by RLS (see 20261123000002_rls.sql).

create extension if not exists vector;
create extension if not exists pg_trgm;
create extension if not exists unaccent;

-- ---------------------------------------------------------------------------
-- Enums
-- ---------------------------------------------------------------------------
create type public.goal_type as enum ('quran_read', 'memorize', 'adhkar', 'prayer', 'listen');
create type public.prayer_name as enum ('fajr', 'dhuhr', 'asr', 'maghrib', 'isha');
create type public.hifz_status as enum ('new', 'learning', 'review', 'mastered');
create type public.review_source as enum ('self', 'ai');
create type public.recitation_mode as enum ('read', 'hifz');
create type public.job_status as enum ('pending', 'processing', 'done', 'failed');
create type public.ai_feature as enum ('recitation', 'ask', 'search');
create type public.content_source as enum ('ayah', 'tafsir', 'hadith');
create type public.subscription_status as enum ('active', 'grace_period', 'billing_issue', 'cancelled', 'expired', 'paused');
create type public.store_name as enum ('app_store', 'play_store', 'stripe', 'promotional', 'other');

-- ---------------------------------------------------------------------------
-- Profiles
-- ---------------------------------------------------------------------------
create table public.profiles (
  id uuid primary key references auth.users (id) on delete cascade,
  display_name text,
  locale text not null default 'ar' check (locale in ('ar', 'en', 'ur', 'id', 'tr', 'fr')),
  country_code text,
  timezone text not null default 'Asia/Riyadh',
  reciter_id int,
  translation_id int,
  onboarding_completed boolean not null default false,
  referral_code text unique not null default substr(replace(gen_random_uuid()::text, '-', ''), 1, 8),
  referred_by uuid references public.profiles (id) on delete set null,
  xp int not null default 0,
  level int not null default 1,
  current_streak int not null default 0,
  longest_streak int not null default 0,
  last_active_date date,
  streak_freezes int not null default 1 check (streak_freezes between 0 and 5),
  notification_prefs jsonb not null default '{"morning_adhkar":"06:30","evening_adhkar":"17:30","hifz_review":"20:00"}'::jsonb,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

-- ---------------------------------------------------------------------------
-- Quran content
-- ---------------------------------------------------------------------------
create table public.surahs (
  id smallint primary key check (id between 1 and 114),
  name_ar text not null,
  name_en text not null,
  transliteration text not null,
  revelation_place text not null check (revelation_place in ('makkah', 'madinah')),
  ayah_count smallint not null
);

create table public.ayahs (
  id int primary key,                       -- global ayah index 1..6236
  surah_id smallint not null references public.surahs (id),
  ayah_number smallint not null,
  text_uthmani text not null,
  text_simple text not null,                -- normalized, no diacritics (search + alignment)
  juz smallint not null,
  hizb_quarter smallint,
  page smallint not null,
  unique (surah_id, ayah_number)
);
create index ayahs_text_simple_trgm on public.ayahs using gin (text_simple gin_trgm_ops);

create table public.ayah_words (
  id bigint generated always as identity primary key,
  ayah_id int not null references public.ayahs (id) on delete cascade,
  position smallint not null,
  text_uthmani text not null,
  text_simple text not null,
  unique (ayah_id, position)
);

create table public.translations (
  id int primary key,
  language text not null,
  name text not null,
  author text not null,
  source text not null,
  license text
);

create table public.ayah_translations (
  translation_id int not null references public.translations (id) on delete cascade,
  ayah_id int not null references public.ayahs (id) on delete cascade,
  text text not null,
  primary key (translation_id, ayah_id)
);
create index ayah_translations_text_trgm on public.ayah_translations using gin (text gin_trgm_ops);

create table public.tafsir_sources (
  id int primary key,
  language text not null,
  name text not null,
  author text not null,
  source text not null,
  license text
);

create table public.ayah_tafsir (
  tafsir_id int not null references public.tafsir_sources (id) on delete cascade,
  ayah_id int not null references public.ayahs (id) on delete cascade,
  text text not null,
  primary key (tafsir_id, ayah_id)
);

create table public.reciters (
  id int primary key,
  name_en text not null,
  name_ar text not null,
  style text,                               -- murattal | mujawwad | muallim
  audio_url_template text not null,         -- e.g. https://cdn/.../{surah3}{ayah3}.mp3
  is_premium boolean not null default false,
  sort smallint not null default 0
);

-- ---------------------------------------------------------------------------
-- Hadith content
-- ---------------------------------------------------------------------------
create table public.hadith_collections (
  id int primary key,
  slug text unique not null,
  name_en text not null,
  name_ar text not null,
  source text not null,
  license text
);

create table public.hadiths (
  id bigint primary key,
  collection_id int not null references public.hadith_collections (id),
  hadith_number text not null,
  book text,
  chapter text,
  text_ar text not null,
  text_en text,
  grade text,                               -- sahih / hasan / da'if as given by the source
  grade_source text,
  reference text not null,                  -- human readable, e.g. "Sahih al-Bukhari 6114"
  unique (collection_id, hadith_number)
);

-- ---------------------------------------------------------------------------
-- Embeddings (semantic search + RAG). voyage-3.5 => 1024 dims
-- ---------------------------------------------------------------------------
create table public.content_embeddings (
  id bigint generated always as identity primary key,
  source_type public.content_source not null,
  source_id bigint not null,                -- ayahs.id | tafsir ayah_id | hadiths.id
  source_variant int,                       -- tafsir_id / translation_id used to build the chunk
  language text not null,
  chunk text not null,
  embedding vector(1024) not null,
  created_at timestamptz not null default now(),
  unique (source_type, source_id, source_variant, language)
);
create index content_embeddings_hnsw on public.content_embeddings using hnsw (embedding vector_cosine_ops);
create index content_embeddings_source on public.content_embeddings (source_type);

-- ---------------------------------------------------------------------------
-- Adhkar
-- ---------------------------------------------------------------------------
create table public.adhkar_categories (
  id smallint primary key,
  slug text unique not null,               -- morning | evening | sleep | travel | after_prayer
  name_ar text not null,
  name_en text not null,
  sort smallint not null default 0
);

create table public.adhkar (
  id int primary key,
  category_id smallint not null references public.adhkar_categories (id),
  text_ar text not null,
  transliteration text,
  translation_en text not null,
  repeat_count smallint not null default 1,
  reference text not null,
  virtue_en text,
  audio_url text,
  sort smallint not null default 0
);

-- ---------------------------------------------------------------------------
-- Goals, activity, streaks, gamification
-- ---------------------------------------------------------------------------
create table public.goals (
  user_id uuid not null references public.profiles (id) on delete cascade,
  goal_type public.goal_type not null,
  daily_target int not null check (daily_target > 0),
  active boolean not null default true,
  updated_at timestamptz not null default now(),
  primary key (user_id, goal_type)
);

create table public.daily_activity (
  user_id uuid not null references public.profiles (id) on delete cascade,
  activity_date date not null,
  ayahs_read int not null default 0,
  minutes_listened int not null default 0,
  adhkar_completed int not null default 0,
  ayahs_memorized int not null default 0,
  reviews_done int not null default 0,
  prayers_logged int not null default 0,
  recitations int not null default 0,
  xp_earned int not null default 0,
  goals_met boolean not null default false,
  primary key (user_id, activity_date)
);

create table public.xp_events (
  id bigint generated always as identity primary key,
  user_id uuid not null references public.profiles (id) on delete cascade,
  amount int not null,
  kind text not null,
  ref text,
  created_at timestamptz not null default now()
);
create index xp_events_user_time on public.xp_events (user_id, created_at desc);

-- XP rules live in the DB so they can be tuned without an app release.
create table public.xp_rules (
  kind text primary key,
  xp_per_unit int not null,
  daily_unit_cap int not null,
  activity_column text not null
);

create table public.achievements (
  id text primary key,                     -- slug
  name_ar text not null,
  name_en text not null,
  description_ar text not null,
  description_en text not null,
  icon text not null,
  xp_reward int not null default 0,
  metric text not null,                    -- streak | xp | ayahs_read | ayahs_memorized | adhkar | recitations | prayers
  threshold int not null,
  sort smallint not null default 0
);

create table public.user_achievements (
  user_id uuid not null references public.profiles (id) on delete cascade,
  achievement_id text not null references public.achievements (id),
  unlocked_at timestamptz not null default now(),
  primary key (user_id, achievement_id)
);

create table public.prayer_logs (
  user_id uuid not null references public.profiles (id) on delete cascade,
  log_date date not null,
  prayer public.prayer_name not null,
  on_time boolean not null default true,
  created_at timestamptz not null default now(),
  primary key (user_id, log_date, prayer)
);

create table public.adhkar_progress (
  user_id uuid not null references public.profiles (id) on delete cascade,
  progress_date date not null,
  category_id smallint not null references public.adhkar_categories (id),
  completed_ids int[] not null default '{}',
  completed boolean not null default false,
  updated_at timestamptz not null default now(),
  primary key (user_id, progress_date, category_id)
);

create table public.reading_progress (
  user_id uuid primary key references public.profiles (id) on delete cascade,
  last_ayah_id int references public.ayahs (id),
  khatmah_started_at date,
  updated_at timestamptz not null default now()
);

create table public.bookmarks (
  user_id uuid not null references public.profiles (id) on delete cascade,
  ayah_id int not null references public.ayahs (id),
  note text,
  created_at timestamptz not null default now(),
  primary key (user_id, ayah_id)
);

-- ---------------------------------------------------------------------------
-- Hifz (memorization) with spaced repetition
-- ---------------------------------------------------------------------------
create table public.hifz_plans (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.profiles (id) on delete cascade,
  title text,
  start_ayah_id int not null references public.ayahs (id),
  end_ayah_id int not null references public.ayahs (id),
  daily_new_ayahs smallint not null default 3 check (daily_new_ayahs between 1 and 50),
  active boolean not null default true,
  created_at timestamptz not null default now(),
  check (end_ayah_id >= start_ayah_id)
);
create index hifz_plans_user on public.hifz_plans (user_id) where active;

create table public.hifz_items (
  id bigint generated always as identity primary key,
  user_id uuid not null references public.profiles (id) on delete cascade,
  plan_id uuid not null references public.hifz_plans (id) on delete cascade,
  ayah_id int not null references public.ayahs (id),
  status public.hifz_status not null default 'new',
  ease_factor numeric(4, 2) not null default 2.50,
  interval_days int not null default 0,
  repetitions int not null default 0,
  lapses int not null default 0,
  due_date date,
  introduced_on date,
  last_reviewed_at timestamptz,
  last_score smallint,
  unique (user_id, ayah_id)
);
create index hifz_items_due on public.hifz_items (user_id, due_date) where status <> 'new';
create index hifz_items_new on public.hifz_items (plan_id, ayah_id) where status = 'new';

create table public.hifz_reviews (
  id bigint generated always as identity primary key,
  user_id uuid not null references public.profiles (id) on delete cascade,
  item_id bigint not null references public.hifz_items (id) on delete cascade,
  score smallint not null check (score between 0 and 5),
  source public.review_source not null,
  recitation_id uuid,
  reviewed_at timestamptz not null default now()
);
create index hifz_reviews_user_time on public.hifz_reviews (user_id, reviewed_at desc);

-- ---------------------------------------------------------------------------
-- AI recitation coach
-- ---------------------------------------------------------------------------
create table public.recitation_sessions (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.profiles (id) on delete cascade,
  mode public.recitation_mode not null default 'read',
  start_ayah_id int not null references public.ayahs (id),
  end_ayah_id int not null references public.ayahs (id),
  audio_path text not null,                -- storage: recitations/{user_id}/{id}.m4a
  status public.job_status not null default 'pending',
  error text,
  transcript text,
  words_total int,
  words_correct int,
  accuracy_score numeric(5, 2),            -- 0..100
  fluency_score numeric(5, 2),
  tajweed_score numeric(5, 2),
  overall_score numeric(5, 2),
  mistakes jsonb not null default '[]'::jsonb,
  duration_ms int,
  created_at timestamptz not null default now(),
  completed_at timestamptz,
  check (end_ayah_id >= start_ayah_id and end_ayah_id - start_ayah_id < 50)
);
create index recitation_sessions_user_time on public.recitation_sessions (user_id, created_at desc);

-- ---------------------------------------------------------------------------
-- AI assistant / Ask the Quran
-- ---------------------------------------------------------------------------
create table public.ai_conversations (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.profiles (id) on delete cascade,
  kind text not null check (kind in ('assistant', 'ask_quran')),
  title text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);
create index ai_conversations_user on public.ai_conversations (user_id, updated_at desc);

create table public.ai_messages (
  id bigint generated always as identity primary key,
  conversation_id uuid not null references public.ai_conversations (id) on delete cascade,
  user_id uuid not null references public.profiles (id) on delete cascade,
  role text not null check (role in ('user', 'assistant')),
  content text not null,
  structured jsonb,                         -- {quran:[], hadith:[], scholarly:[], ...}
  model text,
  input_tokens int,
  output_tokens int,
  created_at timestamptz not null default now()
);
create index ai_messages_conversation on public.ai_messages (conversation_id, id);

create table public.plan_limits (
  feature public.ai_feature primary key,
  free_daily int not null,
  premium_daily int not null               -- fair-use cap that protects unit economics
);

create table public.ai_usage (
  user_id uuid not null references public.profiles (id) on delete cascade,
  usage_date date not null,
  feature public.ai_feature not null,
  count int not null default 0,
  primary key (user_id, usage_date, feature)
);

-- ---------------------------------------------------------------------------
-- Subscriptions (provider-agnostic; RevenueCat at launch)
-- ---------------------------------------------------------------------------
create table public.subscriptions (
  user_id uuid primary key references public.profiles (id) on delete cascade,
  provider text not null default 'revenuecat',
  entitlement text not null default 'premium',
  status public.subscription_status not null,
  store public.store_name,
  product_id text,
  period_type text,                         -- normal | trial | intro
  current_period_end timestamptz,
  will_renew boolean,
  original_transaction_id text,
  environment text,                         -- production | sandbox
  updated_at timestamptz not null default now()
);

create table public.billing_events (
  id bigint generated always as identity primary key,
  provider text not null,
  event_id text not null,
  user_id uuid,
  event_type text not null,
  payload jsonb not null,
  received_at timestamptz not null default now(),
  unique (provider, event_id)
);

-- ---------------------------------------------------------------------------
-- Referrals
-- ---------------------------------------------------------------------------
create table public.referrals (
  referrer_id uuid not null references public.profiles (id) on delete cascade,
  referred_id uuid not null references public.profiles (id) on delete cascade,
  created_at timestamptz not null default now(),
  rewarded boolean not null default false,
  primary key (referred_id)
);

-- ---------------------------------------------------------------------------
-- updated_at trigger
-- ---------------------------------------------------------------------------
create or replace function public.touch_updated_at() returns trigger
language plpgsql as $$
begin
  new.updated_at = now();
  return new;
end $$;

create trigger profiles_touch before update on public.profiles
  for each row execute function public.touch_updated_at();
create trigger goals_touch before update on public.goals
  for each row execute function public.touch_updated_at();
create trigger ai_conversations_touch before update on public.ai_conversations
  for each row execute function public.touch_updated_at();
create trigger adhkar_progress_touch before update on public.adhkar_progress
  for each row execute function public.touch_updated_at();
