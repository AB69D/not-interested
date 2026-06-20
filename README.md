# Not Interested

> Real-time nudity blur for Android — works across every app, entirely on-device.

**Not Interested** runs silently in the background and automatically blurs sensitive content the moment it appears on your screen — in browsers, social media apps, messaging apps, or anywhere else. No cloud, no data upload, no account required.

---

## How It Works

1. A foreground service captures your screen via Android's MediaProjection API
2. Each frame is passed to an on-device NudeNet ONNX model (320n)
3. Detected regions are sent to a system overlay that draws blur boxes in real-time
4. When nothing is detected, the overlay is invisible

The entire pipeline runs locally. Nothing ever leaves your device.

---

## Features

| Feature | Details |
|---|---|
| **System-wide blur** | Draws over every app using Android's overlay API |
| **On-device ML** | NudeNet 320n ONNX model — zero network calls |
| **Adjustable sensitivity** | Threshold slider from 30 % to 90 % |
| **App exclusions** | Per-app toggle to skip filtering for trusted apps |
| **Foreground service** | Stays running reliably in the background |
| **Detection counter** | Live count of blur events during a session |
| **One-time setup** | Guided 4-step onboarding, permissions asked once |
| **No account, no ads** | Open source and free |

---

## Screenshots

> _Coming soon_

---

## Architecture

```
lib/
├── core/
│   ├── constants/       # Capture resolution, frame rate, defaults
│   ├── di/              # get_it + injectable wiring
│   ├── platform/        # MethodChannel bridges (overlay, screen capture)
│   └── router/          # go_router setup
├── features/
│   ├── home/            # Main toggle screen (MVVM)
│   ├── onboarding/      # 4-page first-run flow
│   ├── settings/        # Sensitivity slider + app exclusions entry
│   └── whitelist/       # Per-app exclusion list
└── services/
    ├── abstract/        # Interfaces for DI / testability
    └── impl/            # Foreground task, overlay, screen capture, ML
```

Pattern: **MVVM** with `Provider` for state, `get_it` + `injectable` for DI, `go_router` for navigation, `freezed` for immutable models.

---

## Permissions Required

| Permission | Why |
|---|---|
| `FOREGROUND_SERVICE` | Keeps the detection pipeline alive |
| `SYSTEM_ALERT_WINDOW` | Draws the blur overlay over other apps |
| `MediaProjection` | Reads screen frames for ML inference |
| `POST_NOTIFICATIONS` | Shows the persistent service notification |

All permissions are requested inline with explanations. The overlay permission opens Settings exactly once.

---

## Getting Started

### Prerequisites

- Flutter `^3.10` / Dart `^3.10.4`
- Android device or emulator (API 26+)

### Run

```bash
flutter pub get
flutter run
```

The ONNX model (`assets/models/nudenet_320n.onnx`) is bundled — no extra download needed.

---

## Tech Stack

- **Flutter** — UI and cross-layer glue
- **Kotlin / Android** — Native screen capture, overlay, foreground service
- **NudeNet 320n** — Lightweight NSFW detection ONNX model
- **get_it + injectable** — Dependency injection
- **Provider** — MVVM state management
- **go_router** — Navigation
- **freezed** — Immutable state models
- **flutter_foreground_task** — Reliable foreground service

---

## Privacy

- Zero network requests
- No analytics, no crash reporting, no ads
- All ML inference is local
- Screen frames are processed in memory and never written to disk

---

## License

MIT
