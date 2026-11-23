# ASR service

Stateless HTTP service that turns a recitation recording into words with timestamps.
Called only by the `recitation-analyze` edge function (bearer token `ASR_SERVICE_TOKEN`).

## Deploy (Google Cloud Run, scales to zero)

```bash
gcloud run deploy muslim-ai-asr --source services/asr --region me-central1 \
  --cpu 2 --memory 2Gi --concurrency 2 --timeout 180 --min-instances 0 --max-instances 10 \
  --set-env-vars ASR_SERVICE_TOKEN=<random-64-chars> --allow-unauthenticated
```

`--allow-unauthenticated` is fine because the app itself checks the bearer token. Put the
service URL in Supabase secrets as `ASR_SERVICE_URL`.

## Model choice

`tarteel-ai/whisper-base-ar-quran` (Apache-2.0 per its model card; confirm before launch) is small
enough for CPU. If accuracy on real users is not good enough, try a larger Quran-tuned checkpoint
and a GPU host; the API stays the same.

## Local test

```bash
docker build -t asr services/asr && docker run -p 8080:8080 -e ASR_SERVICE_TOKEN=dev asr
curl -s localhost:8080/v1/transcribe -H 'Authorization: Bearer dev' \
  -H 'content-type: application/json' -d '{"audio_url":"https://everyayah.com/data/Alafasy_128kbps/001001.mp3"}'
```
