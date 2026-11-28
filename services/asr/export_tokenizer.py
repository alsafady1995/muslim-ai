"""Write tokenizer.json and preprocessor_config.json next to the converted CTranslate2 model.

faster-whisper loads tokenizer.json from the model directory. Some fine-tuned Whisper repos
(e.g. tarteel-ai/whisper-base-ar-quran) ship only the slow tokenizer files, so build the fast
one here; if the repo has no tokenizer at all, use the base Whisper one (same vocabulary).

Usage: python export_tokenizer.py <hf_model> <output_dir>
"""

import sys
from pathlib import Path

from transformers import AutoTokenizer, WhisperFeatureExtractor

model, out = sys.argv[1], Path(sys.argv[2])

try:
    tok = AutoTokenizer.from_pretrained(model, use_fast=True)
except Exception as exc:  # noqa: BLE001
    print(f"no tokenizer in {model} ({exc}); using openai/whisper-base")
    tok = AutoTokenizer.from_pretrained("openai/whisper-base", use_fast=True)
tok.backend_tokenizer.save(str(out / "tokenizer.json"))

try:
    fe = WhisperFeatureExtractor.from_pretrained(model)
except Exception:  # noqa: BLE001
    fe = WhisperFeatureExtractor.from_pretrained("openai/whisper-base")
fe.save_pretrained(str(out))
print("wrote", sorted(p.name for p in out.iterdir()))
