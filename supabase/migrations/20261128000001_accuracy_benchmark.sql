-- Recitation accuracy benchmark: labelled clips recorded by volunteers in the app
-- (Settings → Accuracy recordings, only in builds with BENCHMARK_RECORDER=true).
--
-- Unlike normal recitations, these recordings are KEPT: the volunteer agrees to that on the
-- consent screen, the audio is private (service role reads it with scripts/accuracy/export.ts),
-- the volunteer can delete their own clips, and deleting the account deletes them too.

create table public.benchmark_clips (
  id uuid primary key,
  user_id uuid not null references public.profiles (id) on delete cascade,
  start_ayah_id int not null references public.ayahs (id),
  end_ayah_id int not null references public.ayahs (id),
  audio_path text not null,                         -- storage: benchmark-clips/{user_id}/{id}.m4a
  speaker_group text not null check (speaker_group in ('man', 'woman', 'child')),
  native_arabic boolean not null,
  environment text not null check (environment in ('quiet', 'noisy')),
  -- Ground truth from the volunteer: [{ "ayah_id": 2, "position": 3, "type": "wrong" }].
  -- Every other word in the range was recited correctly. [] = a clean recitation.
  mistakes jsonb not null default '[]'::jsonb check (jsonb_typeof(mistakes) = 'array'),
  duration_ms int check (duration_ms > 0 and duration_ms <= 300000),
  app_version text,
  consented_at timestamptz not null,
  created_at timestamptz not null default now(),
  check (end_ayah_id >= start_ayah_id and end_ayah_id - start_ayah_id < 50),
  check (audio_path like user_id::text || '/%')
);
create index benchmark_clips_user on public.benchmark_clips (user_id, created_at desc);

alter table public.benchmark_clips enable row level security;
create policy benchmark_clips_insert_own on public.benchmark_clips for insert to authenticated
  with check (user_id = auth.uid());
create policy benchmark_clips_read_own on public.benchmark_clips for select to authenticated
  using (user_id = auth.uid());
create policy benchmark_clips_delete_own on public.benchmark_clips for delete to authenticated
  using (user_id = auth.uid());
-- No update policy: a clip's labels are fixed once saved (delete and record again instead).
revoke update on public.benchmark_clips from anon, authenticated;
revoke all on public.benchmark_clips from anon;

insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values ('benchmark-clips', 'benchmark-clips', false, 10485760,
        array['audio/mp4', 'audio/m4a', 'audio/x-m4a', 'audio/aac', 'audio/wav', 'audio/webm'])
on conflict (id) do nothing;

create policy benchmark_upload_own on storage.objects for insert to authenticated
  with check (bucket_id = 'benchmark-clips' and (storage.foldername(name))[1] = auth.uid()::text);
create policy benchmark_delete_own on storage.objects for delete to authenticated
  using (bucket_id = 'benchmark-clips' and (storage.foldername(name))[1] = auth.uid()::text);
-- No select policy on the bucket: only the service role (export script) can download audio.
