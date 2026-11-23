import os

from fastapi.testclient import TestClient

os.environ["ASR_SERVICE_TOKEN"] = "test-token"
from app.main import app  # noqa: E402

client = TestClient(app)


def test_health():
    assert client.get("/healthz").json() == {"ok": True}


def test_rejects_missing_token():
    r = client.post("/v1/transcribe", json={"audio_url": "https://example.com/a.mp3"})
    assert r.status_code == 401


def test_rejects_bad_url():
    r = client.post("/v1/transcribe", json={"audio_url": "not-a-url"}, headers={"Authorization": "Bearer test-token"})
    assert r.status_code == 422
