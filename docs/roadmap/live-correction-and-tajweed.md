# Live correction and tajweed: implementation plan

Status: plan only, nothing here is built yet. Written 2026-11-25.
Arabic summary and the list of questions for the sheikh: [sheikh-brief-ar.md](sheikh-brief-ar.md).

## 0. Where we are today

- **Engine:** `services/asr` runs `tarteel-ai/whisper-base-ar-quran` (Apache-2.0, confirmed on the model card) with
  faster-whisper on Cloud Run CPU. The app uploads a whole recording after the user stops. `recitation-analyze` then
  aligns the transcript to the expected words (`_shared/alignment.ts`) and reports wrong, skipped and unclear words a
  few seconds later.
- **Tajweed:** one heuristic only. `possible_short_madd` flags a word with a madd sign that was recited much faster per
  letter than the reciter's own median. It is a hint, not a ruling.
- **Accuracy is not measured yet.** PR #11 adds the benchmark (`scripts/accuracy/`) and the in-app labelled clip
  recorder, with proposed gates: at most 5% of clean recitations get any false flag, at most 1% of correct words are
  flagged, at least 80% of real mistakes are caught.

The order stays: **1) measure, 2) live correction, 3) tajweed.** What changes now that a sheikh is available is that
his work can start **today, in parallel**, because the single most valuable thing he can produce (a gold set of
clips labelled by an expert) is needed by all three steps.

## 1. Live (in-recitation) correction

### 1.1 Key idea

Live correction is not open speech recognition. We know which ayah the user is reciting, so the problem is
**tracking a known text**: "which word is the user on, and did the last word match?". That is much easier and
cheaper than transcription, and it can run on the phone.

### 1.2 Architecture options

| Option | How | Latency to a flag | Cost | Verdict |
|---|---|---|---|---|
| A. Server streaming Whisper | WebSocket from app, re-transcribe a sliding 5–10 s window every ~1 s | 1.5–3 s; Whisper is not a streaming model and repeats/hallucinates at window edges | Highest (instance busy for the whole recitation) | Prototype only, as a baseline |
| B. Server streaming CTC tracker | WebSocket, a small CTC phoneme/char model, align incrementally against the expected text | 0.5–1.5 s | Medium | Good fallback for weak phones |
| **C. On-device CTC tracker + server confirmation** | Small ONNX model on the phone tracks position and raises *candidate* mistakes live; the existing upload-and-analyse path still runs at the end and is the record of truth (score, hifz grade, XP) | 0.3–1 s, works offline | Near zero per minute for the live part | **Recommended** |

Why C: it removes per-minute server cost for the live layer, works with no network, and keeps today's server path
(already tested, already cost-capped) as the authority. Live flags only change the UI; nothing is graded from them.

### 1.3 Candidate on-device models (all need our own benchmark)

| Model | License (checked) | What it gives | Notes |
|---|---|---|---|
| [HisnLabs/tajweed-v2](https://huggingface.co/HisnLabs/tajweed-v2) | Apache-2.0 | Phonetic symbols with times and probabilities; per-word tajweed remarks (madd, ghunna, ikhfa, iqlab, idgham, qalqalah); Hafs and Warsh | 23 MB int8 ONNX, self-reported 28 ms for 4 s of audio on an M1 and PER 7.0% on QDAT bench. Input is one ayah or phrase up to 30 s, so we must chunk. Built on Tarteel whisper-base encoder; teacher labels from obadx muaalem (card says MIT). Very new and self-reported: treat every number as a claim until our benchmark confirms it. |
| `tarteel-ai/whisper-tiny-ar-quran` / `whisper-base` on device (whisper.cpp) | Apache-2.0 | Words | Not streaming, heavier, same edge problems as option A |
| Muno459 / Quran-Lab zipformer streaming models | **Non-commercial (NPL-1.1, gated)** | Streaming phonemes | **Cannot be used**: Asmi3ni has paid plans |
| Meta MMS / torchaudio `MMS_FA` aligner | **CC-BY-NC 4.0** | Forced alignment | **Cannot be used** commercially |

Plan: spike HisnLabs tajweed-v2 first (license fits, size fits a phone, and it also gives us a path to tajweed).
Fallback is option B with the same model on the server.

### 1.4 Latency budget (target p90, mid-range Android)

- Audio frames to model: 20 ms chunks, inference every 300–500 ms on the last 2–4 s.
- Word "done" detection: word end + 400 ms of the next word (we wait for the next word so a slow reciter is not
  flagged mid-word).
- **Target: a candidate flag within 1.5 s of the end of the wrong word, p90.** Measured on a Samsung A-series class
  phone, not a flagship.

### 1.5 Cost per user-minute

Prices from the [Cloud Run pricing page](https://cloud.google.com/run/pricing) (instance-based, tier 1): $0.000018 per
vCPU-s, $0.000002 per GiB-s, NVIDIA L4 $0.0001867 per s.

| Setup | Per instance-minute | Streams per instance (assumed, to be measured) | Per user-minute |
|---|---|---|---|
| Today: batch Whisper-base, 2 vCPU / 2 GiB, ~5–10× real time | $0.0024 | n/a (≈6–12 s of compute per audio minute) | **≈ $0.0003–0.0005** (env uses $0.001 to be safe) |
| Option B: CPU streaming, 4 vCPU / 4 GiB | $0.0048 | 4 | ≈ $0.0012 |
| Option A/B on GPU, L4 + 4 vCPU / 16 GiB | ≈ $0.017 | 20–40 if full | ≈ $0.0005–0.0009 when busy, but an always-on GPU instance costs ≈ **$25/day** idle |
| **Option C: on-device** | $0 for the live layer | n/a | **≈ $0.0005** (only the final batch check, as today) |

Budget check: a Premium annual user nets roughly $21–25 a year after store fees, and the cost cap allows 50% of that,
≈ $0.9 a month. At $0.0012 a minute, option B gives ≈ 750 live minutes a month before the cap; option C keeps us at
today's cost. GPU only makes sense after there are enough concurrent users to keep it busy.

### 1.6 Offline fallback

- Option C works offline for live tracking. Without network, the final check is queued and sent when online (the audio
  stays on the phone until then, then is deleted as today).
- If the device is too slow (we measure inference time in the first 3 s), the app turns off live flags and silently
  falls back to today's after-recitation check.

### 1.7 UX

- **Follow mode (default):** the current word is softly highlighted as the user recites. No red marks during the
  recitation.
- **Live mistakes:** a skipped or wrong word gets a gentle amber underline after the 1.5 s confirmation, never a sound,
  never a pop-up. Red only appears on the final result screen, after the server confirms.
- **Stop-on-mistake mode (opt-in, for hifz tests):** recitation pauses and shows the first word of the correct ayah
  as a hint, like a teacher who stops the student.
- Every flag has **"This is wrong"**. It saves the clip (with consent) to the review queue for the sheikh. This is how
  we find false flags in real use.

### 1.8 Safeguards against false flags

1. Live flags need high confidence: model probability above a threshold chosen with `--sweep` on the gold set, and
   the word must be missing or different in **two** consecutive decodes.
2. Live flags never grade anything. Score, hifz SM-2 grades and XP come only from the server check.
3. A remote-config kill switch (`live_correction_enabled`, `live_min_confidence`) so we can switch it off without a
   release.
4. Onboarding Al-Fatiha uses follow mode only (no live mistake marks) until the false-flag gate is met on that surah.
5. Accept the known valid variations: pausing and restarting a word, repeating an ayah, a different but valid waqf.
   The sheikh helps us list these.
6. Track `false_flag_reports / live_flags` per surah in PostHog; alert above 5%.

## 2. Tajweed

### 2.1 Decide the standard first

Before any rule: **riwayah and tariq** (we assume Hafs 'an 'Asim, tariq ash-Shatibiyyah), and **the accepted
ranges**, for example munfasil 4 or 5 harakat (and whether 2 is accepted), 'arid lil-sukun 2/4/6, and whether the user
must be consistent within one recitation. This is the sheikh's decision, and it changes what the code accepts.

### 2.2 Which rules first

| Rule | How we would detect it | Feasibility | Order |
|---|---|---|---|
| **Madd** (tabi'i 2, muttasil, munfasil, lazim 6, 'arid) | Duration of the vowel, measured in the reciter's own harakah length (from their tempo), not seconds | Highest: duration is robust; positions are known from the text | **1** |
| **Ghunna** on mushaddad nun/mim (2 harakat) | Duration plus nasal segment from the phoneme model | High | **2** |
| **Qalqalah** (q, t, b, j, d with sukun) | Acoustic release/burst after the letter; tajweed-v2 and qdat_bench both cover it | Medium | **3** |
| **Ikhfa, idgham, iqlab, izhar** of nun sakinah/tanween | Phoneme sequence: was the nun pronounced clearly or merged/hidden | Medium; ikhfa is subtle and varies by reciter | 4 |
| Tafkhim/tarqiq, sifat, makharij | Fine acoustics | Hard; research-grade | Later |
| Waqf and ibtida | From text plus pause positions | Text part is easy; judging meaning is the sheikh's area | Later |

### 2.3 How we would detect them

1. **Phoneme-level timing.** Run a CTC phoneme model (tajweed-v2 candidate) or a forced aligner on the known text to
   get the start and end of each phoneme.
   - Forced aligner candidate: [Quran-Lab/mfa-quran-hafs](https://huggingface.co/Quran-Lab/mfa-quran-hafs)
     (Apache-2.0; Montreal Forced Aligner model for Hafs, self-reported 10–20 ms boundary jitter, ships a tajweed rule
     index). Server-side only (MFA is a heavy tool). Useful to cross-check the on-device model.
2. **Rule positions from the text.** Each word's Uthmani text tells us where each rule applies. We precompute a
   `tajweed_positions` table (ayah, word, letter, rule, expected length) and the sheikh reviews a sample of it.
3. **Rule check.** Compare measured length (in the user's harakah units) to the accepted range, with a "not sure"
   band where we say nothing.
4. **Only report confident cases.** A tajweed remark is a suggestion ("قد تكون المدّة أقصر من المطلوب"), with a link
   to listen to a reference reciter on the same word.

### 2.4 Existing data (checked)

| Data | License | Use |
|---|---|---|
| [obadx/qdat](https://huggingface.co/datasets/obadx/qdat) | MIT | 1,505 clips, one verse (Al-Ma'idah 109), 160 reciters, labels for madd, ghunnah, ikhfa. Card notes some mislabels. Evaluation only. |
| [obadx/qdat_bench](https://huggingface.co/datasets/obadx/qdat_bench) | Apache-2.0 | 159 learner clips of one verse with madd lengths, ghunnah, qalqalah, phonetic string. Evaluation only. |
| obadx `quran-muaalem` package and model | Custom "QML 1.0" (Apache-2.0 with extra terms: AI-use notice, no ads/selling data, free path to core features). **Read the LICENSE file before use**; we did not verify the full text. | Possible teacher model on the server |
| IqraEval datasets (ArabicNLP 2025, Interspeech 2026) | Commercial use **not clarified** (open question on the dataset page) | Research only until clarified; also MSA reading, not tajweed |
| Crowdsourced Quranic audio (arXiv 2405.02675) | Not stated | Do not use |

Gap: nothing public covers our users (mixed ages, phone mics, Gulf and Levant accents, children) across many surahs.
So **our own labelled data is required**, and the sheikh is the only person who can label tajweed.

### 2.5 Labelled data we need

- **Gold set v1 (word mistakes):** 300 clips from PR #11's recorder, labelled by the sheikh. Also used for tajweed
  timing checks later.
- **Per tajweed rule:** about 200 occurrences correct + 100 with the mistake, from at least 30 different reciters,
  labelled by the sheikh. For madd that is roughly 80–120 short clips (each clip has several madd positions).
- **Double labelling:** 10% of clips labelled twice (sheikh plus a second qualified teacher, or the sheikh again a
  week later) to measure agreement. If two experts agree less than ~85% on a rule, the model cannot be held to a
  higher bar and the rule is not ready.

## 3. The sheikh's role

### 3.1 What he decides (authority)

1. The standard: riwayah, tariq, accepted madd lengths and variants (section 2.1).
2. The mistake taxonomy and the Arabic wording of every message the app shows about recitation (about 25 strings).
3. Gold labels on clips, and the final word on disputed flags.
4. Sign-off per rule and per model version before it is shown to users (section 4).

### 3.2 Review tool

A small web page (no app install), served from the existing `site/` or a protected route, backed by Supabase:

- Lists clips from `benchmark_clips` (PR #11) and from "This is wrong" reports, oldest first.
- Plays the clip with the Uthmani text shown word by word; tapping a word cycles: correct → wrong → skipped →
  tajweed issue (then pick the rule and "short / long / missing").
- Shows what the app said, so he can mark "app was right / app was wrong".
- Keyboard and phone friendly; about 1 minute per short clip.
- Saves to a new `expert_labels` table (clip, labeller, labels JSON, version, created_at), separate from the
  volunteer's own labels so we can compare.
- Access: a dedicated Supabase account with an `expert` role; RLS so only experts read clips.

Effort: about 1 week to build. **Until it exists, he can start with a spreadsheet and audio files** (section 3.3).

### 3.3 What to ask him to do first (in order)

1. **One meeting (1 hour):** confirm riwayah/tariq and accepted ranges; review the list of mistake types and our
   Arabic messages; agree on how he wants to be credited.
2. **Listen to 20 app results** (we send recordings plus what the app said). He marks which flags are wrong. This
   gives a first, honest read on false flags before any engineering.
3. **Label 50 clips** (spreadsheet or the tool) as a pilot, then the full 300.
4. **Review the madd and ghunna positions** precomputed for Al-Fatiha and Juz 'Amma.
5. Later: label tajweed occurrences per rule (2.5) and sign off each release.

Rough time: steps 1–2 ≈ 2–3 hours; 300 clips ≈ 6–8 hours; per tajweed rule ≈ 3–4 hours.

### 3.4 Credit, agreement and ijazah

- **Credit** only with his written permission, in the form he chooses (name, title, or anonymous). Suggested place: an
  "Scholarly review" page in Settings and on asmi3ni.com, stating exactly what he reviewed and when.
- **Compensation:** agree it up front (paid per hour or per batch, or voluntary). Put it in a one-page written
  agreement that also covers data use (clips stay private, used only to improve the app) and that the app may not
  imply more endorsement than he gave.
- **Ijazah:** the app must never claim to grant ijazah or to replace a teacher. His ijazah and sanad can be mentioned
  as his qualification for reviewing, if he agrees. His approval is **per version**: when the model or thresholds
  change, the gold set is re-run and he re-confirms before the store text keeps saying "reviewed".
- Content beyond recitation (Ask the Quran answers, adhkar texts): out of scope for this plan, but if he is willing,
  a separate review of adhkar sources and the Ask disclaimer is cheap and valuable.

## 4. Milestones

Estimates assume one developer working with Claude, and the sheikh's availability of a few hours a week.

| # | Milestone | Effort | Depends on | Done when |
|---|---|---|---|---|
| M0 | Merge PR #11, deploy ASR, collect 300 clips; sheikh meeting and 20-result review | 1–2 weeks | Volunteers, sheikh | Benchmark report on the real gold set |
| M1 | Fix whatever M0 shows (thresholds via `--sweep`, alignment tweaks); meet the existing launch gates | 1–3 weeks | M0 | Gates pass on gold set |
| M2 | Review tool for the sheikh (`expert_labels`) | 1 week | can start now | He labels in it |
| M3 | Live spike: tajweed-v2 ONNX in Flutter, measure speed on 3 phones, tracking accuracy on gold set; option B as baseline | 2 weeks | M1 | Go/no-go with numbers |
| M4 | Live correction beta: follow mode + amber flags, kill switch, "This is wrong" reports, offline queue | 3–4 weeks | M3 | Internal beta (TestFlight / Play internal) |
| M5 | Tajweed madd: positions table, harakah-relative timing, sheikh labels, threshold tuning | 3–4 weeks | M1, sheikh labels | Rule gate met, sheikh sign-off |
| M6 | Ghunna, then qalqalah | 2–3 weeks each | M5 | Same |
| M7 | Ikhfa / idgham / iqlab | 4+ weeks, uncertain | M6 | Same, or dropped if experts disagree too much |

Live correction in public: realistically **2–3 months** from now. First tajweed rule (madd) in public: **3–4
months**, mostly gated by labelled data, not code.

## 5. Risks

| Risk | Impact | Mitigation |
|---|---|---|
| Base accuracy is worse than expected (M0) | Everything shifts | That is why M0 is first; try whisper-small or tajweed-v2 on the server before live work |
| False flags on correct recitation | Users leave, bad reviews, religious sensitivity | Gates, two-decode rule, follow-only onboarding, kill switch, sheikh-reviewed reports |
| Children, women and non-native speakers under-represented in training data | Unequal accuracy | Benchmark breaks results down by group (already in PR #11); do not launch a feature that fails one group |
| Self-reported model claims don't hold | Spike fails | Every model is scored on our gold set before adoption |
| License terms change or are misunderstood | Legal | Pin model revisions and keep copies of licenses in `docs/licenses/`; avoid NC and custom licenses unless reviewed |
| Sheikh's time is limited | Tajweed stalls | Start with madd only; spreadsheet first; second teacher for double labelling |
| Valid variants marked as mistakes | Wrong teaching | Sheikh defines accepted ranges; "not sure" band where the app says nothing |
| Privacy of kept clips | Trust and store review | Consent screen, delete-all, privacy page update before any public collection |
| GPU cost if we go server-side | Budget | On-device first; GPU only with enough concurrent users |

## 6. What must be true before advertising in the stores

**Live correction**
- Benchmark gates met in **live mode** (not just the final check): ≤ 5% of clean recitations get any live flag,
  ≥ 80% of real mistakes caught, on the sheikh's gold set, and no group (child, woman, non-native) more than 2 points
  worse.
- p90 flag latency ≤ 1.5 s on a mid-range Android phone; works offline.
- Internal beta of at least 2 weeks with false-flag reports under 5%.
- Store wording: "يتابع تلاوتك وينبّهك على الكلمات الخاطئة أو المتروكة" is fine. Avoid "100% accurate", "replaces a
  teacher", "certified".

**Tajweed (per rule)**
- On the sheikh's labels: ≥ 90% of the app's tajweed remarks are correct (precision), ≥ 70% of real mistakes caught,
  and expert agreement on that rule ≥ 85%.
- Written sign-off from the sheikh for that rule and that model version.
- Shown in the app as "تنبيهات تجويد (تجريبي)" until it has been public for a while with low report rates.
- Store text names only the rules that passed ("ينبّهك على المدود والغنّة"), never "full tajweed correction".
- Mention the scholarly review only in the wording he approved.

## 7. Sources checked (2026-11-25)

- tarteel-ai/whisper-base-ar-quran model card (Apache-2.0)
- HisnLabs/tajweed-v2 model card (Apache-2.0; self-reported PER and speed)
- Muno459/zipformer_p-quran (NPL-1.1, non-commercial, gated)
- Quran-Lab/mfa-quran-hafs (Apache-2.0)
- obadx/qdat (MIT), obadx/qdat_bench (Apache-2.0), quran-muaalem on PyPI (QML 1.0, not fully read)
- arXiv 2509.00094 (multi-level CTC, Quran phonetic script; 848 h; PER 1.94% on qdat_bench, tajweed F1 75.8%)
- Iqra'Eval shared task (ArabicNLP 2025) and IqraEval.2 (Interspeech 2026); commercial license unclear
- torchaudio MMS_FA docs (CC-BY-NC 4.0)
- Cloud Run pricing page (instance-based CPU, memory, L4 GPU)

Numbers on model cards are the authors' own claims. None has been run on our clips yet.
