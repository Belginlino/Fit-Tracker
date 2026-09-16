# FitTrack — Personal Fitness & Visual Transformation Tracker

FitTrack is a production-grade personal fitness journal and visual progress tracker built with **Flutter**, **Riverpod**, and **Cloudflare Workers + D1 + R2**.

> **Workout → Take progress photo → Record workout/body data → Save → Track progress over time → Compare transformation**

---

## 1. System Architecture

```text
Flutter Mobile App (iOS / Android / Web)
        │
        │ HTTPS (Bearer JWT Authentication)
        ▼
Cloudflare Worker (`backend/`)
   ┌────┼──────────────┐
   ▼    ▼              ▼
  D1    R2       Future Services
Database Photos
```

- **Cloudflare Workers** — Secure REST API, password hashing (PBKDF2/SHA-256), JWT token issuance/verification, request authorization.
- **Cloudflare D1** — Relational SQLite database on edge (Users, Workouts, Exercises, Sets, Measurements, PRs, Photo metadata).
- **Cloudflare R2** — Zero-egress private object storage for high-resolution progress photos and thumbnails.
- **Flutter App** — Clean architecture with Riverpod state management, GoRouter navigation, `ApiClient`, dark athletic UI system.

---

## 2. Project Directory Structure

```text
├── backend/                           # Cloudflare Workers API
│   ├── src/
│   │   ├── index.ts                   # Worker router & CORS handling
│   │   ├── types.ts                   # Environment bindings (DB, PHOTOS_BUCKET, JWT_SECRET)
│   │   ├── middleware/auth.ts         # JWT authentication middleware
│   │   ├── routes/                    # API endpoints
│   │   │   ├── auth.ts                # Register, login, profile, account deletion
│   │   │   ├── photos.ts              # R2 direct binary upload, D1 metadata, streaming
│   │   │   ├── workouts.ts            # Workouts, exercises, sets, automatic PR tracking
│   │   │   ├── measurements.ts        # Weight and body circumferences
│   │   │   └── analytics.ts           # D1 volume progression, streaks, consistency score
│   │   └── utils/crypto.ts            # Web Crypto PBKDF2 & HMAC-SHA256 JWT
│   ├── migrations/
│   │   └── 0001_initial_schema.sql    # D1 relational schema & indexes
│   ├── wrangler.toml                  # Cloudflare Wrangler configuration
│   └── package.json
│
├── lib/                               # Flutter Mobile App
│   ├── main.dart                      # App entry point, Riverpod ProviderScope, ApiClient init
│   ├── app/
│   │   ├── app.dart                   # MaterialApp.router and dark theme setup
│   │   ├── router.dart                # GoRouter with StatefulShellRoute bottom tabs
│   │   └── theme/                     # Dark athletic theme (Electric cyan, lime, OLED dark)
│   ├── core/
│   │   ├── network/                   # ApiClient and ApiEndpoints
│   │   ├── errors/                    # Domain failures and exception handling
│   │   ├── services/                  # NotificationService and ProgressInsightService
│   │   └── widgets/                   # AppButton, AppCard, AppTextField, StreakBadge
│   └── features/
│       ├── auth/                      # Login, Register, Profile, CloudflareAuthRepository
│       ├── onboarding/                # 3-step baseline onboarding
│       ├── dashboard/                 # Home hub with streaks, today's workout, recent photos
│       ├── progress_photos/           # Same-pose camera overlay, Before/After split slider
│       ├── workouts/                  # Active session logger, set steppers, templates
│       ├── measurements/              # Weight trend with fl_chart, body circumferences
│       ├── analytics/                 # Consistency score (0-100), training volume charts
│       └── profile/                   # Account management, data export JSON, deletion
│
└── test/                              # Automated Unit Tests
```

---

## 3. Running Locally

### Start the Cloudflare Backend (D1 & R2 Local Emulation)
Run from the `backend/` directory:
```bash
cd backend
npx wrangler dev
```
*(Runs locally at `http://127.0.0.1:8787` with local D1 and R2 state)*

### Apply D1 Migrations Locally
```bash
cd backend
npx wrangler d1 execute fittrack-db --local --file=./migrations/0001_initial_schema.sql
```

### Run the Flutter App
From the root directory:
```bash
flutter pub get
flutter run
```

### Run Automated Unit Tests
```bash
flutter test
```

---

## 4. Production Cloudflare Deployment

1. **Create remote D1 Database**:
   ```bash
   npx wrangler d1 create fittrack-db
   ```
2. **Apply migrations to remote D1**:
   ```bash
   npx wrangler d1 execute fittrack-db --remote --file=./migrations/0001_initial_schema.sql
   ```
3. **Create remote R2 Bucket**:
   ```bash
   npx wrangler r2 bucket create fittrack-progress-photos
   ```
4. **Deploy Worker**:
   ```bash
   npx wrangler deploy
   ```
