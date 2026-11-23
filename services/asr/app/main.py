"""Quran recitation ASR service.

POST /v1/transcribe {"audio_url": "...", "language": "ar"}
-> {"text": str, "duration": float, "words": [{"word", "start", "end", "probability"}]}

Uses a Whisper model fine-tuned on Quran recitation (default: tarteel-ai/whisper-base-ar-quran,
converted to CTranslate2 at image build time) with word-level timestamps.
The expected text is deliberately NOT passed as a prompt: biasing the decoder toward
the correct text would hide the reciter's mistakes.
"""

from __future__ import annotations

import hmac
import os
import tempfile
from functools import lru_cache

import httpx
from fastapi import Depends, FastAPI, Header, HTTPException
from pydantic import BaseModel, HttpUrl

MODEL_DIR = os.environ.get("ASR_MODEL_DIR", "/models/whisper-quran-ct2")
DEVICE = os.environ.get("ASR_DEVICE", "cpu")  # "cuda" on GPU hosts
COMPUTE_TYPE = os.environ.get("ASR_COMPUTE_TYPE", "int8")  # "float16" on GPU
MAX_AUDIO_BYTES = int(os.environ.get("ASR_MAX_AUDIO_BYTES", str(10 * 1024 * 1024)))
MAX_DURATION_SEC = float(os.environ.get("ASR_MAX_DURATION_SEC", "300"))

app = FastAPI(title="Muslim AI ASR", version="1.0.0")


def require_token(authorization: str = Header(default="")) -> None:
    expected = os.environ.get("ASR_SERVICE_TOKEN", "")
    if not expected:
        raise HTTPException(500, "ASR_SERVICE_TOKEN not configured")
    if not hmac.compare_digest(authorization, f"Bearer {expected}"):
        raise HTTPException(401, "unauthorized")


@lru_cache(maxsize=1)
def model():
    from faster_whisper import WhisperModel

    return WhisperModel(MODEL_DIR, device=DEVICE, compute_type=COMPUTE_TYPE)


class TranscribeRequest(BaseModel):
    audio_url: HttpUrl
    language: str = "ar"


class Word(BaseModel):
    word: str
    start: float
    end: float
    probability: float


class TranscribeResponse(BaseModel):
    text: str
    duration: float
    words: list[Word]


@app.get("/healthz")
def healthz() -> dict:
    return {"ok": True}


@app.post("/v1/transcribe", response_model=TranscribeResponse, dependencies=[Depends(require_token)])
def transcribe(req: TranscribeRequest) -> TranscribeResponse:
    with httpx.Client(timeout=30, follow_redirects=True) as client:
        r = client.get(str(req.audio_url))
    if r.status_code != 200:
        raise HTTPException(400, f"could not fetch audio ({r.status_code})")
    if len(r.content) > MAX_AUDIO_BYTES:
        raise HTTPException(413, "audio too large")

    with tempfile.NamedTemporaryFile(suffix=".audio") as f:
        f.write(r.content)
        f.flush()
        segments, info = model().transcribe(
            f.name,
            language=req.language,
            task="transcribe",
            beam_size=5,
            word_timestamps=True,
            vad_filter=True,
            condition_on_previous_text=False,
            initial_prompt=None,
        )
        if info.duration > MAX_DURATION_SEC:
            raise HTTPException(413, "recording too long")
        words: list[Word] = []
        texts: list[str] = []
        for seg in segments:
            texts.append(seg.text.strip())
            for w in seg.words or []:
                token = w.word.strip()
                if token:
                    words.append(Word(word=token, start=round(w.start, 3), end=round(w.end, 3),
                                      probability=round(w.probability, 3)))
    return TranscribeResponse(text=" ".join(texts), duration=round(info.duration, 3), words=words)
