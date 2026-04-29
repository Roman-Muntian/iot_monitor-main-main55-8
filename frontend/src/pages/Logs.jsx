import React, { useMemo, useState } from "react";
import {
  Thermometer,
  Droplets,
  Calendar,
  X,
  Download,
  AlertTriangle,
  Check,
  Trash2,
  ArrowDown,
  ArrowUp,
  Layers,
  ClipboardList,
} from "lucide-react";
import { useMqtt } from "../components/MqttContext";
import { NeoCard, NeoTag } from "../components/NeoUI";

const TYPE_FILTERS = [
  { key: "Всі", label: "ALL", icon: Layers, color: "var(--nb-yellow)", text: "var(--nb-ink)" },
  { key: "Температура", label: "TEMPERATURE", icon: Thermometer, color: "var(--nb-yellow)", text: "var(--nb-ink)" },
  { key: "Вологість", label: "HUMIDITY", icon: Droplets, color: "var(--nb-blue)", text: "var(--nb-white)" },
];

function downloadCSV(filename, rows) {
  const header = ["ID", "Date & Time", "Type", "Value"];
  const csv = [header, ...rows.map((r) => [
    r.id,
    r.timestamp,
    r.type === "temp" ? "Temperature (°C)" : "Humidity (%)",
    r.value,
  ])]
    .map((r) => r.map((c) => `"${String(c).replace(/"/g, '""')}"`).join(","))
    .join("\n");
  const blob = new Blob([csv], { type: "text/csv;charset=utf-8;" });
  const url = URL.createObjectURL(blob);
  const a = document.createElement("a");
  a.href = url;
  a.download = filename;
  a.click();
  setTimeout(() => URL.revokeObjectURL(url), 500);
}

function FilterChip({ active, label, icon: Icon, color, text, onClick }) {
  return (
    <button
      type="button"
      onClick={onClick}
      className="nb-block-sm"
      style={{
        background: active ? color : "var(--nb-white)",
        color: active ? text : "var(--nb-ink)",
        boxShadow: active ? "var(--nb-shadow-sm)" : "none",
        borderRadius: 6,
        padding: "8px 12px",
        display: "inline-flex",
        alignItems: "center",
        gap: 6,
        cursor: "pointer",
        whiteSpace: "nowrap",
      }}
      data-testid={`filter-${label.toLowerCase()}`}
    >
      <Icon size={14} strokeWidth={2.5} />
      <span className="font-label" style={{ fontSize: 11, color: active ? text : "var(--nb-ink)" }}>
        {label}
      </span>
    </button>
  );
}

function LogTile({ log, settings, onDelete }) {
  const isAnomaly =
    log.type === "temp"
      ? log.value < settings.tempMin || log.value > settings.tempMax
      : log.value < settings.humMin || log.value > settings.humMax;

  const time = log.timestamp.slice(11, 19);

  return (
    <div
      className="nb-block slide-up"
      style={{
        padding: "12px 14px",
        marginBottom: 12,
        display: "flex",
        alignItems: "center",
        gap: 14,
      }}
      data-testid={`log-tile-${log.id}`}
    >
      <div
        style={{
          width: 46,
          height: 46,
          background: log.type === "temp" ? "var(--nb-yellow)" : "var(--nb-blue)",
          border: "2px solid var(--nb-ink)",
          borderRadius: 6,
          display: "flex",
          alignItems: "center",
          justifyContent: "center",
          boxShadow: "3px 3px 0 0 var(--nb-ink)",
        }}
      >
        {log.type === "temp" ? (
          <Thermometer size={22} strokeWidth={2.5} />
        ) : (
          <Droplets size={22} strokeWidth={2.5} color="var(--nb-white)" />
        )}
      </div>
      <div style={{ flex: 1, minWidth: 0 }}>
        <div className="row" style={{ alignItems: "flex-end", flexWrap: "wrap", rowGap: 6 }}>
          <span
            className="font-mono"
            style={{
              fontSize: 22,
              fontWeight: 900,
              color: isAnomaly ? "var(--nb-red)" : "var(--nb-ink)",
            }}
          >
            {log.value}
          </span>
          <span style={{ fontWeight: 700, fontSize: 13, paddingBottom: 2 }}>
            {log.type === "temp" ? "°C" : "%"}
          </span>
          <div style={{ marginLeft: 6 }}>
            {isAnomaly ? (
              <NeoTag label="ERROR" variant="error" icon={AlertTriangle} />
            ) : (
              <NeoTag label="INFO" variant="info" icon={Check} />
            )}
          </div>
        </div>
        <div className="font-label" style={{ fontSize: 10, color: "var(--nb-grey-500)", marginTop: 4 }}>
          {log.type === "temp" ? "TEMPERATURE / ТЕМПЕРАТУРА" : "HUMIDITY / ВОЛОГІСТЬ"}
        </div>
      </div>
      <div className="col" style={{ alignItems: "flex-end", gap: 6 }}>
        <span
          className="font-mono"
          style={{
            background: "var(--nb-ink)",
            color: "var(--nb-yellow)",
            padding: "4px 8px",
            borderRadius: 3,
            fontWeight: 800,
            fontSize: 11,
          }}
        >
          {time}
        </span>
        <button
          onClick={() => onDelete(log.id)}
          className="nb-iconbox"
          style={{ width: 32, height: 32, background: "var(--nb-red)" }}
          data-testid={`delete-log-${log.id}`}
        >
          <Trash2 size={14} strokeWidth={2.5} color="var(--nb-white)" />
        </button>
      </div>
    </div>
  );
}

export default function Logs() {
  const { logs, settings, deleteLog, clearLogs } = useMqtt();

  const [selectedType, setSelectedType] = useState("Всі");
  const [searchDate, setSearchDate] = useState("");
  const [asc, setAsc] = useState(false);

  const filtered = useMemo(() => {
    let arr = logs.filter((l) => {
      const matchType =
        selectedType === "Всі" ||
        l.type === (selectedType === "Температура" ? "temp" : "hum");
      const matchDate = !searchDate || l.timestamp.startsWith(searchDate);
      return matchType && matchDate;
    });
    if (asc) arr = [...arr].reverse();
    return arr;
  }, [logs, selectedType, searchDate, asc]);

  const grouped = useMemo(() => {
    const map = new Map();
    for (const log of filtered) {
      const key = log.timestamp.slice(0, 10);
      if (!map.has(key)) map.set(key, []);
      map.get(key).push(log);
    }
    return Array.from(map.entries());
  }, [filtered]);

  const headerLabel = (key) => {
    const today = new Date().toISOString().slice(0, 10);
    if (key === today) return "TODAY";
    return new Date(key).toLocaleDateString("en-GB", {
      day: "numeric",
      month: "long",
      year: "numeric",
    }).toUpperCase();
  };

  return (
    <main className="container stagger" data-testid="logs-page">
      <NeoCard padding={14}>
        <div className="row-between" style={{ marginBottom: 10 }}>
          <span className="font-label" style={{ fontSize: 10.5 }}>FILTER BY TYPE</span>
          <div className="row" style={{ gap: 8 }}>
            <button
              type="button"
              className="nb-iconbox"
              style={{ width: 36, height: 36, background: "var(--nb-yellow)" }}
              onClick={() => setAsc(!asc)}
              data-testid="toggle-sort"
            >
              {asc ? (
                <ArrowUp size={16} strokeWidth={2.5} />
              ) : (
                <ArrowDown size={16} strokeWidth={2.5} />
              )}
            </button>
            <button
              type="button"
              className="nb-iconbox"
              style={{ width: 36, height: 36, background: "var(--nb-mint)" }}
              onClick={() =>
                downloadCSV(`iot_telemetry_${Date.now()}.csv`, filtered)
              }
              data-testid="download-csv-btn"
            >
              <Download size={16} strokeWidth={2.5} />
            </button>
          </div>
        </div>

        <div className="row" style={{ flexWrap: "wrap", gap: 10 }}>
          {TYPE_FILTERS.map((f) => (
            <FilterChip
              key={f.key}
              label={f.label}
              icon={f.icon}
              color={f.color}
              text={f.text}
              active={selectedType === f.key}
              onClick={() => setSelectedType(f.key)}
            />
          ))}
          <div style={{ width: 2.5, height: 32, background: "var(--nb-ink)", margin: "0 4px" }} />
          <label
            className="nb-block-sm"
            style={{
              background: searchDate ? "var(--nb-mint)" : "var(--nb-white)",
              boxShadow: searchDate ? "var(--nb-shadow-sm)" : "none",
              borderRadius: 6,
              padding: "8px 12px",
              display: "inline-flex",
              alignItems: "center",
              gap: 6,
              cursor: "pointer",
            }}
          >
            <Calendar size={14} strokeWidth={2.5} />
            <input
              type="date"
              value={searchDate}
              onChange={(e) => setSearchDate(e.target.value)}
              style={{
                border: "none", background: "transparent", outline: "none",
                fontFamily: "Space Grotesk", fontWeight: 800, fontSize: 11,
                letterSpacing: "0.12em", textTransform: "uppercase", color: "var(--nb-ink)",
                width: 130,
              }}
              data-testid="date-filter-input"
            />
            {searchDate && (
              <span
                onClick={(e) => {
                  e.preventDefault();
                  setSearchDate("");
                }}
              >
                <X size={14} strokeWidth={2.5} />
              </span>
            )}
          </label>
        </div>
      </NeoCard>

      <div style={{ height: 16 }} />

      {logs.length === 0 ? (
        <NeoCard padding={28}>
          <div style={{ textAlign: "center" }}>
            <div
              className="nb-block-sm"
              style={{
                width: 72, height: 72, display: "inline-flex",
                alignItems: "center", justifyContent: "center",
                background: "var(--nb-blue)", borderRadius: 6,
                marginBottom: 14,
              }}
            >
              <ClipboardList size={32} color="var(--nb-white)" strokeWidth={2.5} />
            </div>
            <div className="font-display" style={{ fontSize: 20, marginBottom: 6 }}>
              NO RECORDS
            </div>
            <div style={{ color: "var(--nb-grey-500)", fontSize: 13 }}>
              Records will appear here once telemetry is captured
            </div>
          </div>
        </NeoCard>
      ) : (
        <>
          {grouped.map(([dateKey, dayLogs]) => (
            <div key={dateKey} style={{ marginBottom: 18 }}>
              <div
                className="row"
                style={{
                  background: "var(--nb-ink)",
                  color: "var(--nb-white)",
                  padding: "8px 12px",
                  borderRadius: 4,
                  marginBottom: 10,
                  boxShadow: "var(--nb-shadow-sm)",
                }}
              >
                <Calendar size={14} strokeWidth={2.5} color="var(--nb-yellow)" />
                <span className="font-label" style={{ fontSize: 11, color: "var(--nb-white)", marginLeft: 8 }}>
                  {headerLabel(dateKey)}
                </span>
                <div className="spacer" />
                <span
                  style={{
                    background: "var(--nb-yellow)", color: "var(--nb-ink)",
                    padding: "2px 6px", borderRadius: 2,
                  }}
                  className="font-label"
                >
                  {dayLogs.length} ENTRIES
                </span>
              </div>
              {dayLogs.map((log) => (
                <LogTile
                  key={log.id}
                  log={log}
                  settings={settings}
                  onDelete={deleteLog}
                />
              ))}
            </div>
          ))}

          {filtered.length === 0 && (
            <div style={{ textAlign: "center", color: "var(--nb-grey-500)", padding: 24 }}>
              <span className="font-label" style={{ fontSize: 12 }}>NO MATCHING RECORDS</span>
            </div>
          )}

          <div style={{ height: 8 }} />
          <button
            type="button"
            className="nb-btn nb-btn--red"
            onClick={() => {
              if (window.confirm("Clear all logs?")) clearLogs();
            }}
            data-testid="clear-logs-btn"
          >
            <Trash2 size={16} strokeWidth={2.5} />
            CLEAR ALL
          </button>
        </>
      )}
    </main>
  );
}
