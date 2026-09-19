# FitTrack — Appwrite Console Setup & Migration Guide

This guide provides step-by-step instructions for configuring your **Appwrite** project to power the **FitTrack** application.

---

## 1. Create Appwrite Project

1. Log into your Appwrite Console (e.g. [cloud.appwrite.io](https://cloud.appwrite.io) or your self-hosted instance).
2. Click **Create Project**.
3. Set the project name: `FitTrack`.
4. Note your **Project ID** (e.g., `fittrack` or generated string) and your **API Endpoint** (e.g., `https://cloud.appwrite.io/v1`).

---

## 2. Register Platforms

### Web
1. In Project Settings, click **Add Platform** > **Web App**.
2. **Name**: `FitTrack Web`.
3. **Hostname**: `localhost` (and your production domain if deploying to web hosting).

### Android
1. Click **Add Platform** > **Android App**.
2. **Name**: `FitTrack Android`.
3. **Package Name**: `com.example.fittrack` (or your customized package identifier).

### iOS
1. Click **Add Platform** > **Apple App (iOS)**.
2. **Name**: `FitTrack iOS`.
3. **Bundle ID**: `com.example.fittrack`.

---

## 3. Configure Authentication

1. Navigate to **Auth** in the Appwrite sidebar.
2. Under **Settings**:
   - Ensure **Email / Password** authentication is **Enabled**.
   - (Optional) Configure session expiration length and password history policies according to your preference.

---

## 4. Create Database & Collections

1. Navigate to **Databases** > Click **Create Database**.
2. **Database ID**: `fittrack` (or keep the generated ID and pass it via `--dart-define=APPWRITE_DATABASE_ID=...`).
3. **Database Name**: `FitTrack Database`.

Now create the following **7 Collections**:

### 4.1. Collection: `profiles`
- **Collection ID**: `profiles`
- **Permissions**: Document-level security enabled (or User role: create, read, update, delete).

**Attributes**:
| Key | Type | Size / Options | Required | Default |
|---|---|---|---|---|
| `name` | String | 128 | No | Athlete |
| `goal` | String | 64 | No | Build Muscle |
| `height` | Float | - | No | 178.0 |
| `current_weight` | Float | - | No | 74.2 |
| `target_weight` | Float | - | No | 78.0 |
| `preferred_reminder_time` | String | 16 | No | 18:00:00 |
| `workout_streak` | Integer | - | No | 0 |
| `photo_streak` | Integer | - | No | 0 |
| `has_completed_onboarding` | Boolean | - | No | false |

---

### 4.2. Collection: `workouts`
- **Collection ID**: `workouts`

**Attributes**:
| Key | Type | Size / Options | Required | Default |
|---|---|---|---|---|
| `user_id` | String | 64 | Yes | - |
| `title` | String | 128 | Yes | Workout Session |
| `workout_date` | Datetime / String | 64 | Yes | - |
| `duration_minutes` | Integer | - | No | 45 |
| `notes` | String | 2048 | No | null |

**Indexes**:
- Key: `idx_workouts_user_date` | Type: Key | Attributes: `user_id` (ASC), `workout_date` (DESC)

---

### 4.3. Collection: `workout_exercises`
- **Collection ID**: `workout_exercises`

**Attributes**:
| Key | Type | Size / Options | Required | Default |
|---|---|---|---|---|
| `workout_id` | String | 64 | Yes | - |
| `user_id` | String | 64 | Yes | - |
| `exercise_name` | String | 128 | Yes | - |
| `exercise_order` | Integer | - | No | 0 |

**Indexes**:
- Key: `idx_exercises_workout` | Type: Key | Attributes: `workout_id` (ASC), `exercise_order` (ASC)

---

### 4.4. Collection: `workout_sets`
- **Collection ID**: `workout_sets`

**Attributes**:
| Key | Type | Size / Options | Required | Default |
|---|---|---|---|---|
| `workout_id` | String | 64 | Yes | - |
| `workout_exercise_id` | String | 64 | Yes | - |
| `user_id` | String | 64 | Yes | - |
| `set_number` | Integer | - | Yes | 1 |
| `weight` | Float | - | No | 0.0 |
| `reps` | Integer | - | No | 0 |
| `is_completed` | Boolean | - | No | true |

**Indexes**:
- Key: `idx_sets_exercise` | Type: Key | Attributes: `workout_exercise_id` (ASC), `set_number` (ASC)

---

### 4.5. Collection: `personal_records`
- **Collection ID**: `personal_records`

**Attributes**:
| Key | Type | Size / Options | Required | Default |
|---|---|---|---|---|
| `user_id` | String | 64 | Yes | - |
| `exercise_name` | String | 128 | Yes | - |
| `max_weight` | Float | - | Yes | 0.0 |
| `max_reps` | Integer | - | No | 0 |
| `achieved_at` | Datetime / String | 64 | No | null |
| `workout_id` | String | 64 | No | null |

**Indexes**:
- Key: `idx_pr_user_exercise` | Type: Key | Attributes: `user_id` (ASC), `exercise_name` (ASC)

---

### 4.6. Collection: `measurements`
- **Collection ID**: `measurements`

**Attributes**:
| Key | Type | Size / Options | Required | Default |
|---|---|---|---|---|
| `user_id` | String | 64 | Yes | - |
| `measurement_type` | String | 64 | Yes | weight |
| `value` | Float | - | Yes | - |
| `unit` | String | 16 | No | kg |
| `recorded_at` | Datetime / String | 64 | Yes | - |
| `notes` | String | 1024 | No | null |

**Indexes**:
- Key: `idx_measurements_user_type_date` | Type: Key | Attributes: `user_id` (ASC), `measurement_type` (ASC), `recorded_at` (DESC)

---

### 4.7. Collection: `progress_photos`
- **Collection ID**: `progress_photos`

**Attributes**:
| Key | Type | Size / Options | Required | Default |
|---|---|---|---|---|
| `user_id` | String | 64 | Yes | - |
| `file_id` | String | 64 | Yes | - |
| `storage_path` | String | 128 | No | null |
| `pose` | String | 64 | No | Front |
| `workout_id` | String | 64 | No | null |
| `weight_at_capture` | Float | - | No | null |
| `notes` | String | 2048 | No | null |
| `day_number` | Integer | - | No | 1 |
| `created_at` | Datetime / String | 64 | Yes | - |

**Indexes**:
- Key: `idx_photos_user_date` | Type: Key | Attributes: `user_id` (ASC), `created_at` (DESC)
- Key: `idx_photos_user_day` | Type: Key | Attributes: `user_id` (ASC), `day_number` (ASC)

---

## 5. Create Storage Bucket

1. Navigate to **Storage** > Click **Create Bucket**.
2. **Bucket ID**: `progress-photos`.
3. **Bucket Name**: `Progress Photos`.
4. **Settings**:
   - **File Size Limit**: `15 MB` (recommended).
   - **Allowed File Extensions**: `jpg`, `jpeg`, `png`, `webp`.
   - **Permissions**: Enable **Document Security** (or Role `users` with Create, Read, Delete).
   - **Encryption**: Enabled.
   - **Antivirus**: Enabled (if supported).

---

## 6. Running the Flutter App with Appwrite Config

When running or building FitTrack, provide your Appwrite configuration parameters via `--dart-define` or update `lib/core/appwrite/appwrite_config.dart`:

```bash
# Debug Run
flutter run -d chrome \
  --dart-define=APPWRITE_ENDPOINT="https://cloud.appwrite.io/v1" \
  --dart-define=APPWRITE_PROJECT_ID="your_project_id" \
  --dart-define=APPWRITE_DATABASE_ID="fittrack" \
  --dart-define=APPWRITE_PHOTOS_BUCKET="progress-photos"

# Release Web Build
flutter build web --release \
  --dart-define=APPWRITE_ENDPOINT="https://cloud.appwrite.io/v1" \
  --dart-define=APPWRITE_PROJECT_ID="your_project_id"

# Release APK Build
flutter build apk --release \
  --dart-define=APPWRITE_ENDPOINT="https://cloud.appwrite.io/v1" \
  --dart-define=APPWRITE_PROJECT_ID="your_project_id"
```
