import React from "react";
import { Routes, Route, NavLink, useNavigate, useLocation } from "react-router-dom";
import { Activity, BarChart2, ClipboardList, Settings, Cpu, Menu, Radio } from "lucide-react";

import { MqttProvider, useMqtt, STATES } from "./components/MqttContext";
import Dashboard from "./pages/Dashboard";
import Analytics from "./pages/Analytics";
import Logs from "./pages/Logs";
import SettingsPage from "./pages/Settings";
import { NeoIconBox, NeoTag } from "./components/NeoUI";

function ConnectionStatus() {
  const { state } = useMqtt();
  let dotColor = "#8a8a8a";
  let label = "CONNECTING…";
  if (state === STATES.CONNECTED) {
    dotColor = "var(--nb-mint)";
    label = "CLIENT ACTIVE";
  } else if (state === STATES.ERROR) {
    dotColor = "var(--nb-red)";
    label = "LINK ERROR";
  } else if (state === STATES.DISCONNECTED) {
    dotColor = "#8a8a8a";
    label = "DISCONNECTED";
  }
  return (
    <div className="row" data-testid="connection-status">
      <span
        style={{
          width: 10,
          height: 10,
          background: dotColor,
          border: "1.5px solid var(--nb-ink)",
        }}
        className={state === STATES.CONNECTED ? "blink" : ""}
      />
      <span className="font-label" style={{ fontSize: 10.5 }}>{label}</span>
    </div>
  );
}

function AppBar() {
  const navigate = useNavigate();
  const location = useLocation();
  const titleMap = {
    "/": "KlimaBox",
    "/analytics": "АНАЛІТИКА",
    "/logs": "ЖУРНАЛ ДАНИХ",
    "/settings": "НАЛАШТУВАННЯ",
  };
  const subMap = {
    "/": "REAL-TIME TELEMETRY",
    "/analytics": "LAST 20 SAMPLES PER METRIC",
    "/logs": "EVENT LOG / TELEMETRY",
    "/settings": "SENSOR THRESHOLDS",
  };
  return (
    <header className="appbar">
      <NeoIconBox
        icon={Menu}
        size={48}
        iconSize={22}
        color="var(--nb-white)"
        onClick={() => navigate("/settings")}
        testId="appbar-menu-btn"
      />
      <div style={{ flex: 1, minWidth: 0 }}>
        <div className="font-display" style={{ fontSize: 20, lineHeight: 1 }}>
          {titleMap[location.pathname] || "IoT MONITOR"}
        </div>
        <div style={{ marginTop: 6 }}>
          {location.pathname === "/" ? (
            <ConnectionStatus />
          ) : (
            <span className="font-label" style={{ fontSize: 10.5 }}>
              {subMap[location.pathname]}
            </span>
          )}
        </div>
      </div>
      <NeoTag label="LIVE" variant="success" icon={Radio} />
    </header>
  );
}

function BottomNav() {
  const items = [
    { to: "/", label: "Dashboard", icon: Cpu, end: true },
    { to: "/analytics", label: "Analytics", icon: BarChart2 },
    { to: "/logs", label: "Logs", icon: ClipboardList },
    { to: "/settings", label: "Settings", icon: Settings },
  ];
  return (
    <nav className="bottom-nav" data-testid="bottom-nav">
      {items.map((it) => (
        <NavLink
          key={it.to}
          to={it.to}
          end={it.end}
          className={({ isActive }) =>
            `bottom-nav__item ${isActive ? "is-active" : ""}`
          }
          data-testid={`nav-${it.label.toLowerCase()}`}
        >
          <span className="bottom-nav__icon">
            <it.icon size={20} strokeWidth={2.5} color="var(--nb-ink)" />
          </span>
          <span>{it.label}</span>
        </NavLink>
      ))}
    </nav>
  );
}

function Shell() {
  return (
    <div className="app-shell">
      <AppBar />
      <Routes>
        <Route path="/" element={<Dashboard />} />
        <Route path="/analytics" element={<Analytics />} />
        <Route path="/logs" element={<Logs />} />
        <Route path="/settings" element={<SettingsPage />} />
      </Routes>
      <BottomNav />
    </div>
  );
}

export default function App() {
  return (
    <MqttProvider>
      <Shell />
    </MqttProvider>
  );
}
