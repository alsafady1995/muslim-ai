# CPU image (int8). whisper-base runs ~5-10x real time on 2 vCPU, which is enough for MVP.
# For GPU hosts build with --build-arg BASE=nvidia/cuda:12.3.2-cudnn9-runtime-ubuntu22.04
# and set ASR_DEVICE=cuda ASR_COMPUTE_TYPE=float16.
ARG BASE=python:3.11-slim
FROM ${BASE}

ENV PYTHONDONTWRITEBYTECODE=1 PYTHONUNBUFFERED=1 PORT=8080
RUN apt-get update && apt-get install -y --no-install-recommends ffmpeg python3-pip && rm -rf /var/lib/apt/lists/*
WORKDIR /srv
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Convert the Quran-tuned Whisper model to CTranslate2 at build time.
ARG HF_MODEL=tarteel-ai/whisper-base-ar-quran
RUN pip install --no-cache-dir "transformers[torch]==4.47.1" "ctranslate2==4.5.0" \
 && ct2-transformers-converter --model ${HF_MODEL} --output_dir /models/whisper-quran-ct2 \
      --copy_files tokenizer.json preprocessor_config.json --quantization int8 \
 && pip uninstall -y torch transformers && rm -rf /root/.cache

COPY app ./app
EXPOSE 8080
CMD exec uvicorn app.main:app --host 0.0.0.0 --port ${PORT} --workers 1
