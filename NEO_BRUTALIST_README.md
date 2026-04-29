# IoT MONITOR — NEO-BRUTALIST EDITION

A complete Neo-Brutalist redesign of the original Flutter `iot_monitor` application
by **Roman 41-КІ**, plus a parallel **React web demo** that mirrors the Flutter
design pixel-for-pixel and connects to the same public MQTT broker.

---

## 🎨 Neo-Brutalist Design System

| Token              | Value                                                             |
| ------------------ | ----------------------------------------------------------------- |
| Paper background   | `#F4F4F4`                                                         |
| Ink (border / text)| `#000000`                                                         |
| Accent — Yellow    | `#FFF000`                                                         |
| Accent — Blue      | `#0055FF`                                                         |
| Accent — Mint      | `#00FF90`                                                         |
| Alarm — Red        | `#FF3D2E`                                                         |
| Border thickness   | **2.5 px** solid black on every container, card, button, input    |
| Hard shadow        | `offset (5, 5)` · `blur 0` · color `#000000`                      |
| Border radius      | `0 px` (sharp) or **12 px** max (chunky) — never soft / rounded   |
| Display font       | **Archivo Black** (uppercase, heavy)                              |
| Body / numbers     | **Space Grotesk** (700–900) + **JetBrains Mono** for digits       |

When a button / card is pressed, the shadow disappears and the element shifts
`+5px / +5px` to simulate a physical "push".

---

## 📦 Project layout

```
/app
├── lib/                        ← FLUTTER source (drop into your project)
│   ├── theme/
│   │   └── neo_brutalist_theme.dart    ← NB.* design tokens + nbBlock() helper
│   ├── widgets/
│   │   └── neo_widgets.dart            ← NeoCard, NeoButton, NeoTag, NeoIconBox …
│   ├── main.dart                       ← Dashboard (REDESIGNED)
│   ├── analytics_screen.dart           ← Analytics (REDESIGNED)
│   ├── log_screen.dart                 ← Logs (REDESIGNED)
│   ├── mqtt_service.dart               ← UNCHANGED (logic preserved)
│   ├── db_service.dart                 ← UNCHANGED
│   ├── settings_service.dart           ← UNCHANGED
│   ├── export_service.dart             ← UNCHANGED
│   ├── notification_service.dart       ← UNCHANGED
│   └── mqtt_setup*.dart                ← UNCHANGED
├── pubspec.yaml                        ← UNCHANGED
│
├── frontend/                  ← REACT web demo (Neo-Brutalist visual replica)
│   └── src/
│       ├── pages/
│       │   ├── Dashboard.jsx
│       │   ├── Analytics.jsx
│       │   ├── Logs.jsx
│       │   └── Settings.jsx
│       └── components/
│           ├── NeoUI.jsx              ← reusable Neo-Brutalist primitives
│           └── MqttContext.js         ← mqtt.js WebSocket client
│
└── backend/                   ← FastAPI (publishes simulated sensor data)
    └── server.py                       ← /api/mqtt-config · /api/simulator/*
```

---

## 🚀 How to use the Flutter files

The redesigned files live at `/app/lib/`. They are **drop-in replacements**
for the original ones — same imports, same classes, same dependencies.

1. Copy the entire `lib/` folder into your Flutter project (overwriting
   the existing files).
2. Make sure `pubspec.yaml` declares the same dependencies that were already
   in your project (no new packages were added — `google_fonts`, `lucide_icons`,
   `fl_chart`, `intl`, `mqtt_client`, `sqflite`, etc. are all reused).
3. Run:

   ```bash
   flutter pub get
   flutter run            # mobile / desktop
   flutter run -d chrome  # web — works with WSS WebSocket on emqx.io:8084
   ```

### What changed vs. what stayed the same

| Area                                | Status                                                                              |
| ----------------------------------- | ----------------------------------------------------------------------------------- |
| `mqtt_service.dart` — broker, topics, retry, alarm cooldown                | ✅ untouched |
| `db_service.dart` — sqflite + SharedPreferences (web)                       | ✅ untouched |
| `settings_service.dart` — `tempMin/Max`, `humMin/Max`, persistence          | ✅ untouched |
| `export_service.dart` — CSV + share_plus                                    | ✅ untouched |
| `notification_service.dart` — flutter_local_notifications                   | ✅ untouched |
| `main.dart` widget tree, scroll directions, `Stream` bindings                | ✅ preserved |
| `analytics_screen.dart` `FlSpot` math, axis range, `DbService.getLogs()`     | ✅ preserved |
| `log_screen.dart` filter chips, `Dismissible` swipe, date filter, sort       | ✅ preserved |
| Visuals (decorations, typography, palette, shadows, icons, spacing)         | ♻️ **completely rebuilt** to match the Neo-Brutalist spec |

---

## 🌐 React Web Demo

A live, browser-runnable version of the same UI is available at the preview URL.
It connects to the **same public MQTT broker** the Flutter app uses
(`broker.emqx.io` on WebSocket port `8084`) and subscribes to the **same topics**
(`roman_41ki/temp`, `roman_41ki/hum`).

The FastAPI backend runs a small simulator that publishes pseudo-realistic
sensor values every ~2 seconds, so the demo always has live data even without
an ESP32 connected. As soon as your real hardware starts publishing, those
readings show up automatically alongside (or instead of) the simulated ones.

### Backend endpoints

| Method | Endpoint                  | Description                                 |
| ------ | ------------------------- | ------------------------------------------- |
| GET    | `/api/health`             | Health check                                |
| GET    | `/api/mqtt-config`        | Broker host / port / topics for the client  |
| GET    | `/api/simulator/state`    | Counters (publishes / errors / running)     |
| POST   | `/api/simulator/spike`    | Force one out-of-range reading (alarm test) |

---

## 🧪 Testing the redesign

- Open the demo URL — the Dashboard shows live values within ~5 seconds.
- Tap **TRIGGER ALARM** in the dashboard quick actions to publish an
  out-of-range value — the red alarm overlay appears immediately.
- Open **Logs** — every minute a row is captured per metric (mirrors the
  Flutter `db_service` cadence). Swipe the trash button to delete a row.
- Open **Analytics** — last 20 samples per metric drawn with thick black
  lines and solid yellow / blue fills, no grid.
- Open **Settings** — adjust the threshold sliders, hit **Save Changes**;
  alarms re-evaluate immediately on the next message.

---

## 🛠️ Authoring notes / extension points

- All design tokens live in **`/app/lib/theme/neo_brutalist_theme.dart`**.
  Change a colour there and the whole Flutter app updates.
- All reusable Neo-Brutalist widgets live in
  **`/app/lib/widgets/neo_widgets.dart`** — use `NeoCard`, `NeoButton`,
  `NeoTag`, `NeoIconBox`, `NeoSectionHeader`, `NeoStripeBackground`.
- The same tokens exist in the React demo at
  **`/app/frontend/src/index.css`** as CSS variables (`--nb-yellow`,
  `--nb-blue`, `--nb-shadow`, …).

Have fun shipping ⚡
