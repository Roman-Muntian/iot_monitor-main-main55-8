"""
IoT Monitor — FastAPI backend
- Exposes MQTT broker config so the React frontend can connect via WebSocket
- Optionally runs a background simulator that publishes realistic
  temperature & humidity values to the public broker.emqx.io broker
  using the same topics as the Flutter app:  roman_41ki/temp / roman_41ki/hum
"""

import asyncio
import math
import os
import random
import threading
import time
from contextlib import asynccontextmanager

import paho.mqtt.client as mqtt
from dotenv import load_dotenv
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel

load_dotenv()

# ---------------------------------------------------------------------
# Config
# ---------------------------------------------------------------------
MQTT_BROKER_HOST = os.environ.get("MQTT_BROKER_HOST", "broker.emqx.io")
MQTT_BROKER_WS_PORT = int(os.environ.get("MQTT_BROKER_WS_PORT", "8084"))
MQTT_TOPIC_TEMP = os.environ.get("MQTT_TOPIC_TEMP", "roman_41ki/temp")
MQTT_TOPIC_HUM = os.environ.get("MQTT_TOPIC_HUM", "roman_41ki/hum")
MQTT_SIMULATOR_ENABLED = os.environ.get("MQTT_SIMULATOR_ENABLED", "true").lower() == "true"

# ---------------------------------------------------------------------
# Simulator state
# ---------------------------------------------------------------------
_sim_thread: threading.Thread | None = None
_sim_stop = threading.Event()
_sim_state = {
    "running": False,
    "last_temp": None,
    "last_hum": None,
    "last_publish_at": None,
    "publishes": 0,
    "errors": 0,
}


def _run_simulator():
    """Publishes pseudo-realistic sensor values every ~2s using sine drift + noise."""
    client = mqtt.Client(
        client_id=f"iot-sim-{int(time.time())}",
        callback_api_version=mqtt.CallbackAPIVersion.VERSION2,
        transport="tcp",
    )

    backoff = 2
    while not _sim_stop.is_set():
        try:
            # Standard MQTT (TCP) on 1883 — broker.emqx.io supports it openly
            client.connect(MQTT_BROKER_HOST, 1883, keepalive=30)
            client.loop_start()
            _sim_state["running"] = True
            backoff = 2
            t0 = time.time()
            while not _sim_stop.is_set():
                t = time.time() - t0
                # Temperature: oscillates 21–25 °C with noise + occasional spike
                temp = 23.0 + 1.5 * math.sin(t / 30.0) + random.uniform(-0.4, 0.4)
                if random.random() < 0.03:
                    temp += random.choice([-3.5, 3.5])  # spike to trigger alarm

                # Humidity: oscillates 45–62 % with noise + occasional dip
                hum = 53.0 + 6.0 * math.sin(t / 45.0 + 1.2) + random.uniform(-1.0, 1.0)
                if random.random() < 0.03:
                    hum += random.choice([-12.0, 12.0])

                client.publish(MQTT_TOPIC_TEMP, payload=f"{temp:.1f}", qos=0, retain=False)
                client.publish(MQTT_TOPIC_HUM, payload=f"{hum:.1f}", qos=0, retain=False)
                _sim_state["last_temp"] = round(temp, 1)
                _sim_state["last_hum"] = round(hum, 1)
                _sim_state["last_publish_at"] = time.time()
                _sim_state["publishes"] += 1
                time.sleep(2)
        except Exception as e:  # pragma: no cover
            _sim_state["errors"] += 1
            _sim_state["running"] = False
            print(f"[mqtt-sim] error: {e}; retrying in {backoff}s")
            try:
                client.loop_stop()
                client.disconnect()
            except Exception:
                pass
            if _sim_stop.wait(backoff):
                break
            backoff = min(backoff * 2, 30)

    try:
        client.loop_stop()
        client.disconnect()
    except Exception:
        pass
    _sim_state["running"] = False


# ---------------------------------------------------------------------
# Lifespan: start/stop simulator
# ---------------------------------------------------------------------
@asynccontextmanager
async def lifespan(app: FastAPI):
    global _sim_thread
    if MQTT_SIMULATOR_ENABLED:
        _sim_stop.clear()
        _sim_thread = threading.Thread(target=_run_simulator, daemon=True)
        _sim_thread.start()
        print("[mqtt-sim] started")
    yield
    _sim_stop.set()
    if _sim_thread and _sim_thread.is_alive():
        _sim_thread.join(timeout=3)
    print("[mqtt-sim] stopped")


# ---------------------------------------------------------------------
# App
# ---------------------------------------------------------------------
app = FastAPI(title="IoT Monitor — Neo-Brutalist API", lifespan=lifespan)
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)


# ---------------------------------------------------------------------
# Models
# ---------------------------------------------------------------------
class MqttConfig(BaseModel):
    host: str
    ws_port: int
    ws_path: str = "/mqtt"
    use_tls: bool = True
    topic_temp: str
    topic_hum: str
    client_prefix: str = "iot-web"


class SimulatorState(BaseModel):
    enabled: bool
    running: bool
    last_temp: float | None
    last_hum: float | None
    publishes: int
    errors: int


# ---------------------------------------------------------------------
# Routes (all under /api)
# ---------------------------------------------------------------------
@app.get("/api/health")
async def health():
    return {"status": "ok", "service": "iot-monitor-api"}


@app.get("/api/mqtt-config", response_model=MqttConfig)
async def mqtt_config():
    return MqttConfig(
        host=MQTT_BROKER_HOST,
        ws_port=MQTT_BROKER_WS_PORT,
        ws_path="/mqtt",
        use_tls=True,
        topic_temp=MQTT_TOPIC_TEMP,
        topic_hum=MQTT_TOPIC_HUM,
    )


@app.get("/api/simulator/state", response_model=SimulatorState)
async def simulator_state():
    return SimulatorState(
        enabled=MQTT_SIMULATOR_ENABLED,
        running=_sim_state["running"],
        last_temp=_sim_state["last_temp"],
        last_hum=_sim_state["last_hum"],
        publishes=_sim_state["publishes"],
        errors=_sim_state["errors"],
    )


@app.post("/api/simulator/spike")
async def simulator_spike():
    """Force the next published values to be out-of-range so the alarm overlay shows."""
    # Tiny side-channel: directly publish one out-of-range value through a fresh client.
    try:
        client = mqtt.Client(
            client_id=f"iot-spike-{int(time.time())}",
            callback_api_version=mqtt.CallbackAPIVersion.VERSION2,
            transport="tcp",
        )
        client.connect(MQTT_BROKER_HOST, 1883, keepalive=10)
        client.loop_start()
        await asyncio.sleep(0.3)
        client.publish(MQTT_TOPIC_TEMP, payload="34.2", qos=0)
        client.publish(MQTT_TOPIC_HUM, payload="22.0", qos=0)
        await asyncio.sleep(0.3)
        client.loop_stop()
        client.disconnect()
        return {"ok": True}
    except Exception as e:
        return {"ok": False, "error": str(e)}
