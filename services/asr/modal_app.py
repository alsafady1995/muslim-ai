"""Deploy the ASR service on Modal (https://modal.com).

Why Modal: it bills per second, scales to zero when nobody is reciting, includes $30 of free
compute every month on the Starter plan (enough for tens of thousands of recitation checks),
and signs up with a card directly. Google Cloud in Saudi Arabia must be contracted through a
reseller, which a solo developer cannot do with a card alone.

It runs the exact same container as before (Dockerfile) and the same FastAPI app, so the API,
the bearer-token check and the edge function do not change.

Deploy (from the repo root):
    pip install modal
    modal setup                                   # once: signs this computer in to Modal
    modal secret create asmi3ni-asr ASR_SERVICE_TOKEN=<random-64-chars>
    modal deploy services/asr/modal_app.py

The deploy prints a URL like https://<workspace>--asmi3ni-asr-web.<region>.modal.run. Then:
    supabase secrets set ASR_SERVICE_URL=<that url> ASR_SERVICE_TOKEN=<same token>
"""

from pathlib import Path

import modal

HERE = Path(__file__).parent

# Same image as the Dockerfile: ffmpeg, faster-whisper, and the Quran-tuned Whisper model
# converted to CTranslate2 at build time (so containers start without downloading it).
image = modal.Image.from_dockerfile(HERE / "Dockerfile", context_dir=HERE)

app = modal.App("asmi3ni-asr", image=image)


@app.function(
    cpu=1.0,  # one physical core (2 vCPU), like the 2 vCPU Cloud Run setup
    memory=2048,
    timeout=180,  # the edge function cuts audio at 180 s
    scaledown_window=60,  # stay warm 60 s after the last request, then scale to zero
    max_containers=10,  # hard ceiling on parallel containers, and so on cost
    secrets=[modal.Secret.from_name("asmi3ni-asr")],  # provides ASR_SERVICE_TOKEN
)
@modal.concurrent(max_inputs=2)  # same as Cloud Run --concurrency 2
@modal.asgi_app()
def web():
    import sys

    sys.path.insert(0, "/srv")  # the Dockerfile's WORKDIR, where app/ lives
    from app.main import app as fastapi_app

    return fastapi_app
