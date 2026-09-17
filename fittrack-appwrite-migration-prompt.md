# FitTrack — Supabase to Appwrite Migration Prompt

## ROLE

Act as a senior Flutter architect, backend migration engineer, database designer, and UI/UX engineer.

You are modifying an existing **FitTrack fitness/progress tracking application**.

The application currently uses **Supabase** for backend services. Your task is to **completely remove Supabase and migrate the application to Appwrite**, while preserving all existing functionality, UI design, user data concepts, and app behavior.

The app must continue to support:

- Multiple mobile devices
- Laptop/web access where applicable
- Cloud synchronization
- Daily gym progress photos
- Workout tracking
- Weight and body measurements
- Progress analytics
- Before/after comparisons
- Streaks
- User authentication
- Private user data
- Offline-friendly behavior and retry queues

---

# 1. PRIMARY OBJECTIVE

Replace the current Supabase backend with **Appwrite**.

### Remove completely

- Supabase SDK/packages
- Supabase initialization
- Supabase URL/configuration
- Supabase keys
- Supabase Auth
- Supabase Database queries
- Supabase Storage
- Supabase Storage bucket references
- Supabase Row Level Security logic
- Supabase-specific repositories/services
- Supabase-specific models or helper utilities
- Environment variables used only by Supabase

### Replace with

- **Appwrite Flutter SDK**
- **Appwrite Authentication**
- **Appwrite Databases**
- **Appwrite Storage**
- **Appwrite permissions**
- Appwrite file upload/download APIs
- Appwrite realtime functionality where useful
- Secure Appwrite configuration

After migration, there must be **zero functional dependency on Supabase**.

---

# 2. IMPORTANT RULES

## DO NOT CHANGE THE EXISTING PRODUCT

Do not remove or redesign application functionality unless required for the Appwrite migration.

Preserve:

- Existing screens
- Existing navigation
- Existing user flows
- Existing workout functionality
- Existing progress-photo functionality
- Existing analytics
- Existing measurements
- Existing streak logic
- Existing settings
- Existing validation
- Existing UI theme
- Existing neumorphic design
- Existing animations where practical

The backend should change; the product behavior should remain the same.

---

# 3. APPWRITE ARCHITECTURE

Use Appwrite as the primary cloud backend.

Recommended architecture:

```text
Flutter App
    │
    ├── Appwrite Auth
    │
    ├── Appwrite Databases
    │
    ├── Appwrite Storage
    │
    └── Appwrite Realtime
```

Use a clean repository/service architecture so Appwrite-specific code is isolated from UI code.

Recommended structure:

```text
lib/
├── core/
│   ├── config/
│   │   └── appwrite_config.dart
│   ├── appwrite/
│   │   ├── appwrite_client.dart
│   │   ├── appwrite_auth_service.dart
│   │   ├── appwrite_database_service.dart
│   │   ├── appwrite_storage_service.dart
│   │   └── appwrite_realtime_service.dart
│   ├── errors/
│   ├── constants/
│   └── utils/
│
├── data/
│   ├── models/
│   ├── repositories/
│   └── datasources/
│
├── features/
│   ├── auth/
│   ├── home/
│   ├── progress/
│   ├── workouts/
│   ├── measurements/
│   ├── analytics/
│   └── profile/
│
└── main.dart
```

UI widgets must not directly perform Appwrite API calls.

---

# 4. APPWRITE PROJECT SETUP

Create/configure an Appwrite project for FitTrack.

Configure:

- Project ID
- Project endpoint
- Android platform
- iOS platform if applicable
- Web platform if applicable
- App package/bundle identifiers
- Authentication
- Database
- Storage bucket
- Realtime where required

Create a central configuration:

```dart
class AppwriteConfig {
  static const String endpoint = 'YOUR_APPWRITE_ENDPOINT';
  static const String projectId = 'YOUR_PROJECT_ID';

  static const String databaseId = 'fittrack';

  static const String progressPhotosCollectionId = 'progress_photos';
  static const String workoutsCollectionId = 'workouts';
  static const String workoutExercisesCollectionId = 'workout_exercises';
  static const String workoutSetsCollectionId = 'workout_sets';
  static const String measurementsCollectionId = 'measurements';
  static const String profilesCollectionId = 'profiles';
  static const String settingsCollectionId = 'settings';

  static const String progressPhotosBucketId = 'progress-photos';
}
```

Do not hard-code server secrets into the source code.

---

# 5. APPWRITE CLIENT INITIALIZATION

Create a single reusable Appwrite client.

Example:

```dart
final Client client = Client()
    .setEndpoint(AppwriteConfig.endpoint)
    .setProject(AppwriteConfig.projectId);
```

Initialize Appwrite once.

Create reusable services:

```text
AuthService
DatabaseService
StorageService
RealtimeService
```

Handle Appwrite exceptions centrally.

---

# 6. AUTHENTICATION MIGRATION

Replace Supabase Auth with Appwrite Account authentication.

Support:

- Register
- Login
- Logout
- Current session
- Session restoration
- Password reset
- Email verification if currently supported
- Account deletion if currently supported

Use Appwrite Account APIs.

Authentication flow:

```text
Launch App
   ↓
Check current Appwrite session
   ↓
Session exists?
   ├── Yes → Load user profile → Home
   └── No  → Login
```

Do not store passwords locally.

Do not manually implement password authentication.

---

# 7. USER PROFILE

Replace the Supabase profile table with an Appwrite collection.

Collection:

```text
profiles
```

Suggested attributes:

```text
userId
name
email
profileImageUrl
height
currentWeight
targetWeight
createdAt
updatedAt
```

Use the authenticated Appwrite user's `$id` as the primary user identifier.

Every user's private profile data must be restricted to that user.

---

# 8. DATABASE MIGRATION

Use an Appwrite Database and Collections.

Suggested database:

```text
fittrack
```

Collections:

```text
profiles
progress_photos
workouts
workout_exercises
workout_sets
measurements
templates
records
reminders
settings
```

Adapt the exact collections and attributes to the existing application's current data model.

Do not blindly duplicate the old Supabase schema if the current code already has a better model.

---

# 9. PROGRESS PHOTOS

Use:

```text
Appwrite Storage
```

Bucket:

```text
progress-photos
```

Each uploaded photo should have a corresponding database document.

Suggested document:

```text
progress_photos
```

Attributes:

```text
userId
fileId
photoDate
caption
bodyPart
weightAtUpload
createdAt
updatedAt
```

Relationship:

```text
User
 │
 ├── Progress Photo Document
 │       └── Appwrite Storage File
 │
 ├── Progress Photo Document
 │       └── Appwrite Storage File
 │
 └── Progress Photo Document
         └── Appwrite Storage File
```

Do not store large image binaries directly in the database.

Store images in Appwrite Storage and store the `fileId` in the database.

---

# 10. PRIVATE PHOTO SECURITY

Progress photos are private personal data.

Configure Appwrite Storage permissions so users cannot access another user's photos.

Recommended logic:

```text
User A uploads photo
       ↓
Storage file owned by User A
       ↓
User A can read/update/delete
       ↓
User B cannot access
```

Use Appwrite document/file permissions rather than relying only on hidden UI elements.

Never expose unrestricted public access to private progress photos.

Avoid permanent public image URLs for private photos.

---

# 11. PHOTO UPLOAD FLOW

Implement:

```text
Select Photo
     ↓
Validate File
     ↓
Compress/Resize
     ↓
Generate Unique File ID
     ↓
Upload to Appwrite Storage
     ↓
Create progress_photos document
     ↓
Update local cache
     ↓
Refresh UI
```

Handle failures carefully.

If storage upload succeeds but database creation fails:

```text
Storage upload succeeded
        ↓
Database creation failed
        ↓
Retry database operation
        ↓
If unrecoverable → clean up orphaned file
```

Do not create duplicate photos during retry.

---

# 12. IMAGE OPTIMIZATION

Before upload:

- Resize excessively large images
- Compress JPEG/WEBP when appropriate
- Preserve reasonable visual quality
- Avoid unnecessary multi-megapixel uploads
- Keep thumbnails/previews where useful

The goal is to reduce:

- Storage usage
- Upload time
- Mobile data usage
- Memory consumption

Do not compress images so aggressively that progress comparisons become visually poor.

---

# 13. DATABASE SECURITY

Appwrite permissions must replace Supabase Row Level Security.

For every user-owned document:

```text
read   → current user
create → current user
update → current user
delete → current user
```

Use the authenticated Appwrite user ID.

Do not trust a `userId` sent by the UI without validating the authenticated session.

Ownership should effectively follow:

```text
document.userId == authenticatedUser.$id
```

Implement ownership checks consistently.

---

# 14. WORKOUT DATA

Migrate workout functionality to Appwrite collections.

Possible structure:

```text
workouts
    ↓
workout_exercises
    ↓
workout_sets
```

Example workout document:

```text
userId
name
date
duration
notes
createdAt
updatedAt
```

Exercise document:

```text
workoutId
userId
exerciseName
order
createdAt
```

Set document:

```text
workoutId
exerciseId
userId
setNumber
weight
reps
duration
createdAt
```

Adapt this to the existing FitTrack implementation.

Do not break existing workout history.

---

# 15. BODY MEASUREMENTS

Use:

```text
measurements
```

Suggested attributes:

```text
userId
date
weight
bodyFat
chest
waist
arms
thighs
hips
notes
createdAt
updatedAt
```

Only include fields actually used by the existing application.

Measurements must be private to the authenticated user.

---

# 16. ANALYTICS

Do not move all analytics computation to the backend unnecessarily.

Prefer:

```text
Appwrite Database
       ↓
Repository
       ↓
Local data processing
       ↓
Analytics service
       ↓
Charts/UI
```

Calculate locally where practical:

- Weight trends
- Workout frequency
- Volume progression
- Personal records
- Streaks
- Measurement changes
- Progress-photo timelines

Use Appwrite for persistent synchronized data.

---

# 17. OFFLINE-FIRST BEHAVIOR

The app should remain usable when internet access is temporarily unavailable.

Implement a local cache/database suitable for Flutter.

Possible options:

- Hive
- Isar
- SQLite
- SharedPreferences for small settings only

Do not use SharedPreferences as the main database for large fitness data.

Offline flow:

```text
User action
    ↓
Save locally
    ↓
Update UI immediately
    ↓
Add sync operation to queue
    ↓
Internet available
    ↓
Sync with Appwrite
```

For failed uploads:

```text
Pending
  ↓
Retry
  ↓
Success → remove queue item
  ↓
Failure → exponential backoff
```

Avoid duplicate records during synchronization.

---

# 18. MULTI-DEVICE SYNCHRONIZATION

The application must support:

```text
Mobile 1
   ↕
Appwrite
   ↕
Mobile 2
   ↕
Laptop/Web
```

When the same user logs in on another device:

1. Authenticate with Appwrite
2. Retrieve cloud data
3. Merge with local cache
4. Resolve conflicts
5. Display synchronized data

Appwrite should be the cloud source of truth.

---

# 19. REALTIME SYNC

Where useful, use Appwrite Realtime.

Potential use cases:

- New workout created on another device
- Measurement updated
- Progress photo added
- Profile changes
- Settings changes

Architecture:

```text
Appwrite Realtime
        ↓
Realtime Service
        ↓
Repository refresh
        ↓
State Management
        ↓
UI
```

Do not use realtime for data that does not need it.

---

# 20. STATE MANAGEMENT

Preserve the application's existing state-management solution if one already exists.

If state management needs to be introduced or replaced, use a clean solution such as:

```text
Riverpod
```

Recommended flow:

```text
UI
 ↓
Provider/Controller
 ↓
Repository
 ↓
Appwrite Service
 ↓
Appwrite
```

Never make widgets directly responsible for backend architecture.

---

# 21. ERROR HANDLING

Create centralized error handling.

Handle:

- No internet
- Invalid credentials
- Expired session
- Permission denied
- File upload failure
- Database failure
- Timeout
- Rate limits
- Invalid file
- Storage errors
- Unexpected Appwrite errors

Display user-friendly messages.

Example:

```text
"Unable to upload your photo right now.
It has been saved and will retry when you're online."
```

Do not expose raw backend exceptions to users.

---

# 22. LOADING STATES

Do not freeze the UI during Appwrite operations.

Use:

- Skeleton loading
- Progress indicators
- Upload progress
- Retry buttons
- Empty states
- Pull-to-refresh where appropriate

For photo uploads, show upload progress when supported.

---

# 23. UI PRESERVATION

The existing FitTrack UI uses a soft neumorphic fitness design.

Do not replace this design during backend migration.

Preserve:

- Warm cream/beige background
- Deep teal primary accent
- Rounded cards
- Soft shadows
- Neumorphic controls
- Teal outline icons
- Existing typography hierarchy
- Existing spacing system
- Existing navigation
- Existing animations

Backend migration must remain independent from the visual design.

---

# 24. REMOVE SUPABASE COMPLETELY

Search the entire project for:

```text
supabase
Supabase
supabase_flutter
SupabaseClient
Supabase.instance
```

Also inspect:

```text
pubspec.yaml
pubspec.lock
.env
.env.example
README.md
Android files
iOS files
web files
service files
repositories
providers
controllers
```

Remove unused Supabase dependencies and imports.

Run:

```bash
flutter pub get
```

Then:

```bash
flutter clean
flutter pub get
```

---

# 25. APPWRITE DEPENDENCY

Add the official Appwrite Flutter SDK compatible with the project's current Flutter/Dart version.

Do not blindly copy an outdated version.

After adding it:

```bash
flutter pub get
```

Resolve all dependency conflicts.

---

# 26. ENVIRONMENT CONFIGURATION

Do not commit sensitive credentials.

Use appropriate configuration for:

```text
APPWRITE_ENDPOINT
APPWRITE_PROJECT_ID
APPWRITE_DATABASE_ID
APPWRITE_BUCKET_ID
```

Never put these into Flutter:

- Appwrite API keys
- Server secrets
- Admin credentials
- Privileged server tokens

A mobile application is a public client.

Use Appwrite client-side authentication and permissions correctly.

---

# 27. APPWRITE CONSOLE SETUP DOCUMENTATION

Create clear documentation explaining:

1. Create Appwrite project
2. Add Flutter platforms
3. Configure authentication
4. Create database
5. Create collections
6. Create attributes
7. Configure indexes where required
8. Create storage bucket
9. Configure file permissions
10. Configure document permissions
11. Configure realtime if needed
12. Add project ID and endpoint
13. Run Flutter app
14. Test authentication
15. Test database
16. Test image upload

Do not assume the Appwrite project is already configured.

---

# 28. DATABASE INDEXES

Identify queries that require indexes.

Create indexes for commonly queried fields such as:

```text
userId
createdAt
photoDate
date
workoutId
exerciseId
```

Use compound indexes when actual query patterns require them.

Do not create unnecessary indexes.

---

# 29. DATA MIGRATION

If existing Supabase data exists, provide a migration strategy.

Migration should follow:

```text
Supabase
   ↓
Export existing data
   ↓
Transform schema
   ↓
Upload to Appwrite
   ↓
Map user IDs
   ↓
Upload photos
   ↓
Create Appwrite documents
   ↓
Validate counts/data
```

Do not silently delete existing user data.

If automated migration is not currently possible, provide a migration script/tool rather than pretending migration succeeded.

---

# 30. USER ID MAPPING

Supabase user IDs and Appwrite user IDs may differ.

If existing accounts/data must be migrated, create a mapping:

```text
old_supabase_user_id
        ↓
appwrite_user_id
```

All migrated documents must reference the correct Appwrite user.

Do not assign all migrated data to one user.

---

# 31. DATA VALIDATION

After migration verify:

```text
User count
Profile count
Workout count
Exercise count
Set count
Measurement count
Photo document count
Storage file count
```

Verify:

- Dates
- Weights
- Reps
- Workout history
- Measurements
- Photo references
- Ownership
- File IDs

Perform spot checks where multiple users are supported.

---

# 32. DELETE ACCOUNT FLOW

When a user deletes their account, handle associated data appropriately.

Consider:

```text
User account
   ↓
Profile
   ↓
Workouts
   ↓
Measurements
   ↓
Progress-photo documents
   ↓
Storage files
```

Do not leave unnecessary private files orphaned.

For privileged cleanup operations, use an appropriate secure Appwrite Function when necessary.

Never expose an Appwrite server API key in Flutter.

---

# 33. PERFORMANCE

Optimize:

- Database queries
- Pagination
- Photo loading
- Image caching
- Storage usage
- Realtime subscriptions
- Network requests
- Offline queue processing

For progress photo galleries:

```text
Load thumbnails/previews first
        ↓
Lazy loading
        ↓
Full image only when needed
```

Avoid downloading every historical photo at application startup.

---

# 34. PAGINATION

Do not load unlimited records.

Use pagination for:

- Progress photos
- Workout history
- Measurements
- Analytics history when large
- Other growing collections

The UI should remain fast even after years of fitness data.

---

# 35. APPWRITE SERVICE REQUIREMENTS

Create clean service APIs such as:

```dart
Future<User?> getCurrentUser();

Future<User> register({
  required String email,
  required String password,
  required String name,
});

Future<Session> login({
  required String email,
  required String password,
});

Future<void> logout();

Future<Document> createDocument(...);

Future<List<Document>> listDocuments(...);

Future<Document> updateDocument(...);

Future<void> deleteDocument(...);

Future<String> uploadProgressPhoto(...);

Future<void> deleteProgressPhoto(...);
```

Adapt exact APIs to the existing architecture.

---

# 36. DO NOT COUPLE UI TO APPWRITE

Avoid:

```dart
onPressed: () async {
  final result = await databases.createDocument(...);
};
```

inside every widget.

Preferred:

```text
WorkoutScreen
    ↓
WorkoutController
    ↓
WorkoutRepository
    ↓
AppwriteDatabaseService
```

This makes the backend replaceable in the future.

---

# 37. SECURITY CHECKLIST

Before completion verify:

- [ ] Users can only access their own private data
- [ ] Users cannot read another user's photos
- [ ] Users cannot modify another user's workouts
- [ ] Users cannot delete another user's measurements
- [ ] No Appwrite server API keys are inside Flutter
- [ ] No Supabase keys remain
- [ ] No public bucket access for private photos
- [ ] Authentication state is validated
- [ ] File ownership is enforced
- [ ] Database permissions are configured
- [ ] Sensitive errors are not exposed
- [ ] Debug logs do not expose secrets

---

# 38. TESTING

## Authentication

- Register
- Login
- Logout
- Session restoration
- Invalid password
- Password reset
- Account deletion

## Progress Photos

- Add photo
- Camera photo
- Gallery photo
- Compression
- Upload
- Retry
- Delete
- View
- Before/after comparison
- Offline upload queue

## Workouts

- Create workout
- Add exercise
- Add sets
- Edit sets
- Delete workout
- Workout history
- Multiple-device synchronization

## Measurements

- Add measurement
- Edit measurement
- Delete measurement
- Analytics update

## Multi-device

Test:

```text
Device A → Add workout
Device B → Login
Device B → Verify workout appears

Device B → Add progress photo
Device A → Refresh/realtime
Device A → Verify photo appears
```

---

# 39. OFFLINE TEST

Test:

```text
Disable internet
      ↓
Create workout
      ↓
Add measurement
      ↓
Add progress photo
      ↓
Close/reopen app
      ↓
Enable internet
      ↓
Verify synchronization
```

No user data should be silently lost.

---

# 40. BUILD VERIFICATION

Run:

```bash
flutter analyze
```

Fix all meaningful errors.

Then:

```bash
flutter test
```

Then:

```bash
flutter build apk --release
```

If web is supported:

```bash
flutter build web
```

The final build must succeed without Supabase.

---

# 41. FINAL PROJECT SEARCH

Before declaring completion, search for:

```text
supabase
Supabase
supabase_flutter
SupabaseClient
```

Expected result:

```text
0 functional references
```

Also search for Firebase only if Firebase was previously part of the project and is intentionally being removed.

---

# 42. MIGRATION COMPLETION CRITERIA

The migration is complete only when:

- [ ] Supabase is fully removed
- [ ] Appwrite SDK is installed
- [ ] Appwrite project configuration works
- [ ] Authentication works
- [ ] Session persistence works
- [ ] Database operations work
- [ ] Storage uploads work
- [ ] Private photo access works
- [ ] Photo deletion works
- [ ] Workout CRUD works
- [ ] Measurement CRUD works
- [ ] Analytics still works
- [ ] Multi-device synchronization works
- [ ] Offline queue works
- [ ] Retry logic works
- [ ] Permissions are secure
- [ ] Pagination works
- [ ] Existing UI is preserved
- [ ] No fake backend data is used
- [ ] No Supabase dependency remains
- [ ] `flutter analyze` passes
- [ ] Tests pass
- [ ] Release APK builds successfully

---

# 43. IMPLEMENTATION ORDER

## Phase 1 — Audit

Inspect the entire project.

Identify:

- Supabase initialization
- Auth usage
- Database queries
- Storage usage
- Repositories
- Models
- State management
- Offline logic
- UI dependencies

Do not modify code before understanding the architecture.

## Phase 2 — Appwrite Setup

Configure:

- Appwrite client
- Endpoint
- Project
- Database
- Collections
- Storage
- Permissions

## Phase 3 — Authentication

Replace Supabase Auth with Appwrite Account.

## Phase 4 — Database

Replace Supabase queries with Appwrite Database operations.

## Phase 5 — Storage

Replace Supabase Storage with Appwrite Storage.

## Phase 6 — Repositories

Update repository implementations while keeping UI-facing interfaces stable.

## Phase 7 — Offline Sync

Reconnect the local cache and synchronization queue to Appwrite.

## Phase 8 — Realtime

Add Appwrite Realtime only where beneficial.

## Phase 9 — Testing

Test all features and edge cases.

## Phase 10 — Cleanup

Remove:

- Supabase packages
- Supabase files
- Supabase configuration
- Dead code
- Unused imports
- Unused dependencies

## Phase 11 — Build

Run:

```bash
flutter clean
flutter pub get
flutter analyze
flutter test
flutter build apk --release
```

---

# 44. IMPORTANT IMPLEMENTATION PRINCIPLE

Do not rewrite the entire application unnecessarily.

Prefer:

```text
Existing UI
    ↓
Existing controllers/providers
    ↓
Existing repository interfaces
    ↓
NEW Appwrite repository implementation
    ↓
Appwrite
```

This reduces the risk of breaking working features.

If the existing architecture is tightly coupled to Supabase, refactor only the affected parts into clean repository/service boundaries.

---

# 45. FINAL INSTRUCTION TO THE CODING AGENT

You are not merely adding Appwrite.

You are performing a **complete backend migration from Supabase to Appwrite**.

Before changing code:

1. Inspect the existing project.
2. Understand all Supabase usage.
3. Map every Supabase feature to its Appwrite equivalent.
4. Create the Appwrite architecture.
5. Migrate authentication.
6. Migrate database operations.
7. Migrate storage.
8. Preserve user ownership and privacy.
9. Preserve offline behavior.
10. Preserve multi-device synchronization.
11. Preserve the existing UI.
12. Remove Supabase completely.
13. Test everything.
14. Build the release APK.

Do not use mock APIs.

Do not replace Appwrite with another backend.

Do not remove existing features to simplify the migration.

Do not expose Appwrite server secrets.

Do not claim completion until the application actually builds and the major workflows have been tested.

## FINAL GOAL

> A fully working Flutter FitTrack application using Appwrite instead of Supabase, with private cloud-synchronized fitness data, progress photos, workouts, measurements, analytics, authentication, offline-friendly behavior, and multi-device support — without breaking the existing application.
