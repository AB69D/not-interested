# Not Interested

> Real-time nudity blur for Android — works across every app, entirely on-device.

[![CI](https://github.com/AB69D/not-interested/actions/workflows/ci.yml/badge.svg)](https://github.com/AB69D/not-interested/actions/workflows/ci.yml)
[![Latest Release](https://img.shields.io/github/v/release/AB69D/not-interested?label=download&logo=android)](https://github.com/AB69D/not-interested/releases/latest)

## Download

**[⬇ Download latest APK](https://github.com/AB69D/not-interested/releases/latest)**

> Enable *Install from unknown sources* on your device before installing.

---

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

- Flutter `3.38.5` / Dart `^3.10.4`
- Android device or emulator (API 29+)

### Run

```bash
flutter pub get
flutter run
```

The ONNX model (`assets/models/nudenet_320n.onnx`) is bundled — no extra download needed.

---

## Releases

Releases are built and signed automatically by GitHub Actions.

### Create a new release

```bash
git tag v1.0.1
git push origin v1.0.1
```

The workflow builds a signed APK and publishes it to the [Releases](https://github.com/AB69D/not-interested/releases) page automatically.

### First-time signing setup

Run the keystore generator script once, then add the printed values as GitHub repository secrets:

```bash
bash scripts/generate_keystore.sh
```

Add these secrets at **Repo → Settings → Secrets and variables → Actions**:

| Secret | Value |
|---|---|
| `KEYSTORE_BASE64` | base64-encoded `.jks` file (printed by the script) |
| `KEY_ALIAS` | `not_interested` |
| `KEY_PASSWORD` | password you chose |
| `STORE_PASSWORD` | same password |

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
