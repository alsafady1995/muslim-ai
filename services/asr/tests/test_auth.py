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


def test_rejects_both_or_no_audio_source():
    auth = {"Authorization": "Bearer test-token"}
    assert client.post("/v1/transcribe", json={"language": "ar"}, headers=auth).status_code == 422
    both = {"audio_url": "https://example.com/a.mp3", "audio_base64": "AAAA"}
    assert client.post("/v1/transcribe", json=both, headers=auth).status_code == 422


def test_rejects_invalid_base64():
    r = client.post("/v1/transcribe", json={"audio_base64": "@@not base64@@"},
                    headers={"Authorization": "Bearer test-token"})
    assert r.status_code == 400


def test_rejects_oversized_base64(monkeypatch):
    import app.main as m

    monkeypatch.setattr(m, "MAX_AUDIO_BYTES", 3)
    r = client.post("/v1/transcribe", json={"audio_base64": "AAAAAAAAAAAA"},
                    headers={"Authorization": "Bearer test-token"})
    assert r.status_code == 413
