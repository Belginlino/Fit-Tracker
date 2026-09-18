# FitTrack — Personal Fitness & Visual Transformation Tracker

FitTrack is a production-grade personal fitness journal and visual transformation tracker built with **Flutter**, **Riverpod**, and **Appwrite Cloud**.

> **Workout → Take progress photo → Record workout/body data → Save → Track progress over time → Compare transformation**

---

## 1. System Architecture

```text
Flutter Mobile App (Android / iOS / Web / Desktop)
        │
        ▼
   Riverpod Providers & Controllers
        │
        ▼
   Repositories (Workouts, Photos, Measurements, Auth)
        │
        ├── Local Persistence (SharedPreferences Cache)
        │
        ▼
   Appwrite Client SDK (Endpoint: https://sgp.cloud.appwrite.io/v1)
        ┌──────────────┼──────────────┐
        ▼              ▼              ▼
  Appwrite Auth   Appwrite DB    Appwrite Storage
   (Account)      (7 Collections) (Private Bucket)
```

- **Appwrite Auth** — Email/password sessions, session restoration on launch, recovery, account deletion.
- **Appwrite Databases** (`fittrack`) — Document security enabled, 7 collections:
  - `profiles`: Athlete profile, goals, metrics, streak data.
  - `workouts`: Workout sessions, duration, dates, notes.
  - `workout_exercises`: Ordered exercises per workout.
  - `workout_sets`: Weight, reps, set numbers, completion status.
  - `personal_records`: Auto-calculated max weights & PR history.
  - `measurements`: Body weight and circumferences (chest, waist, arms, hips, etc.).
  - `progress_photos`: Photo document records, poses, and timestamps.
- **Appwrite Storage** (`progress-photos`) — File security enabled; private user-only permissions (`Permission.read(Role.user(userId))`, `update`, `delete`).
- **Offline-First Persistence** — Local cache via `SharedPreferences` ensures workouts, measurements, and progress photos persist and load instantly even without active network.

---

## 2. Project Directory Structure

```text
lib/
├── main.dart                      # App entry point, Appwrite init, immersive styling
├── app/
│   ├── app.dart                   # MaterialApp.router and light neumorphic theme
│   ├── router.dart                # GoRouter with /splash, guards, and StatefulShellRoute bottom nav
│   └── theme/                     # Neumorphic palette (Cream #F7F3E8, Deep Teal #006D77)
├── core/
│   ├── appwrite/                  # AppwriteClient singleton and AppwriteConfig
│   ├── constants/                 # AppConstants and dimensions
│   ├── errors/                    # Domain failures and exceptions
│   ├── services/                  # PinService, NotificationService, ProgressInsightService
│   ├── utils/                     # StreakCalculator, DateFormatter, UnitConverter
│   └── widgets/                   # AppButton, AppCard, AppTextField, NeumorphicContainer, AppPhotoImage
└── features/
    ├── auth/                      # Login, Register, Splash, PIN Lock, AppwriteAuthRepository
    ├── onboarding/                # 3-step athletic onboarding
    ├── dashboard/                 # Overview hub, real weekly activity, dynamic streaks
    ├── progress_photos/           # Camera, timeline gallery, comparison slider, calendar view
    ├── workouts/                  # Logging, exercise selection/renaming, volume tracking
    ├── measurements/              # Weight tracker with fl_chart, body circumferences
    ├── analytics/                 # Interactive time-range filters (7D..ALL), volume progression
    └── profile/                   # Physical metrics, PIN security dialog, logout, account deletion
```

---

## 3. Environment & Configuration

Appwrite connection settings are centrally defined in `lib/core/appwrite/appwrite_config.dart`. They can be overridden at build/run time using `--dart-define`:

| Variable | Default Value | Description |
|---|---|---|
| `APPWRITE_ENDPOINT` | `https://sgp.cloud.appwrite.io/v1` | Appwrite instance API endpoint |
| `APPWRITE_PROJECT_ID` | `6aac02f1002c53d0bc56` | Appwrite project identifier |
| `APPWRITE_DATABASE_ID` | `fittrack` | Database ID for user data |
| `APPWRITE_PHOTOS_BUCKET` | `progress-photos` | Storage bucket ID for progress photos |

---

## 4. Local Setup & Running

### Requirements
- Flutter SDK: `>=3.10.0` (Dart SDK `>=3.0.0 <4.0.0`)
- Android Studio / VS Code with Flutter extension
- An active Appwrite Cloud project or local Appwrite instance

### Install Dependencies
```bash
flutter pub get
```

### Static Analysis
```bash
flutter analyze
```

### Run Unit Tests
```bash
flutter test
```

### Run the App
```bash
# Run on connected device or Chrome
flutter run

# Run with custom Appwrite parameters
flutter run --dart-define=APPWRITE_PROJECT_ID=YOUR_ID --dart-define=APPWRITE_ENDPOINT=https://cloud.appwrite.io/v1
```

---

## 5. Automated Appwrite Provisioning Script

To initialize all 7 collections, attributes, indexes, and private storage bucket in a new Appwrite project:
```bash
python scripts/setup_appwrite.py <PROJECT_ID> <API_KEY> [ENDPOINT]
```

---

## 6. Building for Release

### Android APK
```bash
flutter build apk --release
```

### Web
```bash
flutter build web --release
```
