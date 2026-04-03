from fastapi.testclient import TestClient

from backend.main import app


client = TestClient(app)


def _auth_headers(token: str = "test-user-1"):
    return {"Authorization": f"Bearer {token}"}


def test_sync_push_lww_rejects_stale_updates():
    first = {
        "items": [
            {
                "id": 1,
                "entity_type": "fields",
                "entity_id": "f-1",
                "operation": "upsert",
                "payload": {"name": "Tarla A"},
                "updated_at": "2026-04-03T10:00:00+00:00",
                "attempt_count": 0,
            }
        ],
        "client_time": "2026-04-03T10:00:01+00:00",
    }
    stale = {
        "items": [
            {
                "id": 2,
                "entity_type": "fields",
                "entity_id": "f-1",
                "operation": "upsert",
                "payload": {"name": "Tarla Eski"},
                "updated_at": "2026-04-03T09:59:59+00:00",
                "attempt_count": 0,
            }
        ],
        "client_time": "2026-04-03T10:00:02+00:00",
    }

    first_res = client.post("/api/sync/push", json=first, headers=_auth_headers())
    stale_res = client.post("/api/sync/push", json=stale, headers=_auth_headers())

    assert first_res.status_code == 200
    assert stale_res.status_code == 200
    assert first_res.json()["completed_ids"] == [1]
    assert stale_res.json()["failed_by_id"]["2"] == "stale_update"


def test_sync_pull_since_filters_results():
    payload = {
        "items": [
            {
                "id": 3,
                "entity_type": "calendar_events",
                "entity_id": "ev-1",
                "operation": "upsert",
                "payload": {"title": "Sulama"},
                "updated_at": "2026-04-03T12:00:00+00:00",
                "attempt_count": 0,
            }
        ],
        "client_time": "2026-04-03T12:00:01+00:00",
    }
    client.post("/api/sync/push", json=payload, headers=_auth_headers("user-pull"))

    pull_old = client.get(
        "/api/sync/pull?since=2026-04-03T11:00:00+00:00",
        headers=_auth_headers("user-pull"),
    )
    pull_new = client.get(
        "/api/sync/pull?since=2026-04-03T12:30:00+00:00",
        headers=_auth_headers("user-pull"),
    )

    assert pull_old.status_code == 200
    assert len(pull_old.json()["items"]) == 1
    assert pull_new.status_code == 200
    assert len(pull_new.json()["items"]) == 0
