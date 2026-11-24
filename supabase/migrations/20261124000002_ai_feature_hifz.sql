-- AI hifz tests (recite from memory, graded automatically) get their own weekly quota,
-- separate from free recitation checks. Kept in its own migration because a new enum
-- value cannot be used in the same transaction that adds it.
alter type public.ai_feature add value if not exists 'hifz';
