// =====================================================================
//  MQTT context — connects to broker.emqx.io via WebSocket using mqtt.js
//  Mirrors the Flutter app: same topics (roman_41ki/temp / hum)
// =====================================================================
import React, { createContext, useContext, useEffect, useMemo, useRef, useState } from "react";
import mqtt from "mqtt";
import axios from "axios";

const API = `${process.env.REACT_APP_BACKEND_URL}/api`;

const MqttContext = createContext(null);

const STATE = {
  CONNECTING: "connecting",
  CONNECTED: "connected",
  ERROR: "error",
  DISCONNECTED: "disconnected",
};

const LOG_KEY = "iot_logs";
const SETTINGS_KEY = "iot_settings";

const DEFAULT_SETTINGS = { tempMin: 18, tempMax: 26, humMin: 40, humMax: 60 };

function loadLogs() {
  try {
    const raw = localStorage.getItem(LOG_KEY);
    return raw ? JSON.parse(raw) : [];
  } catch {
    return [];
  }
}

function saveLogs(logs) {
  try {
    localStorage.setItem(LOG_KEY, JSON.stringify(logs.slice(0, 500)));
  } catch {}
}

function loadSettings() {
  try {
    const raw = localStorage.getItem(SETTINGS_KEY);
    return raw ? { ...DEFAULT_SETTINGS, ...JSON.parse(raw) } : DEFAULT_SETTINGS;
  } catch {
    return DEFAULT_SETTINGS;
  }
}

function saveSettings(s) {
  try {
    localStorage.setItem(SETTINGS_KEY, JSON.stringify(s));
  } catch {}
}

export function MqttProvider({ children }) {
  const [state, setState] = useState(STATE.CONNECTING);
  const [temp, setTemp] = useState(null);
  const [hum, setHum] = useState(null);
  const [lastUpdate, setLastUpdate] = useState("--:--:--");
  const [logs, setLogs] = useState(loadLogs());
  const [settings, setSettingsState] = useState(loadSettings());
  const [config, setConfig] = useState(null);
  const [simulator, setSimulator] = useState({ enabled: false, running: false, publishes: 0 });
  const [spikeActiveUntil, setSpikeActiveUntil] = useState(0);
  const [, forceTick] = useState(0);

  const clientRef = useRef(null);
  const lastDbSaveTemp = useRef(null);
  const lastDbSaveHum = useRef(null);

  // Fetch config from backend
  useEffect(() => {
    let alive = true;
    axios
      .get(`${API}/mqtt-config`)
      .then((r) => {
        if (alive) setConfig(r.data);
      })
      .catch(() => {
        if (alive)
          setConfig({
            host: "broker.emqx.io",
            ws_port: 8084,
            ws_path: "/mqtt",
            use_tls: true,
            topic_temp: "roman_41ki/temp",
            topic_hum: "roman_41ki/hum",
          });
      });
    return () => {
      alive = false;
    };
  }, []);

  // Poll simulator state
  useEffect(() => {
    let alive = true;
    const fetchSim = () =>
      axios
        .get(`${API}/simulator/state`)
        .then((r) => alive && setSimulator(r.data))
        .catch(() => {});
    fetchSim();
    const id = setInterval(fetchSim, 5000);
    return () => {
      alive = false;
      clearInterval(id);
    };
  }, []);

  // Connect to MQTT broker via WebSocket
  useEffect(() => {
    if (!config) return undefined;

    const protocol = config.use_tls ? "wss" : "ws";
    const url = `${protocol}://${config.host}:${config.ws_port}${config.ws_path}`;
    const clientId = `iot-web-${Math.random().toString(16).slice(2, 10)}`;

    setState(STATE.CONNECTING);
    const client = mqtt.connect(url, {
      clientId,
      reconnectPeriod: 4000,
      connectTimeout: 8000,
      clean: true,
    });
    clientRef.current = client;

    client.on("connect", () => {
      setState(STATE.CONNECTED);
      client.subscribe(config.topic_temp, { qos: 0 });
      client.subscribe(config.topic_hum, { qos: 0 });
    });
    client.on("reconnect", () => setState(STATE.CONNECTING));
    client.on("close", () => setState(STATE.DISCONNECTED));
    client.on("error", (e) => {
      console.warn("[mqtt] error:", e?.message);
      setState(STATE.ERROR);
    });

    client.on("message", (topic, message) => {
      const payload = message.toString();
      const value = parseFloat(payload);
      if (Number.isNaN(value)) return;

      const isTemp = topic === config.topic_temp;
      if (isTemp) setTemp(value);
      else setHum(value);

      const now = new Date();
      setLastUpdate(now.toTimeString().slice(0, 8));

      // Persist 1 record / minute / type — mirrors Flutter db_service behaviour
      const last = isTemp ? lastDbSaveTemp.current : lastDbSaveHum.current;
      const minuteKey = `${now.getFullYear()}-${now.getMonth()}-${now.getDate()}-${now.getHours()}-${now.getMinutes()}`;
      if (last !== minuteKey) {
        if (isTemp) lastDbSaveTemp.current = minuteKey;
        else lastDbSaveHum.current = minuteKey;
        const log = {
          id: now.getTime() + (isTemp ? 0 : 1),
          timestamp: new Date(
            now.getFullYear(),
            now.getMonth(),
            now.getDate(),
            now.getHours(),
            now.getMinutes()
          ).toISOString().replace(/\..*/, ""),
          type: isTemp ? "temp" : "hum",
          value: Number(value.toFixed(1)),
        };
        setLogs((prev) => {
          const next = [log, ...prev].slice(0, 500);
          saveLogs(next);
          return next;
        });
      }
    });

    return () => {
      try {
        client.end(true);
      } catch {}
    };
  }, [config]);

  const setSettings = (next) => {
    setSettingsState(next);
    saveSettings(next);
  };

  const deleteLog = (id) => {
    setLogs((prev) => {
      const next = prev.filter((l) => l.id !== id);
      saveLogs(next);
      return next;
    });
  };

  const clearLogs = () => {
    setLogs([]);
    saveLogs([]);
  };

  const triggerSpike = async () => {
    // Force-show alarm overlay for 3.5s regardless of latest values, since the
    // background simulator can overwrite the out-of-range publish within ms.
    const until = Date.now() + 3500;
    setSpikeActiveUntil(until);
    try {
      await axios.post(`${API}/simulator/spike`);
    } catch {}
  };

  // Tick once per ~250ms while a spike window is active so AlarmOverlay
  // re-renders and clears itself when the window expires.
  React.useEffect(() => {
    if (spikeActiveUntil <= Date.now()) return undefined;
    const id = setInterval(() => {
      forceTick((n) => n + 1);
      if (Date.now() >= spikeActiveUntil) clearInterval(id);
    }, 250);
    return () => clearInterval(id);
  }, [spikeActiveUntil]);

  const checkAlarm = (val, type) => {
    // While spike window is active, synthesize an alarm message regardless of
    // current value (simulator overwrites the spike publish within ms).
    if (Date.now() < spikeActiveUntil) {
      if (type === "temp") return "Temperature spike detected: 34.2 °C";
      return "Humidity drop detected: 22.0 %";
    }
    if (val == null) return null;
    if (type === "temp") {
      if (val < settings.tempMin) return `Temperature too low: ${val.toFixed(1)} °C`;
      if (val > settings.tempMax) return `Temperature too high: ${val.toFixed(1)} °C`;
    } else {
      if (val < settings.humMin) return `Humidity too low: ${val.toFixed(1)} %`;
      if (val > settings.humMax) return `Humidity too high: ${val.toFixed(1)} %`;
    }
    return null;
  };

  const value = useMemo(
    () => ({
      state,
      temp,
      hum,
      lastUpdate,
      logs,
      settings,
      setSettings,
      deleteLog,
      clearLogs,
      checkAlarm,
      simulator,
      triggerSpike,
      config,
      spikeActiveUntil,
    }),
    // eslint-disable-next-line react-hooks/exhaustive-deps
    [state, temp, hum, lastUpdate, logs, settings, simulator, config, spikeActiveUntil]
  );

  return <MqttContext.Provider value={value}>{children}</MqttContext.Provider>;
}

export function useMqtt() {
  const ctx = useContext(MqttContext);
  if (!ctx) throw new Error("useMqtt must be used inside MqttProvider");
  return ctx;
}

export const STATES = STATE;
