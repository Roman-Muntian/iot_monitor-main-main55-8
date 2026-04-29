import React, { useMemo } from "react";
import {
  ResponsiveContainer,
  LineChart,
  Line,
  XAxis,
  YAxis,
  CartesianGrid,
  Tooltip,
  ReferenceArea,
} from "recharts";
import { Thermometer, Droplets, Activity, Info, BarChart2 } from "lucide-react";
import { useMqtt } from "../components/MqttContext";
import { NeoCard, NeoTag } from "../components/NeoUI";

function Kpi({ label, value, color, icon: Icon, textColor = "var(--nb-ink)" }) {
  return (
    <div
      className="nb-block"
      style={{
        background: color,
        padding: "12px 14px 14px",
        flex: 1,
        minWidth: 0,
      }}
    >
      <div className="row" style={{ color: textColor, marginBottom: 6 }}>
        <Icon size={16} strokeWidth={2.5} />
        <span className="font-label" style={{ fontSize: 10.5, color: textColor }}>
          {label}
        </span>
      </div>
      <div
        className="font-mono"
        style={{
          fontSize: 26,
          fontWeight: 900,
          color: textColor,
          letterSpacing: "-0.02em",
          whiteSpace: "nowrap",
          overflow: "hidden",
          textOverflow: "ellipsis",
        }}
      >
        {value}
      </div>
    </div>
  );
}

function CustomTooltip({ active, payload, label }) {
  if (!active || !payload?.length) return null;
  return (
    <div
      style={{
        background: "var(--nb-white)",
        border: "2px solid var(--nb-ink)",
        padding: "8px 10px",
        boxShadow: "3px 3px 0 0 var(--nb-ink)",
        borderRadius: 0,
      }}
      className="font-mono"
    >
      <div className="font-label" style={{ fontSize: 10, marginBottom: 4 }}>
        {label}
      </div>
      {payload.map((p) => (
        <div key={p.dataKey} style={{ color: p.color, fontWeight: 800, fontSize: 13 }}>
          {p.dataKey === "temp" ? "TEMP" : "HUM"}: {p.value?.toFixed(1)}
          {p.dataKey === "temp" ? "°C" : "%"}
        </div>
      ))}
    </div>
  );
}

export default function Analytics() {
  const { logs, temp, hum } = useMqtt();

  const { data, stats } = useMemo(() => {
    // Take last 20 samples per type, ordered ascending (chronological)
    const tempLogs = logs
      .filter((l) => l.type === "temp")
      .slice(0, 20)
      .reverse();
    const humLogs = logs
      .filter((l) => l.type === "hum")
      .slice(0, 20)
      .reverse();

    const length = Math.max(tempLogs.length, humLogs.length);
    const merged = [];
    for (let i = 0; i < length; i++) {
      const t = tempLogs[i];
      const h = humLogs[i];
      const ts = (t || h)?.timestamp;
      const time = ts ? ts.slice(11, 16) : `T-${length - i}`;
      merged.push({
        index: i,
        time,
        temp: t ? t.value : null,
        hum: h ? h.value : null,
      });
    }

    // KPIs
    const tempVals = tempLogs.map((l) => l.value);
    const humVals = humLogs.map((l) => l.value);
    const avg = (a) => (a.length ? a.reduce((x, y) => x + y, 0) / a.length : 0);

    return {
      data: merged,
      stats: {
        tempNow: temp ?? (tempVals.length ? tempVals[tempVals.length - 1] : null),
        humNow: hum ?? (humVals.length ? humVals[humVals.length - 1] : null),
        tempAvg: avg(tempVals),
        humAvg: avg(humVals),
        tempMin: tempVals.length ? Math.min(...tempVals) : 0,
        tempMax: tempVals.length ? Math.max(...tempVals) : 0,
        humMin: humVals.length ? Math.min(...humVals) : 0,
        humMax: humVals.length ? Math.max(...humVals) : 0,
        count: logs.length,
      },
    };
  }, [logs, temp, hum]);

  const empty = data.length === 0;

  return (
    <main className="container stagger">
      {/* KPIs */}
      <div style={{ display: "flex", gap: 12 }}>
        <Kpi
          label="TEMP NOW"
          value={stats.tempNow != null ? `${stats.tempNow.toFixed(1)}°C` : "--"}
          color="var(--nb-yellow)"
          icon={Thermometer}
        />
        <Kpi
          label="HUM NOW"
          value={stats.humNow != null ? `${stats.humNow.toFixed(1)}%` : "--"}
          color="var(--nb-blue)"
          textColor="var(--nb-white)"
          icon={Droplets}
        />
      </div>
      <div style={{ height: 12 }} />
      <div style={{ display: "flex", gap: 12 }}>
        <Kpi
          label="TEMP AVG"
          value={stats.count ? `${stats.tempAvg.toFixed(1)}°C` : "--"}
          color="var(--nb-white)"
          icon={Activity}
        />
        <Kpi
          label="HUM AVG"
          value={stats.count ? `${stats.humAvg.toFixed(1)}%` : "--"}
          color="var(--nb-mint)"
          icon={Activity}
        />
      </div>

      <div style={{ height: 22 }} />

      {/* Chart */}
      <NeoCard padding={0}>
        <div
          className="row-between"
          style={{ padding: "16px 18px 8px", borderBottom: "0" }}
        >
          <div className="font-display" style={{ fontSize: 14 }}>TIMELINE</div>
          <div className="row" style={{ gap: 12 }}>
            <span className="row" style={{ gap: 6 }}>
              <span
                style={{
                  width: 14, height: 14, background: "var(--nb-yellow)",
                  border: "2px solid var(--nb-ink)",
                }}
              />
              <span className="font-label" style={{ fontSize: 11 }}>TEMP</span>
            </span>
            <span className="row" style={{ gap: 6 }}>
              <span
                style={{
                  width: 14, height: 14, background: "var(--nb-blue)",
                  border: "2px solid var(--nb-ink)",
                }}
              />
              <span className="font-label" style={{ fontSize: 11 }}>HUM</span>
            </span>
          </div>
        </div>
        <div style={{ height: 360, padding: "8px 14px 14px 0" }}>
          {empty ? (
            <div
              style={{
                height: "100%", display: "flex", alignItems: "center", justifyContent: "center",
                flexDirection: "column", gap: 12, color: "var(--nb-grey-500)",
              }}
            >
              <BarChart2 size={42} strokeWidth={2.5} />
              <span className="font-label" style={{ fontSize: 12 }}>
                NO DATA YET — WAITING FOR TELEMETRY…
              </span>
            </div>
          ) : (
            <ResponsiveContainer width="100%" height="100%">
              <LineChart data={data} margin={{ top: 8, right: 18, left: 8, bottom: 8 }}>
                <CartesianGrid stroke="transparent" />
                <XAxis
                  dataKey="time"
                  stroke="var(--nb-ink)"
                  strokeWidth={2.5}
                  tickLine={false}
                  tick={{ fontFamily: "Space Grotesk", fontWeight: 800, fontSize: 11, fill: "var(--nb-ink)" }}
                />
                <YAxis
                  stroke="var(--nb-ink)"
                  strokeWidth={2.5}
                  tickLine={false}
                  tick={{ fontFamily: "Space Grotesk", fontWeight: 800, fontSize: 11, fill: "var(--nb-ink)" }}
                  width={40}
                />
                <Tooltip content={<CustomTooltip />} cursor={{ stroke: "var(--nb-ink)", strokeWidth: 2 }} />
                {/* Temp line */}
                <Line
                  type="linear"
                  dataKey="temp"
                  stroke="var(--nb-ink)"
                  strokeWidth={4}
                  dot={{
                    r: 5,
                    fill: "var(--nb-yellow)",
                    stroke: "var(--nb-ink)",
                    strokeWidth: 2,
                  }}
                  activeDot={{ r: 7, fill: "var(--nb-yellow)", stroke: "var(--nb-ink)", strokeWidth: 2.5 }}
                  isAnimationActive={false}
                  connectNulls
                />
                {/* Hum line */}
                <Line
                  type="linear"
                  dataKey="hum"
                  stroke="var(--nb-blue)"
                  strokeWidth={4}
                  dot={{
                    r: 5,
                    fill: "var(--nb-white)",
                    stroke: "var(--nb-blue)",
                    strokeWidth: 2,
                  }}
                  activeDot={{ r: 7, fill: "var(--nb-white)", stroke: "var(--nb-blue)", strokeWidth: 2.5 }}
                  isAnimationActive={false}
                  connectNulls
                />
              </LineChart>
            </ResponsiveContainer>
          )}
        </div>
      </NeoCard>

      <div style={{ height: 14 }} />
      <div
        className="row"
        style={{
          padding: "10px 14px",
          background: "var(--nb-yellow)",
          border: "2px solid var(--nb-ink)",
          borderRadius: 4,
          boxShadow: "var(--nb-shadow-sm)",
        }}
      >
        <Info size={16} strokeWidth={2.5} />
        <span className="font-label" style={{ fontSize: 11 }}>
          HOVER ANY POINT FOR EXACT READING
        </span>
        <div className="spacer" />
        <NeoTag label={`${stats.count} LOGS`} variant="ink" />
      </div>

      {/* Per-metric stats */}
      <div style={{ height: 16 }} />
      <div className="grid-2" style={{ display: "grid", gridTemplateColumns: "1fr 1fr", gap: 12 }}>
        <NeoCard padding={14}>
          <div className="row" style={{ marginBottom: 8 }}>
            <span
              style={{
                width: 28, height: 28, background: "var(--nb-yellow)",
                border: "2px solid var(--nb-ink)", display: "flex",
                alignItems: "center", justifyContent: "center", borderRadius: 4,
              }}
            >
              <Thermometer size={16} strokeWidth={2.5} />
            </span>
            <span className="font-display" style={{ fontSize: 13 }}>TEMPERATURE</span>
          </div>
          <Stat label="MIN" value={`${stats.tempMin.toFixed(1)}°C`} />
          <Stat label="MAX" value={`${stats.tempMax.toFixed(1)}°C`} />
          <Stat label="AVG" value={`${stats.tempAvg.toFixed(1)}°C`} />
        </NeoCard>
        <NeoCard padding={14}>
          <div className="row" style={{ marginBottom: 8 }}>
            <span
              style={{
                width: 28, height: 28, background: "var(--nb-blue)",
                border: "2px solid var(--nb-ink)", display: "flex",
                alignItems: "center", justifyContent: "center", borderRadius: 4,
              }}
            >
              <Droplets size={16} strokeWidth={2.5} color="var(--nb-white)" />
            </span>
            <span className="font-display" style={{ fontSize: 13 }}>HUMIDITY</span>
          </div>
          <Stat label="MIN" value={`${stats.humMin.toFixed(1)}%`} />
          <Stat label="MAX" value={`${stats.humMax.toFixed(1)}%`} />
          <Stat label="AVG" value={`${stats.humAvg.toFixed(1)}%`} />
        </NeoCard>
      </div>
    </main>
  );
}

function Stat({ label, value }) {
  return (
    <div className="row-between" style={{ padding: "4px 0" }}>
      <span className="font-label" style={{ fontSize: 10.5 }}>{label}</span>
      <span className="font-mono" style={{ fontWeight: 800, fontSize: 14 }}>{value}</span>
    </div>
  );
}
