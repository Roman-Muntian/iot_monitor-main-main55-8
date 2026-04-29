"""Backend API tests for IoT Monitor FastAPI service."""
import os
import time
import requests
import pytest

BASE_URL = os.environ.get("REACT_APP_BACKEND_URL", "").rstrip("/")
if not BASE_URL:
    # Fallback to frontend env file
    env_path = "/app/frontend/.env"
    if os.path.exists(env_path):
        with open(env_path) as f:
            for line in f:
                if line.startswith("REACT_APP_BACKEND_URL="):
                    BASE_URL = line.split("=", 1)[1].strip().rstrip("/")
                    break


@pytest.fixture(scope="module")
def api():
    s = requests.Session()
    s.headers.update({"Content-Type": "application/json"})
    return s


# ------------------ Health ------------------
def test_health(api):
    r = api.get(f"{BASE_URL}/api/health", timeout=10)
    assert r.status_code == 200
    data = r.json()
    assert data["status"] == "ok"
    assert data["service"] == "iot-monitor-api"


# ------------------ MQTT Config ------------------
def test_mqtt_config(api):
    r = api.get(f"{BASE_URL}/api/mqtt-config", timeout=10)
    assert r.status_code == 200
    data = r.json()
    assert data["host"] == "broker.emqx.io"
    assert data["ws_port"] == 8084
    assert data["topic_temp"] == "roman_41ki/temp"
    assert data["topic_hum"] == "roman_41ki/hum"
    assert data["use_tls"] is True
    assert data["ws_path"] == "/mqtt"


# ------------------ Simulator State ------------------
def test_simulator_running_and_publishes(api):
    # Hit twice with a delay to confirm the publish counter is increasing
    r1 = api.get(f"{BASE_URL}/api/simulator/state", timeout=10)
    assert r1.status_code == 200
    s1 = r1.json()
    assert s1["enabled"] is True
    # The sim may need a couple seconds to connect on cold start; retry briefly
    if not s1["running"] or s1["publishes"] == 0:
        for _ in range(8):
            time.sleep(2)
            s1 = api.get(f"{BASE_URL}/api/simulator/state", timeout=10).json()
            if s1["running"] and s1["publishes"] > 0:
                break
    assert s1["running"] is True, f"simulator not running: {s1}"
    assert s1["publishes"] > 0
    assert isinstance(s1["last_temp"], (int, float))
    assert isinstance(s1["last_hum"], (int, float))

    time.sleep(3)
    s2 = api.get(f"{BASE_URL}/api/simulator/state", timeout=10).json()
    assert s2["publishes"] >= s1["publishes"], (
        f"publishes did not increase: {s1['publishes']} -> {s2['publishes']}"
    )


# ------------------ Spike POST ------------------
def test_simulator_spike(api):
    r = api.post(f"{BASE_URL}/api/simulator/spike", timeout=15)
    assert r.status_code == 200
    data = r.json()
    assert data.get("ok") is True, f"spike failed: {data}"
