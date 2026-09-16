# PLAN.md — Firebase to Cloudflare Migration

## Objective

Refactor the existing personalized fitness tracker so **Firebase is completely removed** and replaced with the Cloudflare stack:

- **Cloudflare Workers** — backend API, authentication/session logic, business logic
- **Cloudflare D1** — structured application database
- **Cloudflare R2** — private progress-photo/object storage
- **Flutter local notifications** — local workout/photo reminders

Do not merely replace Firebase Storage with R2. Replace each Firebase responsibility with the appropriate Cloudflare component while preserving the existing UI/UX and functionality.

## Target Architecture

```text
Flutter Mobile App
        │ HTTPS
        ▼
Cloudflare Worker
   ┌────┼──────────────┐
   ▼    ▼              ▼
  D1    R2       Future services
Database Photos
```

R2 stores binary photos only. D1 stores users, workouts, measurements, photo metadata, settings, and relationships. Workers provide the secure API boundary.

## Authentication Migration

Remove Firebase Authentication completely.

Implement:

```text
POST /api/auth/register
POST /api/auth/login
POST /api/auth/logout
POST /api/auth/forgot-password
GET  /api/auth/me
```

Requirements:

- Never store plaintext passwords.
- Use a modern secure password-hashing approach supported by the Workers runtime.
- Use secure sessions/tokens with expiration and revocation/rotation as appropriate.
- Store sensitive server-side secrets only in Cloudflare secrets.
- Never put R2 credentials or server secrets in Flutter.
- Protect every private API endpoint with authentication middleware.

## D1 Database

Create versioned D1 migrations.

Suggested tables:

```text
users
progress_photos
workouts
workout_exercises
workout_sets
measurements
workout_templates
personal_records
reminders
user_settings
```

Suggested relationships:

```text
users
 ├── progress_photos
 ├── workouts
 │    ├── workout_exercises
 │    │    └── workout_sets
 │    ├── measurements
 │    └── optional progress photo references
 ├── workout_templates
 ├── personal_records
 ├── reminders
 └── user_settings
```

Use UUID/string IDs rather than Firebase UIDs. Use foreign keys where appropriate and indexes for common user/date queries.

Example user fields:

```text
id
email
password_hash
name
goal
current_weight
target_weight
height
fitness_level
created_at
updated_at
```

Photo metadata:

```text
id
user_id
object_key
thumbnail_object_key
pose
workout_id
weight_at_capture
notes
created_at
updated_at
```

Never store photo binaries in D1.

## R2 Photo Storage

Create a private R2 bucket, for example:

```text
fittrack-progress-photos
```

Object keys:

```text
users/{userId}/progress/{photoId}/original.webp
users/{userId}/progress/{photoId}/thumbnail.webp
```

Store only object keys in D1.

Do not make personal progress photos public.

## Secure Upload Flow

Never put R2 access keys in the Flutter APK.

Implement:

```text
Flutter selects/takes photo
        ↓
Compress + orient + resize
        ↓
POST /api/photos/upload-url
        ↓
Worker authenticates user
        ↓
Worker validates request
        ↓
Worker generates short-lived signed R2 upload URL
        ↓
Flutter uploads directly to R2
        ↓
Flutter calls POST /api/photos
        ↓
Worker verifies ownership and records metadata in D1
```

Use short-lived presigned URLs. Prefer Worker R2 bindings where appropriate. Never expose permanent credentials to the client.

## Secure Photo Download

For private images:

```text
Flutter
 ↓
GET /api/photos/{id}/access-url
 ↓
Worker authenticates user
 ↓
Worker verifies photo.user_id == authenticated user
 ↓
Worker generates short-lived signed GET URL
 ↓
Flutter displays image
```

A user must never be able to request another user's object by changing an ID.

## Photo Processing

Before upload:

- Correct EXIF orientation.
- Resize oversized images.
- Compress appropriately.
- Prefer WebP when practical.
- Generate thumbnails.
- Preserve enough quality for long-term before/after comparisons.
- Show upload progress.
- Support retry after failure.

Do not apply body-shaping, beautification, or artificial transformation.

## API Routes

Create a clean REST-style Worker API.

### Auth

```text
POST   /api/auth/register
POST   /api/auth/login
POST   /api/auth/logout
POST   /api/auth/forgot-password
GET    /api/auth/me
```

### Profile

```text
GET    /api/profile
PATCH  /api/profile
```

### Photos

```text
POST   /api/photos/upload-url
POST   /api/photos
GET    /api/photos
GET    /api/photos/:id
GET    /api/photos/:id/access-url
PATCH  /api/photos/:id
DELETE /api/photos/:id
```

### Workouts

```text
GET    /api/workouts
POST   /api/workouts
GET    /api/workouts/:id
PATCH  /api/workouts/:id
DELETE /api/workouts/:id
```

### Measurements

```text
GET    /api/measurements
POST   /api/measurements
PATCH  /api/measurements/:id
DELETE /api/measurements/:id
```

### Analytics

```text
GET /api/analytics/dashboard
GET /api/analytics/weight
GET /api/analytics/workouts
GET /api/analytics/strength
GET /api/analytics/photos
```

## Backend Security

Every private request must authenticate first.

```text
Request
 ↓
Auth middleware
 ↓
Extract authenticated user ID
 ↓
Validate input
 ↓
Query D1 using authenticated user ID
 ↓
Return response
```

Never trust a client-supplied `userId` for ownership.

Prevent:

- cross-user reads
- cross-user writes
- cross-user updates
- cross-user deletes
- unauthorized signed URLs

Add rate limiting to login, registration, password recovery, and upload URL endpoints.

Validate uploaded MIME type and file size.

Configure CORS appropriately for the actual Flutter/API architecture; do not blindly use unrestricted production CORS.

## Flutter API Layer

Create a dedicated network/data layer.

Recommended structure:

```text
lib/
├── core/
│   ├── network/
│   │   ├── api_client.dart
│   │   ├── api_exception.dart
│   │   └── auth_interceptor.dart
│   └── storage/
└── features/
    ├── auth/
    ├── progress_photos/
    ├── workouts/
    ├── measurements/
    ├── analytics/
    └── profile/
```

Use repository/service abstractions:

```text
AuthRepository
ProfileRepository
ProgressPhotoRepository
WorkoutRepository
MeasurementRepository
AnalyticsRepository
```

Do not put HTTP calls inside widgets.

Continue using Riverpod for state management.

## Remove Firebase Completely

Search the entire repository for:

```text
firebase_core
firebase_auth
cloud_firestore
firebase_storage
firebase_messaging
firebase_analytics
Firebase.initializeApp
FirebaseAuth
FirebaseFirestore
FirebaseStorage
FirebaseMessaging
```

Remove all Firebase packages, imports, initialization, providers, repositories, configuration, and build integration.

Remove Firebase-specific files such as `google-services.json` and `GoogleService-Info.plist` when no longer needed.

After migration, repository-wide search must confirm there are no Firebase runtime dependencies.

## Flutter Session Handling

Represent:

```text
Unauthenticated
Authenticating
Authenticated
Session expired
```

Handle 401 responses correctly. Refresh/revalidate the session where supported; otherwise clear the session and return the user to login.

Never store passwords. Use secure device storage for sensitive session credentials where appropriate.

## Offline Support

For photos:

```text
Take photo offline
 ↓
Save temporary local file
 ↓
Mark pending
 ↓
When network returns
 ↓
Request signed R2 URL
 ↓
Upload
 ↓
Create D1 metadata
 ↓
Mark complete
```

Use client-generated photo UUIDs to prevent duplicate uploads.

Do not lose workout input if connectivity temporarily fails.

## Existing Data Migration

If the current project has production Firebase data:

1. Export Firebase Auth/Firestore/Storage data safely.
2. Map Firebase documents to D1 rows.
3. Download existing Storage photos.
4. Upload photos to R2.
5. Record R2 object keys in D1.
6. Validate record/photo counts.
7. Test the new app against migrated data.
8. Keep the old Firebase data intact until verification is complete.
9. Only then remove Firebase from the application.

If there is no production data, skip the migration scripts and start with D1/R2.

## Notifications

Remove Firebase Cloud Messaging from the MVP.

Use Flutter local notifications for:

- workout reminders
- progress-photo reminders
- weekly review reminders

If server push is required later, design a Cloudflare-compatible push architecture rather than reintroducing Firebase automatically.

## Analytics

Calculate analytics from D1 rather than downloading large datasets to Flutter.

Support:

- workout count
- workout frequency
- workout duration
- workout consistency
- photo count
- photo consistency
- weight trends
- measurement trends
- exercise progression
- personal records
- streaks

Keep calculations deterministic and based only on real stored data.

## Before/After Comparison

Retrieve only the user's own photos through signed URLs.

Support:

- side-by-side comparison
- draggable before/after slider
- front/side/back comparison
- metadata comparison

Do not fabricate progress or automatically claim exact body-composition changes from photos.

## AI Future Architecture

AI is optional and must not be required for the MVP.

Future flow:

```text
Flutter
 ↓
Worker
 ↓
Authorized photo access
 ↓
AI service
 ↓
Progress insight
```

Only send personal photos to an external AI provider after explicit user consent.

AI must not diagnose medical conditions, claim exact body-fat percentage from ordinary photos, fabricate measurements, or provide dangerous diet/exercise advice.

## Cloudflare Project Structure

If no backend exists, create:

```text
project/
├── mobile/
│   └── Flutter app
└── backend/
    ├── src/
    │   ├── index.ts
    │   ├── routes/
    │   ├── middleware/
    │   ├── services/
    │   ├── db/
    │   └── utils/
    ├── migrations/
    ├── wrangler.toml
    ├── package.json
    └── README.md
```

Use TypeScript for Workers unless the existing backend requires another supported choice.

Configure D1 and R2 bindings through Wrangler/environment configuration.

Use separate development/staging/production environments where practical.

## Database Migrations

Use versioned migration files:

```text
migrations/
├── 0001_initial_schema.sql
├── 0002_measurements.sql
├── 0003_workout_templates.sql
└── 0004_photo_metadata.sql
```

Do not manually alter production schema without a migration.

Use transactions when creating/updating multiple related workout records.

## API Response Format

Use a consistent response format.

Success:

```json
{
  "success": true,
  "data": {}
}
```

Error:

```json
{
  "success": false,
  "error": {
    "code": "PHOTO_UPLOAD_FAILED",
    "message": "Unable to upload photo."
  }
}
```

Never return stack traces, secrets, password hashes, or internal infrastructure details.

## Error Codes

Use centralized codes such as:

```text
AUTH_INVALID_CREDENTIALS
AUTH_SESSION_EXPIRED
AUTH_UNAUTHORIZED
VALIDATION_ERROR
PHOTO_NOT_FOUND
PHOTO_ACCESS_DENIED
PHOTO_UPLOAD_FAILED
WORKOUT_NOT_FOUND
MEASUREMENT_NOT_FOUND
DATABASE_ERROR
STORAGE_ERROR
RATE_LIMITED
INTERNAL_ERROR
```

Map them to friendly Flutter messages.

## UI Preservation

Do not redesign the existing application unnecessarily during this migration.

Preserve the existing:

- screens
- navigation
- design system
- colors
- typography
- animations
- core user flows

Only add/adjust UI for new loading, upload progress, offline, authentication, and API error states.

## Testing

### Unit tests

Test:

- streak calculations
- weight trends
- analytics
- validation
- date/time handling
- personal-record logic

### Widget tests

Test:

- login/register
- dashboard
- photo upload UI
- workout logging
- analytics
- empty/error states

### Integration tests

Test:

- registration
- login/logout
- session expiration
- workout creation/edit/delete
- photo upload/view/delete
- measurement creation
- before/after comparison
- offline retry

### Security tests

Prove that User A cannot read, modify, delete, or generate signed access URLs for User B's data/photos.

## Development Sequence

### Phase 1 — Audit

Inspect the existing project before changing anything.

Find every Firebase dependency, repository, provider, initialization point, configuration file, and security assumption.

Produce a concise migration checklist.

### Phase 2 — Cloudflare Backend

Create Worker + D1 + R2.

Implement:

- schema
- migrations
- authentication/session system
- auth middleware
- profile APIs

### Phase 3 — R2

Implement:

- signed upload URL
- direct upload
- photo metadata
- signed download URL
- delete photo
- thumbnail support

Test independently.

### Phase 4 — Flutter API Layer

Implement repositories and API client.

### Phase 5 — Replace Firebase

Replace Firebase repositories/providers/services while preserving the UI.

### Phase 6 — Remove Firebase

Remove packages, imports, configuration, initialization, and build integration.

### Phase 7 — Harden and Test

Run analysis, tests, build, security checks, and repository-wide Firebase search.

## Security Checklist

```text
[ ] Firebase runtime dependencies removed
[ ] No R2 credentials in Flutter
[ ] R2 bucket private
[ ] Signed upload URLs expire
[ ] Signed download URLs expire
[ ] Auth required for private API routes
[ ] Every D1 query is scoped to authenticated user
[ ] Passwords securely hashed
[ ] Sessions handled securely
[ ] File type validated
[ ] File size validated
[ ] Rate limiting considered
[ ] CORS configured
[ ] Account deletion implemented
[ ] Photo deletion implemented
[ ] Secrets stored only server-side
```

## Acceptance Criteria

The final application must allow a real user to:

```text
Register
 ↓
Login
 ↓
Complete profile
 ↓
Start workout
 ↓
Log exercises/sets/reps/weight
 ↓
Finish workout
 ↓
Take or select progress photo
 ↓
Compress photo
 ↓
Upload securely to R2
 ↓
Store metadata in D1
 ↓
View timeline
 ↓
Record weight/measurements
 ↓
View analytics
 ↓
Compare progress photos
 ↓
Logout
```

All of the above must work without Firebase.

## Final Repository Requirement

The target architecture is:

```text
Flutter
   │ HTTPS
   ▼
Cloudflare Worker
   ├── D1
   │    ├── users
   │    ├── workouts
   │    ├── measurements
   │    ├── photo metadata
   │    └── settings
   │
   └── R2
        ├── original photos
        └── thumbnails
```

Do not overengineer the MVP with Kubernetes, microservices, or unnecessary databases.

The core stack should remain:

**Flutter + Cloudflare Workers + D1 + R2**

## Final Instruction to the Coding Agent

Before modifying code:

1. Inspect the existing project and current Flutter version.
2. Inventory every Firebase dependency.
3. Identify all files that require migration.
4. Check existing UI and preserve it.
5. Create the Cloudflare backend plan.
6. Implement incrementally.
7. Run static analysis after each major phase.
8. Run tests after each major phase.
9. Fix compilation/runtime errors before proceeding.
10. Do not delete existing Firebase production data until migration is verified.
11. At the end, search the entire repository for Firebase references.
12. Confirm the app builds and the full user journey works.

The final product must remain a polished, private, reliable fitness tracker where the user experience is:

**Finish gym → open app → take photo → save → securely stored → see progress over time.**
