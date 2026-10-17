# 🏋️ Fitora — AI-Powered Fitness & Holistic Wellness

[![Flutter](https://img.shields.io/badge/Flutter-3.x-02569B?logo=flutter&logoColor=white)](https://flutter.dev)
[![Riverpod](https://img.shields.io/badge/State-Riverpod%202.x-00D2B8)](https://riverpod.dev)
[![Firebase](https://img.shields.io/badge/Cloud-Firebase%20Suite-FFCA28?logo=firebase&logoColor=black)](https://firebase.google.com)
[![Health Sync](https://img.shields.io/badge/Health%20Connect-Apple%20Health-E91E63)](https://pub.dev/packages/health)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

**Fitora** is an advanced, AI-powered personal fitness and holistic wellness mobile application built using **Flutter** and **Firebase**. Designed to adapt dynamically to each user's unique physiological rhythms, Fitora combines intelligent workout generation, real-time health device synchronization, sleep analysis, menstrual cycle tracking, and interactive gamification into an elegant, motivating mobile experience.

---

## 🌟 Key Features

### 🤖 Intelligent AI Coach & Wellness Engine
* **Context-Aware Recommendations**: Generates tailored workout routines and recovery plans adjusted for your fatigue, soreness, and previous workout volume.
* **Holistic Wellness Engine**: Calculates daily wellness scores combining physical activity, sleep quality, and active rest intervals.
* **Audio Voice Guidance**: Real-time auditory rep-counting, rest timers, and exercise cues powered by `audioplayers`.

### 🩺 Biometric & Health Synchronization
* **Health Connect & Apple Health**: Direct biometric sync (`package:health`) importing daily step counts, active calories, resting heart rate, and sleep duration.
* **Sleep Analytics**: Detailed sleep stage tracking, restfulness metrics, and bedtime consistency analysis.
* **Cycle & Hormonal Phase Tracking**: Menstrual cycle logging with phase-aware exercise and nutrition adaptations (Follicular, Ovulatory, Luteal).

### 🏆 Gamification & Consistency
* **Streak Tracking**: Visual daily streaks and milestones to reinforce sustained habit building.
* **Badges & Achievements**: Unlock milestones for workout volume, personal records, and mindfulness sessions.
* **Progress Analytics**: High-resolution charting of body weight, strength progression, and workout history.

### ☁️ Cloud Sync & Account Security
* **Firebase Authentication**: One-tap sign-in with Google Sign-In and secure email/password authentication.
* **Cloud Firestore Sync**: Real-time cross-device data backup and offline caching.
* **Local Notifications**: Scheduled reminder alerts and motivational hydration reminders powered by `flutter_local_notifications`.

---

## 🏛️ System Architecture

```
lib/
├── app/                     # App router (GoRouter), theme configuration, and bootstrap
├── core/                    # Global constants, extensions, network clients, utilities
├── features/                # Feature-first modular domain architecture
│   ├── ai_coach/            # AI workout engine & conversational coaching
│   ├── auth/                # Firebase Auth, Google Sign-in providers & UI
│   ├── cloud_backup/        # Firestore sync listeners and state serializers
│   ├── cycle/               # Menstrual cycle tracking & phase calculators
│   ├── gamification/        # Badges, achievements, experience points & streaks
│   ├── health_sync/         # Health Connect / Apple Health permission & ingestion
│   ├── home/                # Executive daily summary & quick actions
│   ├── onboarding/          # Interactive personal goal assessment wizard
│   ├── personalization/     # Muscle group preferences and equipment filters
│   ├── profile/             # User vitals, BMI, target weight, and preferences
│   ├── progress/            # Historical metrics, charts, and PR logs
│   ├── sleep/               # Sleep hygiene tracking and restorative analysis
│   ├── wellness/            # Daily wellness score calculation & mood check-ins
│   ├── wellness_engine/     # Mathematical rules engine combining vitals
│   └── workouts/            # Exercise catalog, active workout timer, rep counter
├── shared/                  # Reusable atomic UI components, buttons, and cards
├── firebase_options.dart    # Firebase CLI generated configuration
└── main.dart                # Application entrypoint
```

---

## 🚀 Getting Started

### Prerequisites
* **Flutter SDK**: `^3.11.1` or higher
* **Dart SDK**: `^3.11.1`
* **Firebase CLI**: Configured with an active Firebase project
* **Android Studio / Xcode**: For device deployment

### Installation Steps

1. **Clone the Repository**
   ```bash
   git clone https://github.com/metspy9069/Fitora.git
   cd Fitora
   ```

2. **Install Flutter Dependencies**
   ```bash
   flutter pub get
   ```

3. **Configure Firebase**
   Run the FlutterFire CLI to link your Firebase project:
   ```bash
   flutterfire configure
   ```
   *Ensure Google Sign-In and Cloud Firestore are enabled in your Firebase console.*

4. **Launch the Application**
   ```bash
   # Run on connected phone or emulator
   flutter run
   ```

---

## 📦 Key Dependencies

| Dependency | Purpose |
| :--- | :--- |
| `flutter_riverpod` & `hooks_riverpod` | Reactive state management and dependency injection |
| `go_router` | Declarative, deep-link capable routing system |
| `firebase_auth` & `cloud_firestore` | User identity and real-time cloud data storage |
| `health` | Native integration with Google Health Connect & Apple HealthKit |
| `flutter_local_notifications` | Timed medication, workout, and hydration reminders |
| `audioplayers` | Audio coaching sound effects and voice cues |
| `google_mobile_ads` | Non-intrusive monetization and rewarded ad slots |

---

## 🧪 Testing & Linting

Run automated unit and widget tests:
```bash
flutter test
```

Execute code analysis:
```bash
flutter analyze
```

---

## 📄 License

This repository is licensed under the [MIT License](LICENSE).
