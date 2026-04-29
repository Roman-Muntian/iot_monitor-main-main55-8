import React from "react";
import { useNavigate } from "react-router-dom";
import {
  Thermometer,
  Droplets,
  Cpu,
  AlertTriangle,
  Check,
  Clock,
  ChevronRight,
  Zap,
} from "lucide-react";
import { useMqtt } from "../components/MqttContext";
import { NeoCard, NeoTag, NeoButton, AnimatedNumber } from "../components/NeoUI";

function SensorCard({ title, unit, value, accent, icon: Icon, min, max, onClick, testId }) {
  const alarm = value !== null && (value < min || value > max);
  const headerColor = alarm ? "var(--nb-red)" : accent;
  const headerText =
    accent === "var(--nb-blue)" || alarm ? "var(--nb-white)" : "var(--nb-ink)";

  return (
    <div className="sensor-card slide-up" onClick={onClick} data-testid={testId}>
      <div className="sensor-card__header" style={{ background: headerColor, color: headerText }}>
        <Icon size={22} strokeWidth={2.5} color={headerText} />
        <div className="font-display" style={{ flex: 1, fontSize: 14, color: headerText }}>
          {title}
        </div>
        {alarm ? (
          <NeoTag label="ALARM" variant="error" icon={AlertTriangle} />
        ) : (
          <NeoTag label="OK" variant="ink" icon={Check} />
        )}
      </div>
      <div style={{ padding: "20px 18px 16px" }}>
        <div style={{ display: "flex", alignItems: "flex-end", gap: 8 }}>
          <AnimatedNumber
            value={value ?? 0}
            decimals={1}
            fontStyle={{
              fontSize: 78,
              fontWeight: 800,
              lineHeight: 1,
              color: alarm ? "var(--nb-red)" : "var(--nb-ink)",
              letterSpacing: "-0.04em",
            }}
          />
          <span
            className="font-display"
            style={{ fontSize: 22, paddingBottom: 12, color: "var(--nb-ink)" }}
          >
            {unit}
          </span>
          {value === null && (
            <span style={{ paddingBottom: 16 }} className="muted font-label">
              waiting…
            </span>
          )}
        </div>
        <div style={{ marginTop: 12 }} className="row-between">
          <span
            style={{
              padding: "4px 8px",
              background: "var(--nb-grey-200)",
              border: "2px solid var(--nb-ink)",
              borderRadius: 4,
              fontSize: 10,
              fontWeight: 900,
              letterSpacing: "0.12em",
            }}
            className="font-label"
          >
            TARGET {Math.round(min)}–{Math.round(max)}
            {unit}
          </span>
          <span className="row" style={{ color: "var(--nb-grey-500)" }}>
            <span className="font-label" style={{ fontSize: 10 }}>
              TAP FOR ANALYTICS
            </span>
            <ChevronRight size={16} strokeWidth={2.5} />
          </span>
        </div>
      </div>
    </div>
  );
}

function HeroBlock() {
  const { simulator } = useMqtt();
  return (
    <div className="hero slide-up">
      <div className="row-between" style={{ marginBottom: 14 }}>
        <div className="row">
          <div
            style={{
              width: 40,
              height: 40,
              background: "var(--nb-mint)",
              border: "2px solid var(--nb-ink)",
              borderRadius: 6,
              display: "flex",
              alignItems: "center",
              justifyContent: "center",
              boxShadow: "3px 3px 0 0 var(--nb-ink)",
            }}
          >
            <Cpu size={22} strokeWidth={2.5} />
          </div>
          <div className="font-display" style={{ fontSize: 15, color: "var(--nb-white)" }}>
            ROMAN 41-КІ
          </div>
        </div>
        <NeoTag
          label={simulator.running ? "SIM ON" : "REAL-TIME"}
          variant={simulator.running ? "success" : "yellow"}
          icon={Zap}
        />
      </div>
      <div className="font-label" style={{ color: "var(--nb-yellow)", fontSize: 11, marginBottom: 4 }}>
        REAL-TIME TELEMETRY
      </div>
      <div style={{ color: "#c9c9c9", fontSize: 12.5, fontWeight: 500, lineHeight: 1.4 }}>
        Sensor data is streamed over MQTT (broker.emqx.io · WebSocket) and stored locally for analytics & export.
      </div>
    </div>
  );
}

function AlarmOverlay() {
  const { temp, hum, checkAlarm } = useMqtt();
  const tempMsg = checkAlarm(temp, "temp");
  const humMsg = checkAlarm(hum, "hum");
  if (!tempMsg && !humMsg) return null;
  return (
    <div
      style={{
        position: "fixed",
        bottom: 92,
        left: 0,
        right: 0,
        display: "flex",
        flexDirection: "column",
        alignItems: "center",
        gap: 10,
        zIndex: 25,
        padding: "0 18px",
      }}
      data-testid="alarm-overlay"
    >
      {[tempMsg, humMsg].filter(Boolean).map((msg, i) => (
        <div
          key={i}
          className="slide-up"
          style={{
            width: "100%",
            maxWidth: 540,
            background: "var(--nb-red)",
            color: "var(--nb-white)",
            border: "2.5px solid var(--nb-ink)",
            borderRadius: 8,
            boxShadow: "var(--nb-shadow)",
            padding: "12px 14px",
            display: "flex",
            alignItems: "center",
            gap: 10,
          }}
        >
          <AlertTriangle size={22} strokeWidth={2.5} className="pulse" />
          <span style={{ fontWeight: 800, fontSize: 13 }}>{msg}</span>
        </div>
      ))}
    </div>
  );
}

export default function Dashboard() {
  const navigate = useNavigate();
  const { temp, hum, settings, lastUpdate, triggerSpike } = useMqtt();

  return (
    <main className="container stagger">
      <HeroBlock />

      <div style={{ height: 20 }} />

      <SensorCard
        title="TEMPERATURE"
        unit="°C"
        value={temp}
        accent="var(--nb-yellow)"
        icon={Thermometer}
        min={settings.tempMin}
        max={settings.tempMax}
        onClick={() => navigate("/analytics")}
        testId="sensor-card-temp"
      />

      <div style={{ height: 20 }} />

      <SensorCard
        title="HUMIDITY"
        unit="%"
        value={hum}
        accent="var(--nb-blue)"
        icon={Droplets}
        min={settings.humMin}
        max={settings.humMax}
        onClick={() => navigate("/analytics")}
        testId="sensor-card-hum"
      />

      <div style={{ height: 20 }} />

      <div
        className="row"
        style={{
          padding: "10px 14px",
          background: "var(--nb-yellow)",
          border: "2px solid var(--nb-ink)",
          borderRadius: 4,
          boxShadow: "var(--nb-shadow-sm)",
        }}
        data-testid="last-update"
      >
        <Clock size={16} strokeWidth={2.5} />
        <span className="font-label" style={{ fontSize: 11 }}>LAST UPDATE</span>
        <div className="spacer" />
        <span className="font-mono" style={{ fontSize: 15, fontWeight: 800 }}>
          {lastUpdate}
        </span>
      </div>

      <div style={{ height: 14 }} />

      <NeoCard color="var(--nb-white)">
        <div className="row-between" style={{ marginBottom: 10 }}>
          <div className="font-display" style={{ fontSize: 13 }}>QUICK ACTIONS</div>
          <NeoTag label="DEMO" variant="ink" />
        </div>
        <div className="row" style={{ flexWrap: "wrap", gap: 10 }}>
          <NeoButton variant="red" icon={AlertTriangle} onClick={triggerSpike} testId="trigger-spike-btn">
            Trigger Alarm
          </NeoButton>
          <NeoButton variant="blue" icon={Droplets} onClick={() => navigate("/analytics")} testId="view-analytics-btn">
            View Analytics
          </NeoButton>
          <NeoButton variant="yellow" icon={ChevronRight} onClick={() => navigate("/logs")} testId="view-logs-btn">
            Open Logs
          </NeoButton>
        </div>
      </NeoCard>

      <AlarmOverlay />
    </main>
  );
}
