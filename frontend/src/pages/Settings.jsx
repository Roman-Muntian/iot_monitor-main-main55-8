import React, { useState } from "react";
import { Thermometer, Droplets, RotateCcw, Save, Cpu, Activity, Radio } from "lucide-react";
import { useMqtt } from "../components/MqttContext";
import { NeoCard, NeoTag, NeoButton } from "../components/NeoUI";

function RangeRow({ label, unit, icon: Icon, color, textColor = "var(--nb-ink)", min, max, lo, hi, onChange }) {
  return (
    <NeoCard padding={16}>
      <div className="row" style={{ marginBottom: 10 }}>
        <span
          style={{
            width: 36, height: 36, background: color,
            border: "2px solid var(--nb-ink)", display: "flex",
            alignItems: "center", justifyContent: "center",
            borderRadius: 4, boxShadow: "3px 3px 0 0 var(--nb-ink)",
          }}
        >
          <Icon size={18} strokeWidth={2.5} color={textColor} />
        </span>
        <span className="font-display" style={{ fontSize: 14 }}>{label}</span>
        <div className="spacer" />
        <span
          className="font-label"
          style={{
            background: color,
            color: textColor,
            padding: "5px 10px",
            border: "2px solid var(--nb-ink)",
            borderRadius: 4,
            boxShadow: "3px 3px 0 0 var(--nb-ink)",
            fontSize: 11,
          }}
        >
          {Math.round(lo)}–{Math.round(hi)} {unit}
        </span>
      </div>
      <div className="row" style={{ marginBottom: 6 }}>
        <span className="font-label" style={{ fontSize: 10.5, width: 38 }}>MIN</span>
        <input
          type="range"
          className="nb-range"
          min={0}
          max={100}
          step={1}
          value={lo}
          onChange={(e) => {
            const v = Number(e.target.value);
            onChange({ lo: v, hi: Math.max(v, hi) });
          }}
          data-testid={`range-${label.toLowerCase()}-min`}
        />
        <span className="font-mono" style={{ width: 32, textAlign: "right", fontWeight: 800 }}>
          {Math.round(lo)}
        </span>
      </div>
      <div className="row">
        <span className="font-label" style={{ fontSize: 10.5, width: 38 }}>MAX</span>
        <input
          type="range"
          className="nb-range"
          min={0}
          max={100}
          step={1}
          value={hi}
          onChange={(e) => {
            const v = Number(e.target.value);
            onChange({ lo: Math.min(lo, v), hi: v });
          }}
          data-testid={`range-${label.toLowerCase()}-max`}
        />
        <span className="font-mono" style={{ width: 32, textAlign: "right", fontWeight: 800 }}>
          {Math.round(hi)}
        </span>
      </div>
      <div className="muted" style={{ fontSize: 11, marginTop: 8 }}>
        Out-of-range readings will trigger an alarm and be tagged ERROR in logs.
      </div>
    </NeoCard>
  );
}

export default function SettingsPage() {
  const { settings, setSettings, simulator, config, state } = useMqtt();
  const [draft, setDraft] = useState(settings);
  const dirty =
    draft.tempMin !== settings.tempMin ||
    draft.tempMax !== settings.tempMax ||
    draft.humMin !== settings.humMin ||
    draft.humMax !== settings.humMax;

  const reset = () => setDraft({ tempMin: 18, tempMax: 26, humMin: 40, humMax: 60 });
  const save = () => setSettings(draft);

  return (
    <main className="container stagger" data-testid="settings-page">
      <NeoCard color="var(--nb-charcoal)" padding={18}>
        <div className="row" style={{ color: "var(--nb-white)" }}>
          <span
            style={{
              width: 38, height: 38, background: "var(--nb-yellow)",
              border: "2px solid var(--nb-ink)",
              display: "flex", alignItems: "center", justifyContent: "center",
              borderRadius: 4, boxShadow: "3px 3px 0 0 var(--nb-ink)",
            }}
          >
            <Cpu size={20} strokeWidth={2.5} />
          </span>
          <span className="font-display" style={{ fontSize: 15, color: "var(--nb-white)" }}>
            BROKER STATUS
          </span>
          <div className="spacer" />
          <NeoTag
            label={state === "connected" ? "ONLINE" : state.toUpperCase()}
            variant={state === "connected" ? "success" : "yellow"}
            icon={Radio}
          />
        </div>
        <div style={{ marginTop: 10, color: "#c9c9c9", fontSize: 12.5, lineHeight: 1.5 }}>
          {config ? (
            <>
              Connected via{" "}
              <span className="font-mono" style={{ color: "var(--nb-yellow)" }}>
                {(config.use_tls ? "wss" : "ws")}://{config.host}:{config.ws_port}{config.ws_path}
              </span>
              <br />
              Topics:{" "}
              <span className="font-mono" style={{ color: "var(--nb-mint)" }}>{config.topic_temp}</span>
              {" · "}
              <span className="font-mono" style={{ color: "var(--nb-mint)" }}>{config.topic_hum}</span>
            </>
          ) : (
            "Loading config…"
          )}
        </div>
        <div style={{ marginTop: 12, display: "flex", gap: 12, flexWrap: "wrap" }}>
          <span
            className="row"
            style={{
              background: "var(--nb-ink)", color: "var(--nb-yellow)",
              padding: "4px 8px", borderRadius: 3, gap: 6,
              border: "2px solid var(--nb-yellow)",
            }}
          >
            <Activity size={14} strokeWidth={2.5} />
            <span className="font-label" style={{ fontSize: 11, color: "var(--nb-yellow)" }}>
              SIM PUBLISHES: {simulator.publishes}
            </span>
          </span>
          <NeoTag
            label={simulator.running ? "SIM RUNNING" : "SIM IDLE"}
            variant={simulator.running ? "success" : "yellow"}
          />
        </div>
      </NeoCard>

      <div style={{ height: 18 }} />

      <RangeRow
        label="TEMPERATURE"
        unit="°C"
        icon={Thermometer}
        color="var(--nb-yellow)"
        lo={draft.tempMin}
        hi={draft.tempMax}
        min={0}
        max={100}
        onChange={({ lo, hi }) => setDraft({ ...draft, tempMin: lo, tempMax: hi })}
      />

      <div style={{ height: 14 }} />

      <RangeRow
        label="HUMIDITY"
        unit="%"
        icon={Droplets}
        color="var(--nb-blue)"
        textColor="var(--nb-white)"
        lo={draft.humMin}
        hi={draft.humMax}
        min={0}
        max={100}
        onChange={({ lo, hi }) => setDraft({ ...draft, humMin: lo, humMax: hi })}
      />

      <div style={{ height: 18 }} />

      <div className="row" style={{ gap: 12, flexWrap: "wrap" }}>
        <NeoButton variant="white" icon={RotateCcw} onClick={reset} testId="reset-settings-btn">
          Reset
        </NeoButton>
        <NeoButton
          variant={dirty ? "mint" : "yellow"}
          icon={Save}
          onClick={save}
          testId="save-settings-btn"
        >
          {dirty ? "Save Changes" : "Saved"}
        </NeoButton>
      </div>

      <div style={{ height: 22 }} />

      <NeoCard padding={16}>
        <div className="font-display" style={{ fontSize: 14, marginBottom: 8 }}>
          ABOUT
        </div>
        <div style={{ fontSize: 13, lineHeight: 1.55 }}>
          <strong>IoT Monitor — Neo-Brutalist Edition.</strong> A redesign of the original Flutter
          monitor by <span className="font-mono">Roman 41-КІ</span>. The web demo connects to the
          same public MQTT broker as the mobile app, so any ESP32 publishing to{" "}
          <span className="font-mono">roman_41ki/temp</span> and{" "}
          <span className="font-mono">roman_41ki/hum</span> shows up live. The Flutter source files
          are available at <span className="font-mono">/app/lib/</span> and ready to drop into a
          Flutter project.
        </div>
      </NeoCard>
    </main>
  );
}
