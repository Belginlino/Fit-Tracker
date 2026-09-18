# FitTrack --- Complete Bug Fix & Stabilization Prompt

## ROLE

Act as a senior Flutter architect, debugging engineer, QA engineer,
Appwrite engineer, security engineer, and mobile performance specialist.

The existing **FitTrack** application is currently unreliable and
contains multiple bugs and broken flows. Your job is to audit the entire
project, reproduce the problems, identify root causes, fix them
systematically, and verify that the application actually works.

**Do not merely make the project compile. Make the product function
correctly.**

------------------------------------------------------------------------

## 1. PRIMARY OBJECTIVE

Stabilize the complete application while preserving its existing
functionality and design.

The final app must reliably support:

-   Appwrite authentication
-   User profiles
-   Daily gym progress photos
-   Private cloud photo storage
-   Workout tracking
-   Workout history
-   Weight/body measurements
-   Analytics
-   Before/after comparison
-   Streaks
-   Offline-friendly behavior
-   Multi-device synchronization
-   Existing neumorphic UI
-   Responsive layouts
-   Error/loading/empty states

Do not remove features to hide bugs.

Do not replace real functionality with mock data.

------------------------------------------------------------------------

## 2. FIRST: AUDIT BEFORE MODIFYING

Inspect the complete repository:

``` text
pubspec.yaml
lib/
test/
android/
ios/
web/
assets/
.env*
configuration files
```

Search for:

``` text
TODO
FIXME
throw
catch
print(
debugPrint(
supabase
Supabase
firebase
Firebase
Appwrite
async
await
setState
Stream
Future
```

Identify:

-   Compile errors
-   Runtime crashes
-   Null-safety problems
-   Incorrect async handling
-   Race conditions
-   Navigation problems
-   State-management problems
-   Appwrite configuration errors
-   Database/schema mismatches
-   Storage/permission problems
-   Image loading problems
-   Offline/sync bugs
-   Duplicate requests
-   Memory leaks
-   UI overflow
-   Incorrect calculations
-   Fake/mock data
-   Dead code
-   Deprecated APIs
-   Incorrect model serialization

**Do not start randomly editing files. Understand the architecture
first.**

------------------------------------------------------------------------

## 3. RUN AND REPRODUCE

Run:

``` bash
flutter doctor
flutter pub get
flutter analyze
flutter test
flutter run
```

If possible, test on a real Android device and emulator.

Record every error and reproduce it before fixing it.

Create a prioritized bug inventory:

``` text
P0 Critical — crashes, data loss, security, authentication failure
P1 High     — major feature broken
P2 Medium   — incorrect behavior or significant UX issue
P3 Low      — minor visual/UX issue
```

Fix P0/P1 first.

------------------------------------------------------------------------

## 4. APPWRITE AUDIT

The backend is **Appwrite**.

Verify:

``` text
Endpoint
Project ID
Database ID
Collection IDs
Storage bucket ID
Platform configuration
Authentication
Permissions
Indexes
Realtime
```

Use one centralized Appwrite client.

Recommended separation:

``` text
UI
 ↓
Controller / Provider
 ↓
Repository
 ↓
Appwrite Service
 ↓
Appwrite
```

Create/maintain services such as:

``` text
AuthService
DatabaseService
StorageService
RealtimeService
```

Widgets must not contain scattered Appwrite API calls.

Never put Appwrite server API keys, admin credentials, or privileged
tokens in Flutter.

------------------------------------------------------------------------

## 5. AUTHENTICATION

Test the complete flow:

``` text
Launch
 ↓
Check session
 ↓
Existing session? → Load profile → Home
                 → No → Login
```

Verify:

-   Registration
-   Login
-   Logout
-   Session restoration
-   Session expiration
-   Invalid credentials
-   Password reset if implemented
-   Email verification if implemented
-   Account deletion

Fix:

-   Infinite redirects
-   Login appearing after successful login
-   Unexpected logout
-   Null-user crashes
-   Loading screens that never finish
-   Duplicate login/register requests
-   Session race conditions

Passwords must never be stored locally.

------------------------------------------------------------------------

## 6. DATABASE AUDIT

Inspect every CRUD operation for the actual collections used by the
project, including where applicable:

``` text
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

Verify:

``` text
CREATE
READ
UPDATE
DELETE
```

Check:

-   Correct IDs
-   Attribute names
-   Data types
-   Required/optional attributes
-   Query syntax
-   Sorting
-   Pagination
-   Indexes
-   Permissions
-   Date handling
-   Numeric handling

Do not assume the Dart model matches the Appwrite schema.

------------------------------------------------------------------------

## 7. MODEL SERIALIZATION

Audit:

``` text
fromJson()
toJson()
fromDocument()
toDocument()
copyWith()
```

Correctly handle:

-   Appwrite `$id`
-   `$createdAt`
-   `$updatedAt`
-   Missing fields
-   Null values
-   Integers/doubles
-   Date strings
-   Empty strings
-   Optional attributes

Avoid unsafe casts such as:

``` dart
value as int
```

when backend values may have another numeric representation.

------------------------------------------------------------------------

## 8. PROGRESS PHOTO SYSTEM

This is a critical feature.

Test:

``` text
Camera/Gallery
 ↓
Select
 ↓
Validate
 ↓
Compress/resize
 ↓
Upload to Appwrite Storage
 ↓
Create database document
 ↓
Display
 ↓
Full preview
 ↓
Before/After
 ↓
Delete
```

Fix:

-   Image picker failures
-   Permission problems
-   Large image crashes
-   Upload failures
-   Duplicate uploads
-   Wrong file IDs
-   Broken preview URLs
-   Permission denied errors
-   Gallery not refreshing
-   Wrong sorting/date
-   Database document without file
-   File without database document

If storage upload succeeds but document creation fails, retry safely and
clean up orphaned files when appropriate.

Never solve a private-photo problem by making the bucket public.

------------------------------------------------------------------------

## 9. PRIVATE PHOTO SECURITY

Progress photos are private.

Expected:

``` text
User A
 → create/read/update/delete own photos

User B
 → cannot access User A photos
```

Enforce this using Appwrite document and file permissions.

Test cross-user access if possible.

Do not rely only on hiding buttons in the UI.

------------------------------------------------------------------------

## 10. IMAGE PREVIEW BUGS

If images fail to display, investigate:

``` text
Bucket ID
File ID
Project ID
Endpoint
Authentication
File permissions
Preview/view API
URL generation
Caching
```

Centralize preview URL/file access inside `StorageService`.

Do not construct Appwrite URLs differently across multiple widgets.

Use the API appropriate to the installed Appwrite SDK version.

------------------------------------------------------------------------

## 11. WORKOUT SYSTEM

Test:

-   Create workout
-   Edit workout
-   Delete workout
-   Add exercise
-   Edit exercise
-   Delete exercise
-   Add sets
-   Edit sets
-   Delete sets
-   Weight
-   Reps
-   Duration
-   Notes
-   Workout history
-   Templates if implemented
-   Personal records if implemented

Verify no:

-   Duplicate sets
-   Duplicate exercises
-   Lost workouts
-   Incorrect totals
-   Incorrect dates
-   Stale UI
-   Local/remote inconsistencies

Test complete CRUD.

------------------------------------------------------------------------

## 12. MEASUREMENTS

Test all implemented measurements:

-   Weight
-   Body fat
-   Chest
-   Waist
-   Arms
-   Thighs
-   Hips
-   Other existing fields

Verify:

-   Add
-   Edit
-   Delete
-   History
-   Charts
-   Validation

Prevent invalid values, `NaN`, `Infinity`, and unintended negative
values.

------------------------------------------------------------------------

## 13. ANALYTICS

Audit every calculation.

Check:

-   Weight trends
-   Weight change
-   Workout count
-   Workout frequency
-   Workout volume
-   Streaks
-   Personal records
-   Measurement changes
-   Progress timeline

Test:

``` text
0 records
1 record
multiple records
missing optional values
```

Analytics must use real user data.

Charts must not crash when data is empty.

------------------------------------------------------------------------

## 14. STREAKS AND DATES

Use one consistent date/time strategy throughout the application.

Test:

``` text
No activity
One active day
Consecutive days
Skipped day
Multiple activities in one day
Month boundary
Year boundary
```

Do not count multiple activities on one day as multiple streak days
unless that is explicitly the existing product rule.

Avoid timezone-related off-by-one-day bugs.

------------------------------------------------------------------------

## 15. OFFLINE-FIRST BEHAVIOR

If offline support exists, verify:

``` text
Offline
 ↓
User creates/edits data
 ↓
Save locally
 ↓
UI updates
 ↓
Queue synchronization
 ↓
Internet returns
 ↓
Sync to Appwrite
```

Test:

-   Offline app launch
-   Offline workout creation
-   Offline measurements
-   Offline photo queue
-   Retry
-   Reconnection
-   Duplicate prevention
-   Conflict handling

Never silently lose user data.

Use retry/backoff rather than infinite rapid retries.

------------------------------------------------------------------------

## 16. MULTI-DEVICE SYNC

Test at least two devices.

Example:

``` text
Device A → create workout
Device B → login → verify workout

Device B → add photo
Device A → refresh/realtime → verify photo
```

Test edits and deletes too.

Appwrite should be the cloud source of truth.

Do not let stale local cache overwrite newer server data.

Define a clear conflict strategy.

------------------------------------------------------------------------

## 17. REALTIME

If Appwrite Realtime is implemented, audit:

-   Subscription creation
-   Subscription cleanup
-   Duplicate subscriptions
-   Event filtering
-   Reconnection
-   Screen lifecycle
-   State refresh

Dispose subscriptions when screens/controllers are destroyed.

Prevent duplicate event processing.

------------------------------------------------------------------------

## 18. NAVIGATION

Test every actual screen in the project.

At minimum inspect:

``` text
Splash
Login
Register
Home
Progress
Add Photo
Photo Preview
Before/After
Workout
Workout Detail
Analytics
Measurements
Profile
Settings
```

Check:

-   Back button
-   Android back gesture
-   Bottom navigation
-   Logout
-   Login redirect
-   Dialogs
-   Bottom sheets
-   Empty states
-   Error states
-   Deep navigation

No screen should lead to a dead end.

------------------------------------------------------------------------

## 19. STATE MANAGEMENT

Audit providers/controllers/notifiers.

Look for:

-   State updates after dispose
-   Async calls after dispose
-   Loading flags never reset
-   Error state never cleared
-   Stale state
-   Duplicate API calls
-   Provider recreation
-   Race conditions

Every asynchronous feature should have predictable states:

``` text
idle
loading
success
error
```

Do not perform network/database operations from `build()`.

------------------------------------------------------------------------

## 20. ASYNC BUGS

Search all:

``` dart
async
await
Future
.then(
```

Fix:

-   Missing `await`
-   Unhandled Futures
-   Incorrect try/catch
-   `setState` after dispose
-   Race conditions
-   Concurrent duplicate requests
-   Async work inside build
-   Lifecycle issues

Use cancellation/disposal where appropriate.

------------------------------------------------------------------------

## 21. BUTTON AND DUPLICATE ACTION BUGS

Prevent double-tapping for:

``` text
Login
Register
Save
Upload
Delete
Create Workout
Add Set
```

During an active request:

``` text
Disable action
Show progress
Prevent duplicate request
```

Restore the control after success/failure.

------------------------------------------------------------------------

## 22. FORMS AND KEYBOARD

Test every form.

Fix:

-   Keyboard covering fields/buttons
-   Overflow
-   Wrong keyboard type
-   Focus issues
-   Validation issues
-   Empty input
-   Invalid numeric input
-   Password visibility
-   Keyboard dismissal

Use responsive scrolling and SafeArea appropriately.

------------------------------------------------------------------------

## 23. UI / RESPONSIVE BUGS

Test different screen sizes.

Look for:

``` text
RenderFlex overflow
Bottom overflow
Text clipping
Button overflow
Dialog overflow
Bottom-sheet overflow
Long names
Large numbers
Empty lists
Small screens
Large screens
```

Do not solve responsive problems with excessive hard-coded positions.

Preserve the existing warm cream/beige, deep-teal, soft-neumorphic
FitTrack design.

------------------------------------------------------------------------

## 24. LOADING / EMPTY / ERROR STATES

Every data-driven screen must correctly handle:

``` text
Loading
Success with data
Success with no data
Error
```

Example:

``` text
Loading → Skeleton

Empty → Helpful empty state + action

Error → Message + Retry

Success → Real data
```

No endless spinners.

No fake data used to make screens look populated.

------------------------------------------------------------------------

## 25. DELETE OPERATIONS

Audit every destructive action.

Use confirmation where appropriate.

For a progress photo:

``` text
Confirm
 ↓
Delete Storage file
 ↓
Delete database document
 ↓
Update cache
 ↓
Refresh UI
```

Handle partial failures correctly.

Never show "deleted" when the backend operation actually failed.

------------------------------------------------------------------------

## 26. CACHE CONSISTENCY

If local caching exists:

``` text
Remote → Local
Local → Remote
```

must be consistent.

Prevent stale cache from overwriting fresh server data.

After mutations either:

``` text
update cache
```

or:

``` text
invalidate and refresh
```

Do not leave stale UI visible indefinitely.

------------------------------------------------------------------------

## 27. APP LIFECYCLE

Test:

``` text
Open app
Background app
Resume app
Kill app
Restart app
Lose internet
Restore internet
```

Verify:

-   Session persists
-   Sync resumes
-   Realtime reconnects
-   Pending uploads continue
-   Local cache remains valid
-   No duplicate operations

------------------------------------------------------------------------

## 28. PERFORMANCE

Check for:

-   Full-resolution images loaded everywhere
-   Unbounded lists
-   Large database queries
-   Missing disposal
-   Uncancelled streams
-   Realtime subscriptions left alive
-   Expensive build methods
-   Repeated requests
-   Memory leaks

Use:

-   Pagination
-   Lazy loading
-   Image caching
-   Thumbnails/previews
-   Proper disposal

Do not download every historical photo on startup.

------------------------------------------------------------------------

## 29. SECURITY AUDIT

Verify:

-   No Appwrite server API keys in Flutter
-   No admin credentials in client code
-   No passwords stored locally
-   Private photos are private
-   User ownership is enforced
-   Cross-user access is blocked
-   Sensitive logs are removed
-   Debug secrets are removed
-   Production configuration is safe

------------------------------------------------------------------------

## 30. REMOVE OLD BACKEND REFERENCES

Search for:

``` text
supabase
Supabase
supabase_flutter
SupabaseClient
Firebase
FirebaseStorage
Firestore
```

Remove old backend references that are no longer intentionally required.

Do not remove a dependency blindly; verify its actual usage first.

The final application must have no functional Supabase dependency.

------------------------------------------------------------------------

## 31. DEPENDENCY AUDIT

Inspect `pubspec.yaml`.

Remove only genuinely unused/obsolete packages.

Then run:

``` bash
flutter pub get
flutter analyze
```

Avoid unrelated package upgrades while fixing bugs unless necessary.

------------------------------------------------------------------------

## 32. TESTING

Create/fix automated tests for:

### Models

-   Serialization
-   Deserialization
-   Null handling
-   Dates
-   Numeric conversions

### Business logic

-   Streaks
-   Weight calculations
-   Workout volume
-   Analytics
-   Validation

### Repositories

Test:

-   Create
-   Read
-   Update
-   Delete
-   Appwrite errors

### UI

Test important flows:

-   Login
-   Add workout
-   Add measurement
-   Add photo
-   Delete photo

------------------------------------------------------------------------

## 33. MANUAL QA

Perform a complete manual test:

### Launch

-   [ ] Starts without crash
-   [ ] Splash works
-   [ ] Authentication state correct

### Auth

-   [ ] Register
-   [ ] Login
-   [ ] Logout
-   [ ] Session restoration
-   [ ] Invalid credentials

### Home

-   [ ] Dashboard loads
-   [ ] Real statistics
-   [ ] Empty state

### Progress

-   [ ] Gallery
-   [ ] Add photo
-   [ ] Preview
-   [ ] Delete
-   [ ] Before/after
-   [ ] Correct dates

### Workout

-   [ ] Create
-   [ ] Exercises
-   [ ] Sets
-   [ ] Edit
-   [ ] Delete
-   [ ] History

### Measurements

-   [ ] Add
-   [ ] Edit
-   [ ] Delete
-   [ ] History
-   [ ] Charts

### Analytics

-   [ ] Correct calculations
-   [ ] Empty data safe

### Profile

-   [ ] Load
-   [ ] Edit
-   [ ] Save

### Settings

-   [ ] Controls work
-   [ ] Logout works

### Offline

-   [ ] App launches offline
-   [ ] Local data available
-   [ ] New changes queued
-   [ ] Sync after reconnect

### Multi-device

-   [ ] Device A → Device B sync
-   [ ] No duplicates
-   [ ] No data loss

------------------------------------------------------------------------

## 34. RELEASE BUILD

Run:

``` bash
flutter clean
flutter pub get
flutter analyze
flutter test
flutter build apk --release
```

If web is supported:

``` bash
flutter build web --release
```

Install and manually test the release APK.

Do not assume debug success means release success.

------------------------------------------------------------------------

## 35. NO FAKE FIXES

Never fix a bug by:

-   Adding fake data
-   Hardcoding successful responses
-   Hiding errors
-   Making private storage public
-   Disabling authentication
-   Disabling permissions
-   Commenting out broken features
-   Returning empty lists to hide failures
-   Ignoring exceptions
-   Removing features
-   Using dummy Appwrite IDs

Fix the actual root cause.

------------------------------------------------------------------------

## 36. ROOT-CAUSE WORKFLOW

For every discovered bug:

``` text
Reproduce
   ↓
Collect logs/error
   ↓
Find root cause
   ↓
Implement smallest correct fix
   ↓
Test original failure
   ↓
Test related feature
   ↓
Regression test
```

Example:

If progress photos do not display, investigate:

``` text
Upload succeeded?
 ↓
Storage file exists?
 ↓
Database document exists?
 ↓
Correct fileId?
 ↓
Correct bucket?
 ↓
Permissions?
 ↓
Authenticated session?
 ↓
Correct preview API?
 ↓
Model parsing?
 ↓
State refresh?
```

Do not simply add `setState()` until it works by accident.

------------------------------------------------------------------------

## 37. DATA INTEGRITY

For every mutation:

``` text
Validate
 ↓
Persist
 ↓
Confirm success
 ↓
Update cache/UI
```

If persistence fails:

``` text
Do not show success
Preserve local data where possible
Offer retry
```

Never silently lose user data.

------------------------------------------------------------------------

## 38. ARCHITECTURE REFACTORING

If existing architecture causes repeated bugs, refactor toward:

``` text
Presentation
    ↓
Domain/business logic
    ↓
Repository
    ↓
Data source/service
    ↓
Appwrite
```

Do this incrementally.

Do not rewrite the entire application without evidence that a rewrite is
necessary.

------------------------------------------------------------------------

## 39. DOCUMENTATION

Update `README.md` with the actual working setup:

-   Flutter version
-   Appwrite setup
-   Project configuration
-   Database collections
-   Storage bucket
-   Permissions
-   Environment variables
-   Local setup
-   Testing
-   APK build
-   Known limitations

Do not document features that do not work.

------------------------------------------------------------------------

## 40. FINAL BUG FIX REPORT

Create:

``` text
# FitTrack Bug Fix Report

## Critical Bugs Fixed
...

## Authentication Fixes
...

## Appwrite Fixes
...

## Database Fixes
...

## Photo/Storage Fixes
...

## Workout Fixes
...

## Measurement/Analytics Fixes
...

## Offline/Sync Fixes
...

## UI/UX Fixes
...

## Performance Fixes
...

## Security Fixes
...

## Tests Performed
...

## Remaining Known Issues
...

## Release Build Status
...
```

Be honest about remaining problems.

Do not claim the application is "100% bug-free".

------------------------------------------------------------------------

## 41. FINAL ACCEPTANCE CRITERIA

The app is ready for release testing only when:

-   [ ] App launches without crashing
-   [ ] Authentication works
-   [ ] Session restoration works
-   [ ] Appwrite connection works
-   [ ] User profile works
-   [ ] Dashboard works
-   [ ] Progress photos work
-   [ ] Private photo permissions work
-   [ ] Photo deletion works
-   [ ] Before/after works
-   [ ] Workout CRUD works
-   [ ] Measurement CRUD works
-   [ ] Analytics works
-   [ ] Streaks work
-   [ ] Navigation works
-   [ ] Loading states work
-   [ ] Empty states work
-   [ ] Error states work
-   [ ] Offline behavior works
-   [ ] Sync queue works
-   [ ] Multi-device synchronization works
-   [ ] Realtime works if implemented
-   [ ] Duplicate actions are prevented
-   [ ] No major lifecycle/memory issues
-   [ ] No major UI overflow
-   [ ] No fake data
-   [ ] No unauthorized data access
-   [ ] No server secrets in the client
-   [ ] No functional Supabase dependency
-   [ ] `flutter analyze` passes
-   [ ] Tests pass
-   [ ] Release APK builds
-   [ ] Release APK has been manually tested

------------------------------------------------------------------------

# 42. EXECUTION ORDER

Follow this order:

``` text
1. Audit entire project
2. Run app and reproduce bugs
3. Build prioritized bug inventory
4. Fix startup and authentication
5. Fix Appwrite configuration and permissions
6. Fix database/model/repository problems
7. Fix progress photo upload/display/delete
8. Fix workouts
9. Fix measurements and analytics
10. Fix navigation/state management
11. Fix offline and multi-device synchronization
12. Fix UI/responsive issues
13. Fix lifecycle/performance issues
14. Run automated tests
15. Run complete manual QA
16. Build release APK
17. Install and test release APK
18. Search final project for obsolete backend code
19. Generate final bug-fix report
```

------------------------------------------------------------------------

# FINAL COMMAND

**DO NOT JUST MAKE THE APP COMPILE. MAKE THE APP ACTUALLY WORK.**

Inspect first. Reproduce problems. Find root causes. Fix them
systematically. Test every major workflow.

Preserve the existing FitTrack functionality and neumorphic design.

Use Appwrite correctly and securely.

Do not hide errors, use fake data, disable security, or remove features
to make the app appear stable.

Do not claim completion until the application has passed functional,
security, offline, synchronization, regression, and release-build
testing.

## FINAL GOAL

> Transform the current buggy FitTrack Flutter application into a
> stable, reliable, secure, responsive Appwrite-powered fitness tracker
> that works correctly across devices and handles real-world usage,
> network failures, invalid input, lifecycle changes, repeated actions,
> private progress photos, workouts, measurements, analytics, and
> synchronization without losing user data.
