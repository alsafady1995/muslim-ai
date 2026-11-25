# ASR service

Stateless HTTP service that turns a recitation recording into words with timestamps.
Called only by the `recitation-analyze` edge function (bearer token `ASR_SERVICE_TOKEN`).

## Deploy (Modal, scales to zero)

Modal bills per second, scales to zero when nobody is reciting, includes **$30 of free compute a
month** on the Starter plan, and signs up with a card directly. (Google Cloud with a Saudi billing
address must be contracted through the reseller CNTXT, which needs a business contract.)
`modal_app.py` runs the same Dockerfile and the same FastAPI app, so nothing else changes.

```bash
pip install modal
modal setup                                     # once: sign this computer in to Modal
modal secret create asmi3ni-asr ASR_SERVICE_TOKEN=<random-64-chars>
modal deploy services/asr/modal_app.py           # prints https://<workspace>--asmi3ni-asr-web.<region>.modal.run
supabase secrets set ASR_SERVICE_URL=<that url> ASR_SERVICE_TOKEN=<same token>
```

Or from GitHub: add repository secrets `MODAL_TOKEN_ID` and `MODAL_TOKEN_SECRET` (modal.com →
Settings → API tokens) and `ASR_SERVICE_TOKEN` (the workflow stores it in the Modal secret) and run the **Deploy ASR** workflow; it also redeploys when `services/asr/` changes on `main`.

Settings in `modal_app.py`: 1 physical core, 2 GiB, 2 requests per container, at most 10 containers,
warm for 60 s after the last request. Cost: about $0.0000175 per container-second (Modal list price,
Nov 2026), so a one-minute recitation costs well under $0.001; the $30 monthly credit covers
the early months. Set a spend limit in Modal (Settings → Usage and billing) when you add the card.

### Other hosts
The Dockerfile runs anywhere that runs containers (`docker run -p 8080:8080 -e ASR_SERVICE_TOKEN=... asr`).
Google Cloud Run, if you later have an account:

```bash
gcloud run deploy muslim-ai-asr --source services/asr --region me-central1 \
  --cpu 2 --memory 2Gi --concurrency 2 --timeout 180 --min-instances 0 --max-instances 10 \
  --set-env-vars ASR_SERVICE_TOKEN=<random-64-chars> --allow-unauthenticated
```

`--allow-unauthenticated` is fine because the app itself checks the bearer token.

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
