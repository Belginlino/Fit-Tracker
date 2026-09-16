# Personalized Fitness Tracker --- Master Build Prompt

## 1. Role

You are a senior Flutter architect, UI/UX designer, Firebase engineer,
mobile security engineer, and product engineer.

Build a production-quality **personalized fitness tracking mobile app**
called **FitTrack** (name can be changed later).

The app is primarily a **personal fitness journal and visual progress
tracker**. Its core experience is:

> **Workout → Take progress photo → Record workout/body data → Save →
> Track progress over time → Compare transformation**

The application must feel like a polished real product, not a demo or
college prototype.

------------------------------------------------------------------------

# 2. Primary Goal

Create a Flutter application that allows a user to:

1.  Create/sign into a private account.
2.  Record workouts.
3.  Upload or capture daily post-workout progress photos.
4.  Store photos securely in Firebase Storage.
5.  Store workout and progress metadata in Cloud Firestore.
6.  Track body weight and measurements over time.
7.  View a chronological fitness timeline.
8.  View progress through calendars and charts.
9.  Compare older and newer progress photos.
10. Maintain workout/photo consistency streaks.
11. Receive reminders to record progress.
12. Protect highly personal fitness photos and data.
13. Eventually support AI-assisted visual progress insights.

The MVP must work completely without AI. AI should be designed as a
future-ready module rather than making the core application dependent on
it.

------------------------------------------------------------------------

# 3. Technology Stack

Use:

-   **Flutter**
-   **Dart**
-   **Firebase Authentication**
-   **Cloud Firestore**
-   **Firebase Storage**
-   **Firebase Cloud Messaging** where appropriate
-   **Local notifications** for workout/progress reminders
-   **Riverpod** for state management
-   **go_router** for navigation
-   **camera** for camera functionality
-   **image_picker** for gallery selection
-   **fl_chart** for charts
-   Use current stable package versions compatible with the selected
    Flutter version.

Before implementing dependencies, verify compatibility and avoid
deprecated APIs.

Do not introduce unnecessary backend technologies.

------------------------------------------------------------------------

# 4. Architecture

Use a clean, scalable architecture.

Recommended structure:

``` text
lib/
├── main.dart
├── app/
│   ├── app.dart
│   ├── router.dart
│   └── theme/
│       ├── app_theme.dart
│       ├── app_colors.dart
│       └── app_typography.dart
│
├── core/
│   ├── constants/
│   ├── errors/
│   ├── extensions/
│   ├── utils/
│   ├── services/
│   └── widgets/
│
├── features/
│   ├── auth/
│   │   ├── data/
│   │   ├── domain/
│   │   └── presentation/
│   │
│   ├── dashboard/
│   ├── progress_photos/
│   ├── workouts/
│   ├── measurements/
│   ├── analytics/
│   ├── reminders/
│   ├── profile/
│   └── settings/
│
└── firebase/
    └── generated/config files as required
```

Use separation between:

-   Presentation
-   Business/domain logic
-   Firebase/data access
-   Shared services

Do not put Firebase queries directly inside UI widgets.

------------------------------------------------------------------------

# 5. Design Direction

The app should have a premium modern fitness aesthetic.

Design principles:

-   Minimal
-   Clean
-   Strong typography
-   High readability
-   Professional dashboard
-   Dark mode as the primary experience
-   Light mode support if practical
-   Smooth animations
-   Rounded cards
-   Subtle gradients where useful
-   Clear visual hierarchy
-   Avoid excessive decorative elements
-   Avoid clutter

The UI should feel closer to a premium fitness/wellness product than a
generic CRUD application.

Use consistent:

-   spacing
-   corner radius
-   typography
-   iconography
-   button styles
-   cards
-   charts
-   empty states
-   loading states
-   error states

Do not use random colors on individual screens. Define a centralized
design system.

------------------------------------------------------------------------

# 6. Main Navigation

Use a bottom navigation structure such as:

``` text
Home
Progress
Workout
Analytics
Profile
```

The primary action should always be easy to reach.

Consider a prominent floating action button or central action for:

> **+ Log Workout / Progress**

------------------------------------------------------------------------

# 7. Authentication

Implement Firebase Authentication.

Support:

-   Email/password sign-up
-   Email/password login
-   Logout
-   Password reset
-   Auth persistence
-   Proper loading states
-   Validation
-   Error handling

Optional future support:

-   Google Sign-In
-   Apple Sign-In

Do not require social login for MVP.

After registration, show a short onboarding flow.

------------------------------------------------------------------------

# 8. Onboarding

Create a concise onboarding flow.

Collect only information useful for personalization:

-   Name
-   Goal
-   Current weight
-   Height
-   Target weight
-   Preferred workout days
-   Preferred reminder time
-   Optional fitness level

Possible goals:

``` text
Build Muscle
Lose Fat
Improve Strength
Maintain Fitness
General Fitness
```

Do not make medical claims or diagnose users.

Allow users to skip optional information.

------------------------------------------------------------------------

# 9. Home Dashboard

The home screen should immediately communicate the user's current
progress.

Suggested layout:

``` text
Good evening, Belgin

Your Progress
────────────────────

Weight
74.2 kg
↓ / ↑ trend

Workout Streak
12 days

Photo Streak
8 days

────────────────────

Today's Workout
Chest + Triceps

[ Start Workout ]

────────────────────

Today's Progress
[ Take Photo ]

────────────────────

Recent Progress
[ photo ] [ photo ] [ photo ]

────────────────────

Quick Stats
Weight | Workouts | Photos
```

The exact name must come from the user's account rather than hardcoding
it.

Dashboard should adapt based on available data.

If the user has no data yet, show a useful onboarding/empty state
instead of broken charts.

------------------------------------------------------------------------

# 10. Daily Progress Photo

This is the most important feature.

The user should be able to:

-   Take a photo using the camera
-   Choose a photo from gallery
-   Preview it
-   Crop it if necessary
-   Retake/change it
-   Add metadata
-   Save it securely

Metadata:

``` text
photoId
userId
storagePath
downloadUrl/reference
createdAt
workoutId
pose
weightAtCapture
notes
```

Supported poses:

``` text
Front
Side
Back
Free/Other
```

The UI should encourage standardized photos.

------------------------------------------------------------------------

# 11. Same-Pose Camera Mode

Implement the app architecture so a future/initial version can support a
standardized camera experience.

When taking a progress photo:

-   Show a subtle body-position guide/overlay.
-   Encourage consistent distance.
-   Encourage consistent camera angle.
-   Encourage similar lighting.
-   Show previous photo as an optional low-opacity alignment reference
    where privacy and performance permit.

The goal is to make progress comparisons visually meaningful.

Do not perform misleading body transformation manipulation.

Never alter the user's body or fabricate progress.

------------------------------------------------------------------------

# 12. Photo Processing

Before upload:

-   Compress large images appropriately.
-   Preserve sufficient quality.
-   Correct orientation.
-   Generate thumbnails where useful.
-   Avoid excessive file sizes.
-   Do not permanently alter the original unless the user chooses to.
-   Handle failed uploads gracefully.
-   Show upload progress.

Recommended storage organization:

``` text
users/{userId}/progress_photos/{photoId}/original
users/{userId}/progress_photos/{photoId}/thumbnail
```

Use private Storage rules.

Never make personal progress photos publicly accessible.

------------------------------------------------------------------------

# 13. Progress Timeline

Create a beautiful chronological timeline.

Example:

``` text
September 15

📸 Progress Photo
🏋️ Chest + Triceps
⚖️ 74.2 kg

"Felt stronger today."

────────────────

September 14

🏋️ Back + Biceps
⚖️ 74.0 kg
```

Allow filtering by:

-   Date
-   Workout
-   Pose
-   Weight range

Tapping an entry opens its full details.

------------------------------------------------------------------------

# 14. Progress Calendar

Create a monthly calendar.

Display indicators for:

-   Photo uploaded
-   Workout completed
-   Both completed

Tapping a date shows the day's records.

Use visual indicators instead of overwhelming the calendar with text.

Include:

-   Current month
-   Previous/next month
-   Jump to today
-   Date details

------------------------------------------------------------------------

# 15. Before/After Comparison

This is one of the flagship features.

Allow users to select:

``` text
Start Date
End Date
Pose
```

Then support:

### Side-by-side

``` text
BEFORE             AFTER

  PHOTO              PHOTO
```

### Slider comparison

A draggable divider:

``` text
BEFORE | AFTER
       ↔
```

### Metadata comparison

``` text
Weight
68.5 kg → 74.2 kg

Chest
...

Waist
...

Workout consistency
...
```

Do not automatically claim that changes are caused by the app or that a
specific body composition change occurred unless supported by actual
measurements.

------------------------------------------------------------------------

# 16. Body Measurements

Allow users to optionally record:

-   Weight
-   Chest
-   Waist
-   Hips
-   Left arm
-   Right arm
-   Left thigh
-   Right thigh
-   Shoulders
-   Body-fat percentage if the user has a reliable measurement source

Each measurement should include:

``` text
value
unit
date
optional note
```

Support metric units primarily:

-   kg
-   cm

Architect the unit system so imperial units can be added later.

------------------------------------------------------------------------

# 17. Weight Tracking

Create a dedicated weight screen.

Features:

-   Add weight
-   Edit entry
-   Delete entry
-   View history
-   Trend chart
-   Weekly/monthly/custom range
-   Start/current/target weight

Do not imply that short-term fluctuations are automatically fat
gain/loss.

Show neutral language such as:

> "Weight trend"

rather than making health conclusions.

------------------------------------------------------------------------

# 18. Workout Tracker

Implement workout logging.

Workout structure:

``` text
Workout
├── Date
├── Duration
├── Workout type
├── Exercises
│   ├── Exercise name
│   ├── Sets
│   ├── Reps
│   ├── Weight
│   └── Notes
└── General notes
```

Example:

``` text
Chest + Triceps

Bench Press
60 kg × 8
60 kg × 7
55 kg × 10

Incline Dumbbell Press
20 kg × 10
20 kg × 8

Tricep Pushdown
25 kg × 12
25 kg × 10
```

Allow:

-   Add exercise
-   Add set
-   Edit set
-   Delete set
-   Duplicate previous workout
-   Save workout
-   View history

------------------------------------------------------------------------

# 19. Workout Templates

Allow users to create reusable workout templates.

Examples:

``` text
Push
Pull
Legs
Upper Body
Lower Body
Chest + Triceps
Back + Biceps
Custom
```

The user should be able to create their own template.

------------------------------------------------------------------------

# 20. Personal Records

Track useful strength milestones.

Examples:

``` text
Bench Press
Previous best: 60 kg
New best: 65 kg

Squat
Previous best: 100 kg
New best: 105 kg
```

Define a personal record carefully based on actual recorded workout
data.

Do not invent values.

------------------------------------------------------------------------

# 21. Analytics Dashboard

Create a dedicated analytics screen.

Show:

### Workout analytics

-   Workouts completed
-   Workout frequency
-   Weekly consistency
-   Workout duration

### Strength analytics

-   Exercise progression
-   Personal records
-   Volume trends

### Body analytics

-   Weight trend
-   Measurement trends
-   Target progress

### Photo analytics

-   Photos uploaded
-   Photo streak
-   Comparison history

Use clean charts with selectable time ranges:

``` text
7D
30D
3M
6M
1Y
ALL
```

Avoid misleading charts. Clearly label units and ranges.

------------------------------------------------------------------------

# 22. Progress Score

Create an optional personal consistency score.

Example:

``` text
YOUR CONSISTENCY

        86 / 100

Workout consistency   90%
Photo consistency     82%
Measurement tracking  76%
```

This is a motivational product metric, NOT a medical or scientifically
validated fitness score.

Clearly communicate that.

------------------------------------------------------------------------

# 23. Streak System

Track:

-   Workout streak
-   Photo streak
-   Logging streak

Do not encourage unhealthy behavior such as exercising through injury.

If a user misses a day, use neutral language:

> "Welcome back. Let's continue your journey."

Never shame the user.

------------------------------------------------------------------------

# 24. Reminders

Support reminders for:

-   Workout
-   Progress photo
-   Weight logging
-   Weekly progress review

Allow:

-   Enable/disable
-   Time selection
-   Day selection
-   Notification permission handling

Use local notifications for personal recurring reminders where possible.

Do not send unnecessary notifications.

------------------------------------------------------------------------

# 25. Weekly Progress Summary

Create a weekly summary screen.

Example:

``` text
THIS WEEK

5 Workouts
4 Progress Photos
+2.1 kg total lifted-volume trend
74.2 kg current weight

Best Workout
Chest + Triceps

Personal Record
Bench Press — 65 kg

Your Note
"Energy was better this week."
```

Only calculate metrics from actual stored data.

------------------------------------------------------------------------

# 26. AI Module --- Future Ready

Design the architecture for a future AI feature.

Potential future capabilities:

-   Visual progress observations
-   Photo consistency checks
-   Workout summaries
-   Natural-language progress summaries
-   Personalized trend explanations
-   Workout suggestions

AI output must be clearly framed as an estimate/observation when
appropriate.

Do NOT allow AI to:

-   Diagnose medical conditions
-   Claim exact body-fat percentage from ordinary photos
-   Make medical diagnoses
-   Guarantee physical outcomes
-   Encourage dangerous dieting or exercise
-   Replace a qualified professional

The MVP should function without any AI API.

Create an interface/service abstraction so an AI provider can be added
later without rewriting the UI.

Example concept:

``` text
ProgressInsightService
        │
        ├── LocalProgressInsightService
        └── FutureAIProgressInsightService
```

------------------------------------------------------------------------

# 27. Firebase Firestore Data Model

Use a user-scoped data model.

Suggested structure:

``` text
users/{userId}
    profile fields

users/{userId}/progressPhotos/{photoId}
    storagePath
    thumbnailPath
    createdAt
    pose
    workoutId
    weightAtCapture
    notes

users/{userId}/workouts/{workoutId}
    date
    type
    duration
    notes
    exercises

users/{userId}/workouts/{workoutId}/sets/{setId}
    exerciseName
    setNumber
    weight
    reps
    createdAt

users/{userId}/measurements/{measurementId}
    type
    value
    unit
    recordedAt

users/{userId}/settings/preferences
    reminderSettings
    units
    theme
```

Use timestamps rather than relying on client-generated strings.

Add indexes only when required by actual queries.

Avoid unnecessary duplication of large data.

------------------------------------------------------------------------

# 28. Firebase Storage Security

This is critical.

Rules must ensure:

``` text
Authenticated user
    ↓
can read/write
    ↓
ONLY /users/{theirOwnUid}/...
```

A user must never be able to access another user's photos or records by
changing an ID.

Validate:

-   Authentication
-   UID ownership
-   File type
-   Reasonable file size
-   Storage path ownership

Do not expose unrestricted read/write rules.

Never use development rules such as:

``` text
allow read, write: if true;
```

in the production configuration.

------------------------------------------------------------------------

# 29. Firestore Security

Implement user ownership checks.

Conceptually:

``` text
request.auth.uid == userId
```

for user-scoped resources.

Prevent:

-   Cross-user reads
-   Cross-user writes
-   Unauthorized deletes
-   Unauthorized updates

Use Firebase Emulator Suite where practical to test security rules.

------------------------------------------------------------------------

# 30. Privacy

Because this app stores personal body/progress photos:

-   Keep photos private.
-   Provide delete controls.
-   Provide account deletion.
-   Explain what data is stored.
-   Do not upload photos to external AI services without explicit user
    consent.
-   Do not use user photos for training.
-   Do not expose photos through public URLs.
-   Minimize collected data.
-   Do not collect unrelated personal information.

Add a clear privacy/settings section.

------------------------------------------------------------------------

# 31. Profile

Profile screen should include:

``` text
Profile Photo
Name
Goal
Current Weight
Target Weight
Height

Progress Overview
Workouts
Photos
Current Streak

Settings
Notifications
Units
Theme
Privacy
Export Data
Delete Account
Logout
```

------------------------------------------------------------------------

# 32. Export and Delete

Implement data-management architecture.

Allow:

-   Delete individual photo
-   Delete workout
-   Delete measurement
-   Delete account

Account deletion should remove/handle associated:

-   Firestore records
-   Firebase Storage photos
-   Authentication account

Handle failures safely and explain incomplete deletion if a backend
operation fails.

Where practical, support exporting user data in a structured format.

------------------------------------------------------------------------

# 33. Loading, Empty, Error States

Every major screen must have proper states.

### Loading

Use skeletons/progress indicators.

### Empty

Example:

> No progress photos yet\
> Take your first photo after your next workout.

### Error

Use friendly actionable messages.

Example:

> Couldn't upload your photo. Check your connection and try again.

Do not silently fail.

------------------------------------------------------------------------

# 34. Offline Handling

Design for temporary connectivity loss.

At minimum:

-   Cache appropriate Firestore data.
-   Clearly show upload failure/pending state.
-   Do not lose workout input if connectivity drops.
-   Retry failed uploads safely.

If implementing an offline queue, ensure duplicate uploads are
prevented.

------------------------------------------------------------------------

# 35. Image UX

For progress photos:

-   Full-screen viewer
-   Pinch-to-zoom
-   Swipe where appropriate
-   Thumbnail generation
-   Upload progress
-   Delete confirmation
-   Metadata display
-   Before/after selection

Do not automatically apply beautification/body-shaping filters.

The purpose is authentic progress tracking.

------------------------------------------------------------------------

# 36. Accessibility

Support:

-   Semantic labels
-   Adequate contrast
-   Large text where possible
-   Touch targets of appropriate size
-   Screen-reader-friendly controls
-   Avoid conveying information through color alone

------------------------------------------------------------------------

# 37. Performance

Optimize for mobile.

Requirements:

-   Lazy-load photo grids
-   Use thumbnails
-   Avoid loading full-resolution images unnecessarily
-   Paginate long timelines
-   Avoid unnecessary Firestore reads
-   Dispose controllers correctly
-   Avoid memory leaks
-   Keep animations smooth
-   Avoid rebuilding entire screens unnecessarily

------------------------------------------------------------------------

# 38. Error Handling

Create centralized error handling for:

-   Authentication
-   Firestore
-   Storage
-   Camera permission
-   Gallery permission
-   Notification permission
-   Network errors

Show user-friendly messages while keeping technical details in logs.

Never expose secrets or Firebase configuration credentials that should
not be exposed.

------------------------------------------------------------------------

# 39. App State

Use Riverpod consistently.

Separate:

``` text
UI state
Domain state
Remote data
Local state
```

Avoid mixing business logic inside widgets.

Providers should be small and purpose-driven.

------------------------------------------------------------------------

# 40. Navigation

Use go_router.

Routes should include concepts such as:

``` text
/login
/register
/onboarding
/home
/progress
/progress/photo/:id
/progress/compare
/workouts
/workouts/new
/workouts/:id
/analytics
/profile
/settings
```

Protect authenticated routes.

Unauthenticated users should not access private screens.

------------------------------------------------------------------------

# 41. Reusable Components

Create reusable widgets for:

-   Metric cards
-   Progress cards
-   Photo cards
-   Workout cards
-   Empty states
-   Loading states
-   Primary buttons
-   Secondary buttons
-   Section headers
-   Chart containers
-   Date selectors
-   Bottom sheets
-   Confirmation dialogs

Do not duplicate UI code unnecessarily.

------------------------------------------------------------------------

# 42. Data Validation

Validate:

-   Weight
-   Measurements
-   Reps
-   Sets
-   Exercise names
-   Dates
-   Required profile fields

Prevent:

-   Negative values where invalid
-   Impossible/obviously erroneous values
-   Empty required fields
-   Duplicate records where inappropriate

Do not over-restrict legitimate user input.

------------------------------------------------------------------------

# 43. Date and Time

Store timestamps in a robust format.

Display dates using the user's local timezone.

Avoid string-based date comparisons.

Handle:

-   Today
-   Yesterday
-   Week
-   Month
-   Year
-   Custom date ranges

correctly.

------------------------------------------------------------------------

# 44. Security

Never hardcode:

-   API secrets
-   private keys
-   service account credentials
-   server credentials

Firebase client configuration values that are designed to be public can
be included normally, but actual access control must come from Firebase
Authentication and security rules.

Use secure backend rules rather than relying on Flutter UI restrictions.

------------------------------------------------------------------------

# 45. UI Details

Home screen should have a strong visual hierarchy.

Suggested sections:

``` text
Greeting
↓
Today's status
↓
Progress stats
↓
Today's workout
↓
Take progress photo CTA
↓
Recent photos
↓
Weekly progress
```

Progress screen:

``` text
Progress header
↓
Calendar
↓
Photo timeline
↓
Before/After
```

Workout screen:

``` text
Today's workout
↓
Workout templates
↓
Exercise list
↓
Set logging
↓
Finish workout
↓
Post-workout photo CTA
```

Analytics:

``` text
Summary cards
↓
Weight chart
↓
Workout chart
↓
Strength chart
↓
Photo consistency
```

------------------------------------------------------------------------

# 46. Post-Workout Flow

Make this extremely fast.

Ideal flow:

``` text
Finish Workout
      ↓
"Great workout!"
      ↓
"Add today's progress photo?"
      ↓
Camera
      ↓
Preview
      ↓
Weight (optional)
      ↓
Note (optional)
      ↓
SAVE
      ↓
Progress recorded ✓
```

Target the core photo logging action to take roughly 10--20 seconds.

------------------------------------------------------------------------

# 47. Gamification

Use subtle motivation:

-   Streaks
-   Milestones
-   Personal records
-   Weekly summaries
-   Consistency badges

Avoid unhealthy gamification.

Never reward:

-   Excessive workouts
-   Severe calorie restriction
-   Skipping recovery
-   Extreme weight loss

The app should promote sustainable consistency.

------------------------------------------------------------------------

# 48. Testing

Implement tests for:

### Unit tests

-   Progress calculations
-   Streak calculations
-   Weight trends
-   Personal record calculations
-   Date handling
-   Validation

### Widget tests

-   Dashboard
-   Photo upload flow
-   Workout logging
-   Charts
-   Empty states

### Integration tests

-   Authentication
-   Photo upload
-   Workout creation
-   Data retrieval
-   Delete flows

### Firebase rules tests

Test that:

-   User A cannot access User B's data.
-   Unauthenticated users cannot access private data.
-   User can manage only their own records.

------------------------------------------------------------------------

# 49. Firebase Emulator

During development, prefer Firebase Emulator Suite for testing where
possible.

Document how to run:

``` text
Firebase Auth Emulator
Firestore Emulator
Storage Emulator
```

Do not use production data while testing destructive operations.

------------------------------------------------------------------------

# 50. Environment Configuration

Support environment-specific configuration:

``` text
development
staging
production
```

Do not commit sensitive credentials.

Provide a clear setup guide.

------------------------------------------------------------------------

# 51. README

Create a comprehensive README containing:

-   Project overview
-   Features
-   Architecture
-   Tech stack
-   Firebase setup
-   Flutter setup
-   Environment setup
-   Running the project
-   Firebase rules deployment
-   Emulator usage
-   Testing
-   Build instructions
-   Known limitations
-   Future roadmap

------------------------------------------------------------------------

# 52. Seed/Demo Data

Provide optional demo data for development.

Demo data should be clearly separated from real user data.

Include:

-   Sample workouts
-   Sample measurements
-   Sample progress metadata

Do not use real people's body photos as seed data.

If image placeholders are needed, use generated/local placeholder
assets.

------------------------------------------------------------------------

# 53. Future Features

Design the architecture so these can be added later:

``` text
AI Progress Insights
AI Workout Suggestions
Wearable Integration
Apple Health
Google Health Connect
Nutrition Tracking
Water Tracking
Sleep Tracking
Advanced Photo Alignment
Pose Consistency Detection
Cloud Backup
Data Export
Multi-device Sync
Progress Reports
PDF Progress Report
```

Do not implement all future features in the MVP.

------------------------------------------------------------------------

# 54. MVP Priority

Build in this order:

## P0 --- Essential

1.  Authentication
2.  Onboarding
3.  Home dashboard
4.  Camera/gallery
5.  Progress photo upload
6.  Firebase Storage
7.  Firestore metadata
8.  Progress timeline
9.  Workout logging
10. Weight tracking
11. Before/after comparison
12. Security rules

## P1 --- Important

13. Calendar
14. Measurements
15. Analytics
16. Streaks
17. Reminders
18. Workout templates
19. Personal records
20. Weekly summary

## P2 --- Advanced

21. Same-pose camera
22. Advanced photo alignment
23. AI progress insights
24. Wearable integrations
25. Advanced reports

------------------------------------------------------------------------

# 55. Product Quality Requirements

Do NOT build a simplistic CRUD application.

The finished app should have:

-   Production-quality UI
-   Consistent design system
-   Robust navigation
-   Real Firebase integration
-   Secure data access
-   Proper validation
-   Good error handling
-   Responsive layouts
-   Smooth photo experience
-   Good performance
-   Meaningful empty states
-   Useful analytics
-   Maintainable architecture

Do not create fake buttons that do nothing.

Do not create fake Firebase functionality.

Do not use hardcoded progress statistics when actual user data is
available.

Do not fabricate AI results.

------------------------------------------------------------------------

# 56. Important Development Rule

Before writing code:

1.  Inspect the existing project structure if a project already exists.
2.  Identify the current Flutter version.
3.  Identify existing dependencies.
4.  Preserve working functionality.
5.  Avoid unnecessary rewrites.
6.  Plan the architecture before implementation.
7.  Check package compatibility.
8.  Check Firebase configuration.
9.  Implement incrementally.
10. Test every major feature after implementation.

If an existing UI/template exists, preserve its useful visual identity
unless there is a clear reason to improve it.

------------------------------------------------------------------------

# 57. Implementation Strategy

Build the application in vertical slices rather than creating hundreds
of disconnected files.

Recommended sequence:

``` text
STEP 1
Project foundation
Theme
Routing
Riverpod
Firebase initialization

STEP 2
Authentication
Onboarding

STEP 3
Dashboard

STEP 4
Progress photo capture/upload
Firebase Storage
Firestore

STEP 5
Progress timeline
Calendar

STEP 6
Workout logging

STEP 7
Weight + measurements

STEP 8
Before/after comparison

STEP 9
Analytics

STEP 10
Reminders + streaks

STEP 11
Security hardening

STEP 12
Testing + performance

STEP 13
AI-ready service abstraction
```

At every stage:

-   Run the app.
-   Fix compile errors immediately.
-   Test the feature.
-   Avoid accumulating broken code.
-   Keep the project runnable.

------------------------------------------------------------------------

# 58. Acceptance Criteria

The MVP is considered successful only if a real user can complete this
entire journey:

``` text
Install app
   ↓
Create account
   ↓
Complete onboarding
   ↓
Open dashboard
   ↓
Start workout
   ↓
Add exercises
   ↓
Add sets/reps/weight
   ↓
Finish workout
   ↓
Take progress photo
   ↓
Save photo
   ↓
Photo uploads securely
   ↓
Workout + photo appear in timeline
   ↓
Record weight
   ↓
View weight trend
   ↓
Return another day
   ↓
Add another photo
   ↓
Open Progress
   ↓
Select two photos
   ↓
Compare Before vs After
```

Every step must actually work.

------------------------------------------------------------------------

# 59. Final UX Principle

The app should answer these questions immediately:

### "What did I do today?"

→ Workout history

### "Am I being consistent?"

→ Streaks + analytics

### "How is my body changing?"

→ Photos + measurements

### "Am I getting stronger?"

→ Exercise progression + PRs

### "How did I look before?"

→ Before/after comparison

### "What should I do next?"

→ Workout plan/reminder infrastructure, with AI recommendations only as
a future enhancement.

------------------------------------------------------------------------

# 60. Final Instruction

Build this as a **real, scalable personal fitness product**, not merely
a collection of screens.

Prioritize:

**Privacy → Reliability → Core tracking → Excellent photo UX → Useful
analytics → Visual progress → Advanced intelligence**

The most important feature is not the number of features.

It is making the daily habit effortless:

> **Finish gym → open app → take photo → save → see progress over
> time.**

Every technical and UX decision should support that habit.
