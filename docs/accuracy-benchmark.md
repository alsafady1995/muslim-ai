# Recitation accuracy benchmark

How we prove (or disprove) that Asmi3ni hears recitation correctly before launch, and how we compare it with Tarteel
on the same recordings. Code: `scripts/accuracy/`, the in-app recorder in `app/lib/features/benchmark/`, and the
`benchmark_clips` table (`supabase/migrations/20261124000010_accuracy_benchmark.sql`).

## ملخص بالعربية

**الهدف:** نعرف بالأرقام كم مرة التطبيق بيقول "غلط" على كلمة صحيحة، وكم خطأ حقيقي بيلقط، قبل ما نطلق.

**الخطوات:**
1. ابني نسخة داخلية من التطبيق فيها `BENCHMARK_RECORDER=true`. بيظهر بالإعدادات خيار "تسجيلات قياس الدقة".
2. خلّي ٣٠ شخص على الأقل (رجال، نساء، أطفال مع أهلهم، وناس لغتهم الأم مش عربي) يسجّلوا ٣٠٠ مقطع. كل واحد بيقرأ
   المقطع كامل، وبعد التسجيل بيضغط على الكلمات اللي غلط فيها. حوالي ٤٠٪ من المقاطع لازم يكون فيها أخطاء متعمّدة.
3. شغّل `deno task export` لتنزيل المقاطع، وبعدها `deno task run --sweep` لتطلع النتيجة.
4. للمقارنة مع ترتيل: شغّل ٥٠ مقطع جنب تطبيق ترتيل، واكتب الكلمات اللي علّمها كأخطاء بملف، وشغّل نفس الأداة عليه.

**شروط الإطلاق المقترحة:** أقل من ٥٪ من التلاوات الصحيحة ياخدوا أي تنبيه خاطئ، وأقل من ١٪ من الكلمات الصحيحة
تتعلّم كغلط، و٨٠٪ على الأقل من الأخطاء الحقيقية تنلقط.

---

## 1. What is measured

Every recording is labelled by the person who made it: they recite a range, then tap the words they got wrong or
skipped. Every other word is treated as correct. The benchmark runs the same ASR service and the same alignment code
the app uses (`supabase/functions/_shared/alignment.ts`) and compares.

| Metric | Meaning | Proposed launch gate |
| --- | --- | --- |
| Clean recitations with any false flag | Of clips recited perfectly, how many still showed at least one "mistake". This is the Al-Fatiha-in-onboarding moment | ≤ 5% |
| Correct words flagged as mistakes | Share of correctly recited words shown as wrong, mispronounced, skipped or unread | ≤ 1% |
| Real mistakes caught | Share of labelled mistakes shown as a mistake | ≥ 80% |
| Correct words "not sure" | Shown as our `unclear` state; not counted as a false flag, but reported | report only |
| Speed | Seconds per clip (median, 95th percentile) and seconds of processing per second of audio | report only |

Every metric is also broken down by speaker (man, woman, child), Arabic as first language, recording environment,
clean vs with mistakes, and surah. The gates are in `scripts/accuracy/metrics.ts` (`DEFAULT_GATES`).

`--sweep` re-scores the cached ASR output at different word-match thresholds (`THRESHOLDS.correct`, today 0.85), so
the trade-off between false flags and caught mistakes can be chosen from data instead of guessed.

## 2. Collecting the clips

Build an internal app with the recorder switched on (never in store builds):

```bash
cd app
flutter build ipa --dart-define-from-file=env/prod.json --dart-define=BENCHMARK_RECORDER=true   # TestFlight
flutter build apk --dart-define-from-file=env/prod.json --dart-define=BENCHMARK_RECORDER=true   # Android
```

Settings → **Accuracy recordings**: consent (once), who is reciting, the range, record, mark mistakes, save. Clips go
to the private `benchmark-clips` bucket. Unlike normal checks they are kept; volunteers can delete all their clips from
the screen's menu, and deleting the account deletes them too.

Target set (about 300 clips, at least 30 different people):

| Dimension | Target mix |
| --- | --- |
| Speaker | about 40% men, 30% women, 20% children (with a parent), the rest any |
| Arabic as first language | at least 30% non-native |
| Content | at least 60 clips of Al-Fatiha (the onboarding check); Juz Amma short surahs; a few long passages (e.g. Al-Baqarah 1–5, Al-Mulk) |
| Mistakes | about 60% clean recitations, 40% with 1–3 mistakes (deliberate is fine: a wrong word, a skipped word) |
| Environment | about 70% quiet, 30% with background noise |

Ask volunteers to listen back before saving; a wrong label counts against us. The report lists the clips with the
most disagreements so they can be checked by ear.

## 3. Running it

```bash
cd scripts/accuracy

# 1. Download clips and labels (service role key; audio is only readable this way)
SUPABASE_URL=... SUPABASE_SERVICE_ROLE_KEY=... deno task export --out ../../bench-data

# 2. Score our system. Use the deployed ASR service, or run it locally:
#    docker build -t asmi3ni-asr ../../services/asr && docker run -p 8080:8080 -e ASR_SERVICE_TOKEN=dev asmi3ni-asr
ASR_SERVICE_URL=http://localhost:8080 ASR_SERVICE_TOKEN=dev deno task run --dataset ../../bench-data --sweep
```

Output in `bench-data/results/asmi3ni/`: `report.md` (gates, breakdowns, threshold sweep, clips to listen to),
`report.json`, `clips.jsonl`. ASR output is cached per clip; pass `--fresh` after changing the model. Keep
`bench-data/` out of git: it holds people's voices.

## 4. Comparing with Tarteel (or any other app)

Tarteel does not take audio files, so its results are typed in by hand on a subset (about 50 clips, same mix):

1. Open Tarteel's mistake detection on a phone, play the clip from a laptop speaker next to it, and note which words it
   marks. Playback through a speaker is harder than live recitation, so treat Tarteel's numbers as a lower bound.
2. Write one line per clip to `tarteel.jsonl`, using the word positions from `bench-data/manifest.jsonl`:
   `{"id": "<clip id>", "flags": [{"ayahId": 2, "position": 3}], "unsure": []}`
3. `deno task run --dataset ../../bench-data --predictions tarteel.jsonl --system Tarteel`

Both reports use the same metrics. Compare on the same clip ids only (run ours with a manifest filtered to that subset
if needed).

## 5. Decisions this unlocks

- **Launch or not.** If the clean-recitation gate fails on Al-Fatiha, the onboarding check must not ship as it is.
- **Threshold.** Pick `THRESHOLDS.correct` from the sweep; it is one constant.
- **"Not sure" instead of "wrong".** If false flags concentrate on low-confidence words, show them as `unclear`.
- **Model.** If children or non-native speakers fail, test a larger Whisper model on the same set before anything else.
  Changing the model is `HF_MODEL` in `services/asr/Dockerfile`, then `--fresh`.
