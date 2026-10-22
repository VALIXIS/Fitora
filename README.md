# Fitora — AI-Powered Fitness & Holistic Wellness Engine

[![CI/CD Pipeline](https://github.com/metspy9069/Fitora/actions/workflows/ci.yml/badge.svg)](https://github.com/metspy9069/Fitora/actions)
[![Flutter](https://img.shields.io/badge/Flutter-3.x-02569B?logo=flutter&logoColor=white)](https://flutter.dev)
[![Riverpod](https://img.shields.io/badge/State-Riverpod%202.x-00D2B8)](https://riverpod.dev)
[![Health Sync](https://img.shields.io/badge/Health%20Connect-Apple%20Health-E91E63)](https://pub.dev/packages/health)
[![AI Engine](https://img.shields.io/badge/AI-Gemini%20Flash%20Coach-4285F4?logo=google&logoColor=white)](https://ai.google.dev)
[![Tests](https://img.shields.io/badge/Tests-136%2F136%20Passing-brightgreen)](https://github.com/metspy9069/Fitora)
[![License: Proprietary](https://img.shields.io/badge/License-Proprietary-red.svg)](LICENSE)

**Fitora** is an enterprise-grade personal fitness, biometric analytics, and holistic wellness engine. Engineered on Flutter and Riverpod with native Health Connect / Apple Health integrations, Fitora combines AI-driven morning briefings (powered by Gemini Flash), SQLite analytics caching, sleep consistency tracking, cycle phase adaptation, and high-performance local notifications.

---

## Key Capabilities

### AI Wellness Coach & Morning Briefings
* **Gemini Flash Diagnostics**: Analyzes yesterday's sleep debt, daily steps, resting heart rate, and readiness score to generate personalized, 3-point actionable wellness briefings.
* **Hermetic Offline Pipeline**: Instant fallback to rule-based diagnostic generators when running offline or without cloud credentials.
* **Auditory Coaching**: Real-time voice cues, interval timers, and audio rep pacing.

### Biometric Synchronization & Analytics
* **Health Connect & Apple Health**: Real-time synchronization of step volume, active burn calories, resting heart rate, and sleep duration via `package:health`.
* **Sleep Consistency Engine**: Overnight vs. same-day sleep interval boundary resolution with ±30m bedtime consistency metrics.
* **SQLite Historical Vault**: High-speed local SQL database supporting 30-day, 90-day, and 1-year historical aggregation queries.
* **Menstrual Cycle Phase Adaptation**: Phase-aware exercise and nutrition adaptations (Follicular, Ovulatory, Luteal, Menstrual).

### Gamification & Habit Streaks
* **Streak Tracking**: Visual milestone markers reinforcing habit sustainability.
* **Badges & Milestones**: Personal record tracking across weight progression, workout volume, and mindfulness sessions.
* **Local Notifications**: Scheduled reminder alerts and hydration prompts via `flutter_local_notifications`.

---

## System Architecture

```
+-----------------------------------------------------------------------------+
|                                   FITORA                                    |
|                                                                             |
|  +--------------------+   +-----------------------+   +-------------------+ |
|  | Biometric Inbound  |   | Core UI & State Layer |   | AI Coach Engine   | |
|  | - Health Connect   |-->| - Riverpod State      |<--| - Gemini Flash    | |
|  | - Apple Health     |   | - Workout Tracker     |   | - Sleep Evaluator | |
|  | - Pedometer Sensor |   | - Cycle Phase Radar   |   | - Recovery Score  | |
|  +--------------------+   +-----------------------+   +-------------------+ |
|            |                          |                         |           |
|            v                          v                         v           |
|  +------------------------------------------------------------------------+ |
|  |                 SQLite Database & SharedPreferences Vault              | |
|  |          (DailyLogRecord, Historical Rollups, Cache Deduplication)     | |
|  +------------------------------------------------------------------------+ |
+-----------------------------------------------------------------------------+
```

---

## Directory Structure

```
Fitora/
├── .devcontainer/                  # VS Code & Codespaces hermetic container
├── .github/
│   └── workflows/
│       ├── ci.yml                 # 4-stage GitHub Actions enterprise pipeline
│       └── valixis_midnight_automerge.yml # Midnight automated bot
├── lib/
│   ├── app/                       # App bootstrap, router, & Riverpod providers
│   ├── core/                      # Health Connect repo, storage, theme & utils
│   ├── features/
│   │   ├── ai_coach/              # Gemini wellness briefings & fallback pipeline
│   │   ├── cycle/                 # Menstrual cycle & phase tracking
│   │   ├── health_sync/           # Pedometer & Health Connect services
│   │   ├── sleep/                 # Sleep consistency & duration models
│   │   └── workouts/              # Workout logs, timers & exercise catalog
│   └── main.dart                  # Top-level entry point with crash resilience
├── test/
│   ├── unit/                      # Sleep calculations, SQLite analytics & weekly tests
│   └── widget_test.dart           # Cold-boot smoke & launch test
├── Dockerfile                     # Multi-stage hermetic web build
├── docker-compose.yml             # Local evaluation stack
├── nginx.conf                     # Production SPA routing & security headers
├── pubspec.yaml                   # Dependency specification
└── analysis_options.yaml          # Strict linting & static analysis rules
```

---

## Environment Variables

| Variable | Description | Required | Default |
| :--- | :--- | :---: | :--- |
| `GEMINI_API_KEY` | Google Gemini API key for wellness briefings | No | Empty (Mock fallback) |
| `FIREBASE_PROJECT_ID` | Optional Firebase project ID | No | Empty |
| `ENVIRONMENT` | Runtime mode | No | `production` |
| `PORT` | Container binding port for Nginx web server | No | `80` (mapped to `8088`) |

---

## Quickstart

### Prerequisites
- [Flutter SDK](https://flutter.dev/docs/get-started/install) (`>= 3.24.0`)
- [Dart SDK](https://dart.dev/get-dart) (`>= 3.5.0`)
- [Docker & Docker Compose](https://www.docker.com/) (optional)

### Clean-Clone Setup & Local Run

```bash
# Clone the repository
git clone https://github.com/metspy9069/Fitora.git
cd Fitora

# Install dependencies
flutter pub get

# Run on Chrome
flutter run -d chrome

# Run on Android / iOS
flutter run
```

### Running with Docker

```bash
# Build and launch the container
docker compose up -d --build

# Access the application at http://localhost:8088
```

---

## Testing & Coverage

Run the complete hermetic test suite:

```bash
# Run all 136 automated tests
flutter test

# Generate lcov coverage report
flutter test --coverage

# Run static analysis
dart analyze lib
```

All 136 tests execute hermetically with zero external network or database dependencies.

---

## License

Proprietary © Metspy. All rights reserved.
