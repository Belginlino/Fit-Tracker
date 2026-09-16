# FitTrack — Supabase Migration Plan

## Goal

Migrate the existing fitness tracker from Firebase/Cloudflare to **Flutter + Supabase** while preserving the existing UI and features.

Target architecture:

```text
Flutter
  ├── Supabase Auth
  ├── Supabase PostgreSQL
  └── Supabase Storage
```

Core flow:

```text
Workout → Progress Photo → Compress → Upload → Cloud Sync → Timeline → Analytics
```

## 1. Audit First

Inspect the existing project before changing anything.

Find and document:

- Firebase Auth usage
- Firestore usage
- Firebase Storage usage
- Firebase Messaging usage
- Cloudflare R2/Workers/D1 usage
- Existing models
- Repositories/services
- Riverpod providers
- Photo upload flow
- Current screens and navigation
- Existing production data

Do not blindly search-and-replace.

Preserve working UI and business logic wherever possible.

## 2. Remove Firebase and Cloudflare Backend

Remove runtime dependencies and code for:

```text
firebase_core
firebase_auth
cloud_firestore
firebase_storage
firebase_messaging
firebase_analytics

Cloudflare Workers
Cloudflare R2
Cloudflare D1
Wrangler
R2 signed URLs
```

Remove obsolete configuration files such as `google-services.json` and `GoogleService-Info.plist` only when confirmed unnecessary.

Do not delete existing production data before migration is verified.

## 3. Supabase Setup

Use:

- Supabase Auth
- Supabase PostgreSQL
- Supabase Storage
- Row Level Security (RLS)

Flutter uses the public Supabase client configuration.

**Never put the Supabase service-role key in Flutter.**

## 4. Authentication

Replace Firebase Auth with Supabase Auth.

Implement:

```text
Register
Login
Logout
Forgot Password
Session Persistence
Current User
Auth State Changes
```

Flow:

```text
App Launch
   ↓
Check Supabase Session
   ↓
Authenticated?
 ┌───────┴───────┐
Yes              No
 ↓                ↓
Home            Login
```

Use Supabase's supported password-reset and session mechanisms.

## 5. Database Schema

Create these tables:

```text
profiles
progress_photos
workouts
workout_exercises
workout_sets
measurements
workout_templates
workout_template_exercises
personal_records
reminders
user_settings
```

Use UUIDs and `timestamptz`.

### profiles

```sql
id uuid primary key references auth.users(id) on delete cascade
name text
goal text
height numeric
current_weight numeric
target_weight numeric
fitness_level text
preferred_reminder_time time
created_at timestamptz default now()
updated_at timestamptz default now()
```

### progress_photos

```sql
id uuid primary key
user_id uuid references auth.users(id) on delete cascade
storage_path text not null
thumbnail_path text
pose text
workout_id uuid
weight_at_capture numeric
notes text
file_size bigint
mime_type text
width integer
height integer
created_at timestamptz default now()
updated_at timestamptz default now()
```

### workouts

```sql
id uuid primary key
user_id uuid references auth.users(id) on delete cascade
workout_date timestamptz not null
workout_type text
duration_minutes integer
notes text
created_at timestamptz default now()
updated_at timestamptz default now()
```

### workout_exercises

```sql
id uuid primary key
workout_id uuid references workouts(id) on delete cascade
exercise_name text not null
exercise_order integer
created_at timestamptz default now()
```

### workout_sets

```sql
id uuid primary key
workout_exercise_id uuid references workout_exercises(id) on delete cascade
set_number integer
weight numeric
reps integer
created_at timestamptz default now()
```

### measurements

```sql
id uuid primary key
user_id uuid references auth.users(id) on delete cascade
measurement_type text not null
value numeric not null
unit text not null
recorded_at timestamptz not null
notes text
created_at timestamptz default now()
```

Use measurement types such as:

```text
weight
chest
waist
hips
left_arm
right_arm
left_thigh
right_thigh
shoulders
body_fat
```

Do not infer accurate body-fat percentage from ordinary photos.

## 6. Storage

Create a **private** Supabase Storage bucket:

```text
progress-photos
```

Object structure:

```text
{user_id}/progress/{photo_id}/original.webp
{user_id}/progress/{photo_id}/thumbnail.webp
```

Store only object paths in PostgreSQL.

Never store photo binaries in PostgreSQL.

## 7. Storage Security

Use Supabase Storage RLS policies.

A user may access only objects belonging to their authenticated user ID.

Conceptually:

```text
auth.uid()
    =
first segment of storage object path
```

Do not make the bucket public.

Do not use a service-role key in Flutter.

For private image access, use Supabase's authenticated/private access mechanisms or short-lived signed URLs where appropriate.

## 8. Photo Upload Flow

Implement:

```text
Camera/Gallery
      ↓
Preview
      ↓
Orientation correction
      ↓
Resize
      ↓
Compress
      ↓
Generate UUID
      ↓
Upload to Supabase Storage
      ↓
Insert metadata into progress_photos
```

If metadata insertion fails after a successful upload, attempt to clean up the orphaned Storage object.

If upload fails, preserve the temporary local file so the user can retry.

Prevent duplicate submissions.

## 9. Image Optimization

Do not upload unnecessary 5–10 MB camera images.

Target approximately:

```text
Timeline thumbnail: 200–500 KB where practical
Main photo: roughly 500 KB–2 MB depending on quality
```

Use WebP/JPEG as appropriate.

Do not reduce quality so much that long-term visual comparison becomes useless.

Only load full-resolution images for:

- Photo detail
- Zoom
- Before/after comparison

Use thumbnails for:

- Dashboard
- Timeline
- Calendar

## 10. Multi-Device Synchronization

The same Supabase account must work across:

```text
Primary phone
Secondary phone
Laptop/web client
```

Example:

```text
Phone 1
  ↓
Supabase
  ↓
Phone 2 / Laptop
```

All devices must see the same workouts, measurements, photos, and profile data.

Supabase remains the cloud source of truth.

## 11. Row Level Security

Enable RLS on every user-owned table.

Policies must enforce ownership.

For tables with `user_id`:

```sql
auth.uid() = user_id
```

For `profiles`:

```sql
auth.uid() = id
```

For nested workout tables, verify ownership through the parent relationship.

Test that User A cannot:

- Read User B's data
- Update User B's data
- Delete User B's data
- Access User B's photos

Never disable RLS simply to fix a development error.

## 12. Flutter Architecture

Use:

```text
Flutter
Riverpod
go_router
Supabase Flutter
```

Recommended structure:

```text
lib/
├── core/
│   ├── supabase/
│   ├── storage/
│   ├── utils/
│   └── widgets/
│
├── features/
│   ├── auth/
│   ├── dashboard/
│   ├── progress_photos/
│   ├── workouts/
│   ├── measurements/
│   ├── analytics/
│   ├── reminders/
│   ├── profile/
│   └── settings/
```

Use:

```text
UI
 ↓
Riverpod
 ↓
Repository
 ↓
Supabase
```

Do not put Supabase queries directly inside widgets.

## 13. Repositories

Create:

```text
AuthRepository
ProfileRepository
ProgressPhotoRepository
WorkoutRepository
MeasurementRepository
AnalyticsRepository
SettingsRepository
```

Each repository should encapsulate its data access.

## 14. Riverpod Providers

Use focused providers such as:

```text
authProvider
profileProvider
dashboardProvider
progressPhotosProvider
workoutProvider
measurementsProvider
analyticsProvider
settingsProvider
```

Handle:

```text
loading
success
empty
error
refreshing
```

## 15. Dashboard

Preserve the existing design.

Show:

```text
Greeting
Current Weight
Workout Streak
Photo Streak
Today's Workout
Take Progress Photo
Recent Photos
Weekly Summary
```

Do not hardcode personal values.

## 16. Progress Timeline

Query only the authenticated user's photos:

```text
progress_photos
WHERE user_id = authenticated user
ORDER BY created_at DESC
```

Use pagination.

Do not download the entire photo history at startup.

## 17. Calendar

Show daily indicators for:

```text
Workout
Photo
Workout + Photo
No activity
```

Query lightweight date/activity information rather than full images.

## 18. Before/After

Allow the user to select:

```text
Start Photo
End Photo
Pose
```

Support:

- Side-by-side
- Draggable slider

Use only real uploaded photos.

Never modify the user's body or fabricate progress.

## 19. Workout Tracking

Support:

```text
Create workout
Select template
Add exercise
Add sets
Record reps
Record weight
Add notes
Finish workout
```

Support workout history and duplication of previous workouts.

## 20. Measurements

Allow:

```text
Weight
Chest
Waist
Hips
Arms
Thighs
Shoulders
Optional body-fat measurement
```

Track historical values and display trends.

## 21. Analytics

Provide:

```text
Workout count
Photo count
Workout consistency
Photo consistency
Weight trend
Measurement trends
Strength progression
Personal records
Streaks
```

Time ranges:

```text
7D
30D
3M
6M
1Y
ALL
```

Do not download unnecessary raw data when a backend query can return an aggregate.

## 22. Streaks

Implement:

```text
Workout streak
Photo streak
Logging streak
```

Use local timezone consistently.

Store timestamps as `timestamptz`.

Do not incorrectly break a streak because of UTC/local-time conversion.

## 23. Reminders

Do not use Firebase Cloud Messaging.

Use Flutter local notifications for:

```text
Workout reminder
Photo reminder
Weight reminder
Weekly review reminder
```

Allow the user to configure reminders.

Do not spam notifications.

## 24. Offline Upload Queue

Support temporary offline operation:

```text
Take photo
 ↓
Compress
 ↓
Save temporary local file
 ↓
Mark pending
 ↓
Internet returns
 ↓
Upload to Supabase
 ↓
Save metadata
 ↓
Mark complete
```

Do not lose a photo because of temporary connectivity problems.

Prevent duplicate uploads using client-generated IDs.

## 25. Privacy

These photos are highly personal.

Requirements:

```text
Private Storage bucket
RLS
Authenticated access
Secure session handling
Delete photo
Delete account
Minimal data collection
```

Never automatically send photos to an AI provider.

AI access must require explicit user consent.

## 26. Account Deletion

Provide:

```text
Settings → Delete Account
```

Securely remove:

```text
Profile
Workouts
Measurements
Photo metadata
Storage objects
Settings
Authentication account
```

If privileged Auth deletion is required, perform it using a secure server-side mechanism supported by Supabase.

Never put the service-role key in the mobile app.

## 27. Photo Deletion

Flow:

```text
User requests delete
 ↓
Verify ownership
 ↓
Delete Storage object
 ↓
Delete metadata
```

Handle partial failures safely.

## 28. Authentication Migration

If existing Firebase users must be retained, do not directly copy password hashes unless an officially supported migration method is available.

For a development/personal app, recreating accounts may be simpler.

If production migration is required:

```text
Verify existing account securely
 ↓
Create Supabase Auth account
 ↓
Migrate user data
 ↓
Verify
```

Never expose credentials or password hashes to the client.

## 29. Existing Data Migration

If existing Firebase/Cloudflare data exists:

```text
Export old data
 ↓
Map users/data
 ↓
Import into Supabase
 ↓
Migrate photos into Supabase Storage
 ↓
Validate counts
 ↓
Verify random records/photos
 ↓
Switch application
 ↓
Only then remove old backend
```

Do not delete the old data before successful verification.

If there is no production data, skip migration.

## 30. Environment Configuration

Support:

```text
development
staging
production
```

Flutter may contain:

```text
SUPABASE_URL
SUPABASE_ANON_KEY
```

Never include:

```text
SUPABASE_SERVICE_ROLE_KEY
```

in Flutter.

Do not commit secrets.

## 31. Error Handling

Handle:

```text
Authentication errors
Network errors
Storage errors
Database errors
Permission errors
Session expiry
Upload failures
```

Show friendly messages.

Example:

> Could not upload your photo. Check your connection and try again.

Never expose raw database errors or secrets.

## 32. Loading and Empty States

Every major screen needs:

```text
Loading
Empty
Success
Error
Refreshing
```

Photo uploads should show:

```text
Preparing...
Uploading...
Saving...
Complete ✓
```

Prevent accidental double taps while saving.

## 33. API/Query Efficiency

Prefer:

```text
select only required columns
pagination
indexes for actual query patterns
thumbnails
cached images
```

Useful indexes may include:

```text
progress_photos(user_id, created_at)
workouts(user_id, workout_date)
measurements(user_id, measurement_type, recorded_at)
```

Only create indexes when justified.

## 34. UI Preservation

This migration is primarily a backend migration.

Do not unnecessarily redesign the current app.

Preserve:

- Existing colors
- Typography
- Navigation
- Animations
- Layouts
- Existing visual identity

Modify UI only where required for Supabase-specific:

- authentication
- upload state
- error state
- offline state
- session state

## 35. Testing

### Unit tests

Test:

- streak calculations
- weight trends
- measurement calculations
- personal records
- validation
- date/time logic

### Widget tests

Test:

- Login
- Dashboard
- Photo upload
- Workout logging
- Analytics
- Before/after

### Integration tests

Test:

```text
Register
Login
Logout
Create workout
Upload photo
Read photo
Record measurement
Compare photos
Delete photo
```

## 36. Security Testing

Prove:

```text
User A cannot read User B's profile
User A cannot read User B's workouts
User A cannot read User B's measurements
User A cannot read User B's photos
User A cannot modify User B's records
User A cannot delete User B's records
Unauthenticated users cannot access private data
Service-role key is absent from Flutter
```

## 37. Final Repository Search

Search for:

```text
firebase
Firebase
firestore
Firestore
firebase_auth
firebase_storage
FirebaseAuth
FirebaseFirestore
FirebaseStorage
FirebaseMessaging

cloudflare
Cloudflare
r2
R2
wrangler
Worker
D1
```

Review every result.

No obsolete Firebase or Cloudflare runtime dependency should remain.

## 38. Development Sequence

Follow this order:

### Phase 1 — Audit

Inspect current project and produce a migration checklist.

### Phase 2 — Supabase

Create:

```text
Supabase project
Auth
Database
Storage
```

### Phase 3 — Security

Implement and test:

```text
RLS
Storage policies
Authentication
Ownership
```

### Phase 4 — Data Layer

Create repositories and models.

### Phase 5 — Photo System

Implement:

```text
Camera
Gallery
Compression
Thumbnail
Upload
Private access
Delete
Retry
```

### Phase 6 — Backend Replacement

Replace Firebase/Cloudflare repositories and providers with Supabase.

### Phase 7 — Multi-device Testing

Verify:

```text
Phone 1 → Supabase → Phone 2
Phone 1 → Supabase → Laptop
Laptop → Supabase → Phone 1
```

### Phase 8 — Remove Old Backend

Only after successful testing:

```text
Remove Firebase
Remove Cloudflare backend
Remove obsolete packages/configuration
```

### Phase 9 — Final Testing

Run:

```text
flutter analyze
flutter test
flutter build
```

Fix all relevant errors before completion.

## 39. Final Acceptance Test

A user must be able to:

```text
Install
 ↓
Register
 ↓
Login
 ↓
Complete onboarding
 ↓
Log workout
 ↓
Add exercises
 ↓
Add sets/reps/weight
 ↓
Finish workout
 ↓
Take progress photo
 ↓
Compress photo
 ↓
Upload to private Supabase Storage
 ↓
Save metadata to PostgreSQL
 ↓
View timeline
 ↓
Record weight
 ↓
View analytics
 ↓
Compare photos
 ↓
Logout
 ↓
Login on another device
 ↓
See the same data
```

Every step must use real Supabase functionality.

## 40. Final Architecture

```text
                     FITTRACK
                        │
                     Flutter
                        │
              ┌─────────┼─────────┐
              ▼         ▼         ▼
          Supabase   Supabase  Supabase
            Auth     PostgreSQL Storage
                         │         │
                         │         └── Private photos
                         │
                         └── Fitness data
                              + RLS
                         │
              ┌──────────┼──────────┐
              ▼          ▼          ▼
           Phone 1    Phone 2    Laptop
```

## 41. Final Product Principle

The user should experience:

> **Finish gym → Take photo → Save → See the same progress everywhere.**

The backend technology should be invisible to the user.

Priorities:

**Privacy → Reliability → Simple photo capture → Cloud synchronization → Useful analytics → Long-term progress.**

Do not overengineer the MVP.

Start with:

```text
Flutter
+
Supabase Auth
+
Supabase PostgreSQL
+
Supabase Storage
```

Add advanced AI, wearables, health integrations, and advanced analytics only after the core product is stable.
