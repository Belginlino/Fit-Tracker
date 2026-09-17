# FitTrack — UI Redesign Master Prompt

## Role

Act as a senior Flutter UI/UX designer and frontend engineer.

Redesign the existing FitTrack fitness tracker application to closely follow the **attached reference image**. The reference is the visual source of truth for the design language.

The target style is a premium **soft-neumorphic fitness app** using warm cream/beige surfaces, deep teal accents, rounded components, subtle shadows, clean typography, generous spacing, and consistent outlined iconography.

---

## 1. CRITICAL RULE — UI REDESIGN ONLY

This task is primarily a presentation-layer redesign.

**Do NOT break or remove existing functionality.**

Preserve:

- Supabase integration
- Supabase Auth
- PostgreSQL/database logic
- Supabase Storage
- Photo upload/download/delete logic
- Workout tracking
- Measurements
- Weight tracking
- Analytics calculations
- Streak calculations
- Notifications
- Existing repositories
- Existing Riverpod providers
- Existing models
- Existing business logic
- Existing routes where practical

Do not migrate the backend during this task.

If an existing feature works, keep it working and redesign only how it is presented.

Do not replace real data with fake data.

---

# 2. VISUAL SOURCE OF TRUTH

Use the supplied reference image as the primary visual reference.

Do not simply copy one or two components. Extract the complete design system from it:

- Color
- Typography
- Spacing
- Radius
- Shadows
- Elevation
- Neumorphic surfaces
- Buttons
- Inputs
- Cards
- Navigation
- Icons
- Dialogs
- Toasts
- Progress indicators
- Charts
- Photo layouts
- Empty states

The final app should feel like one cohesive design system.

---

# 3. DESIGN LANGUAGE

Target:

> **Premium Soft Neumorphism + Warm Cream/Beige + Deep Teal**

The UI should feel:

- Premium
- Calm
- Minimal
- Elegant
- Tactile
- Modern
- Personal
- Fitness-oriented
- Spacious
- Professional

Avoid:

- Generic Material UI
- Default Flutter buttons
- Harsh black shadows
- Excessive gradients
- Excessive glassmorphism
- Neon gym aesthetics
- Crowded dashboards
- Random colors
- Random border radii
- Heavy borders

---

# 4. COLOR SYSTEM

Create centralized design tokens.

Use approximately:

```text
Background       #F7F3E8
Surface          #EEE8DC
Shadow           #D1C7B7
Deep Shadow      #C4B9A8

Primary Teal     #0D5B5B
Secondary Teal   #0F3D3D
Light Teal       #DCEBE7

Primary Text     #171717
Secondary Text   #65625C
Muted Text       #89847A

White            #FFFFFF
Error            #B3261E
Success          #0D6B63
```

Tune colors slightly if necessary to visually match the reference.

Do not scatter color literals throughout the project.

Create:

```dart
AppColors.background
AppColors.surface
AppColors.primary
AppColors.secondary
AppColors.textPrimary
AppColors.textSecondary
AppColors.textMuted
AppColors.error
AppColors.success
```

---

# 5. NEUMORPHIC SYSTEM

Create reusable surface styles:

### Base

Flat cream surface.

### Raised

Soft outer shadow.

### Inset

Soft inner/depressed appearance.

### Pressed

Stronger inset appearance.

### Floating

Higher elevation with a subtle stronger shadow.

The reference uses soft depth, not heavy Material elevation.

Shadows should be:

- Diffuse
- Warm
- Subtle
- Low contrast

Avoid black or overly sharp shadows.

Create reusable helpers/tokens such as:

```dart
AppShadows.raised
AppShadows.inset
AppShadows.pressed
AppShadows.floating
```

---

# 6. RADIUS SYSTEM

Use consistent values:

```text
4px   tiny
8px   small controls
12px  inputs
16px  cards
20px  large cards
24px  major surfaces
```

Prefer 16–24px for major components.

Do not use arbitrary radii.

---

# 7. SPACING SYSTEM

Use:

```text
4
8
12
16
20
24
32
40
48
```

Recommended:

```text
Screen padding: 20–24px
Section spacing: 24px
Card padding: 16–20px
Small gaps: 8–12px
```

Use generous whitespace like the reference.

---

# 8. TYPOGRAPHY

Use a clean modern sans-serif.

Suggested hierarchy:

```text
Display        28–32px bold
Screen title   22–26px bold
Section title  16–18px semibold
Body           14–16px
Caption        11–13px
Metric         24–32px bold
```

Use deep charcoal instead of pure black where appropriate.

Numeric fitness statistics should have strong visual hierarchy.

---

# 9. ICONOGRAPHY

Use one consistent outlined icon style.

Approximate:

```text
Stroke: 2px
Small: 16px
Medium: 20px
Large: 24px
```

Recommended:

```text
Navigation: 20–24px
Buttons: 18–20px
Inline: 16–18px
Hero actions: 24px
```

Use teal for important actions/icons.

Do not randomly mix outlined and filled icons.

---

# 10. BUTTON SYSTEM

Primary button:

```text
Deep teal
White text
Rounded
Soft raised shadow
```

Pressed:

```text
Inset neumorphic appearance
```

Disabled:

```text
Muted beige/gray
Reduced contrast
```

Loading:

```text
Teal surface
Subtle spinner
"Saving..."
```

Create reusable:

```text
NeumorphicButton
PrimaryButton
SecondaryButton
IconButton
```

---

# 11. INPUT SYSTEM

Inputs should resemble the reference.

Normal:

- Cream surface
- Rounded corners
- Subtle inset effect
- Minimal border

Focused:

- Teal border/glow
- Slightly stronger inset/raised effect

Error:

- Red border
- Red helper text

Disabled:

- Muted surface

Create reusable:

```text
NeumorphicTextField
```

---

# 12. CARD SYSTEM

Create reusable cards for:

- Workout
- Weight
- Streak
- Progress photo
- Analytics
- Measurements
- Quick actions

Cards should use intentional depth:

```text
Flat
Raised
Inset
```

Do not make every card look identical.

---

# 13. HOME / DASHBOARD

Redesign Home using the reference.

Suggested hierarchy:

```text
Good Morning, [Name]
Let's continue your progress.

                         [Bell] [Avatar]

TODAY'S OVERVIEW

[ Streak ] [ Workouts ] [ Weight ]

TODAY'S GOAL

Upload your progress photo
after your workout

                         [Camera]

QUICK ACTIONS

[ Log Workout ] [ Add Photo ]
[ Add Weight  ] [ View Stats ]

THIS WEEK

M  T  W  T  F  S  S
●  ●  ○  ○  ○  ○  ○

RECENT PROGRESS

[ Photo ] [ Photo ] [ Photo ]
```

Use real application data.

Never hardcode statistics.

---

# 14. BOTTOM NAVIGATION

Use a soft neumorphic bottom navigation bar.

Recommended:

```text
Home
Progress
Workout
Stats
Profile
```

Active:

- Teal icon
- Teal label
- Subtle raised/inset surface

Inactive:

- Muted icon/text

Keep the navigation compact and elegant.

---

# 15. PROGRESS PHOTO GALLERY

Design:

```text
← Progress Photos

[ All ] [ Front ] [ Side ] [ Back ]

PHOTO GRID

┌──────────┐ ┌──────────┐
│          │ │          │
│  PHOTO   │ │  PHOTO   │
│          │ │          │
│ Sep 16   │ │ Sep 14   │
└──────────┘ └──────────┘
```

Use:

- Rounded image corners
- Soft cards
- Small metadata
- Consistent spacing

Use thumbnails for performance.

---

# 16. ADD PROGRESS PHOTO

Make this one of the most polished screens.

```text
← Add Progress Photo

╭────────────────────────────╮
│                            │
│            📷              │
│                            │
│      Take a Photo          │
│      Front, Side or Back   │
│                            │
╰────────────────────────────╯

OR

[ Choose from Gallery ]

Photo Type
[ Front ] [ Side ] [ Back ]

Weight
[ 68.5 kg ]

Notes
[ How was your workout? ]

[ Save Photo ]
```

The camera/upload action must be immediately obvious.

---

# 17. PHOTO PREVIEW

After capture:

```text
← Review Photo

┌────────────────────────────┐
│                            │
│          PHOTO             │
│                            │
└────────────────────────────┘

Pose
[ Front ]

Weight
[ 68.5 kg ]

Notes
[ Optional ]

[ Save Photo ]
```

Show:

```text
Preparing...
Uploading...
Saving...
Complete ✓
Failed → Retry
```

Do not allow accidental duplicate submissions.

---

# 18. BEFORE / AFTER COMPARISON

Create a premium comparison experience.

```text
← Compare Progress

╭────────────────────────────╮
│                            │
│      BEFORE | AFTER        │
│                            │
│          PHOTOS            │
│                            │
╰────────────────────────────╯

68.5 kg                 72.3 kg
01 Aug                  16 Sep
```

Support:

- Side-by-side
- Draggable slider

Only use real uploaded photos.

Do not manipulate body shape or fabricate transformation.

---

# 19. WORKOUT LOG

Redesign workout logging.

```text
← Log Workout

Tue, 16 Sep 2026

Workout Type

╭────────────────────────────╮
│ Chest + Triceps        ▼   │
╰────────────────────────────╯

Bench Press

Set 1     60 kg × 8
Set 2     60 kg × 7
Set 3     55 kg × 10

[ + Add Set ]

Incline DB Press

...

[ + Add Exercise ]

[ Save Workout ]
```

Use soft cards and compact controls.

---

# 20. WORKOUT DETAIL

Show:

```text
Workout name
Date
Duration
Exercises
Sets
Reps
Weight
Volume
Notes
```

Important numbers should use the teal accent.

---

# 21. ANALYTICS / STATS

Create a premium statistics dashboard.

```text
← My Progress

[ Weight ] [ Measurements ] [ Workouts ]

Weight

          ●
       ●     ●
    ●
 ●

Jul   Aug   Sep

[1M] [3M] [6M] [1Y] [ALL]

[ Workout Consistency ]
86%

[ Photo Streak ]
24 Days
```

Use soft chart containers.

Use teal as the primary chart color.

Do not use excessive colors.

Do not show misleading trends.

---

# 22. MEASUREMENTS

Use clean soft forms:

```text
Body Measurements

Weight
[ 68.5 kg ]

Chest
[ -- cm ]

Waist
[ -- cm ]

Arms
[ -- cm ]

Thighs
[ -- cm ]

[ Save Measurements ]
```

Show history using cards and charts.

---

# 23. PROFILE / SETTINGS

Follow the reference.

```text
Profile                         ⚙

            [ Avatar ]

          [Name]
          [Email]

Edit Profile                 >
Goals                        >
Reminders                    >
Data Export                  >
Privacy                      >
Appearance                   >

Sign Out
```

Use icon + title + chevron rows.

---

# 24. ONBOARDING

Create a minimal onboarding experience.

```text
        [ Fitness Illustration ]

          Track Your Progress

      Take photos, log workouts,
      and monitor your transformation.

             ● ○ ○ ○

             [ Next ]
```

Use soft raised illustration cards.

Do not overload the user with text.

---

# 25. LOGIN / REGISTER

Match the reference.

```text
Welcome Back

Sign in to continue your journey.

[ Email Address ]
[ Password ]

Forgot Password?

[ Sign In ]

or continue with

[ Google ] [ Apple ]

Don't have an account?
Sign Up
```

Use neumorphic inputs and teal primary buttons.

---

# 26. SPLASH

Simple and premium:

```text
        ╭──────────╮
        │    🏋    │
        ╰──────────╯

          FitTrack

   Track Today.
   A Better You Tomorrow.
```

Use subtle animation.

Keep splash short.

---

# 27. EMPTY STATES

Example:

```text
        [ Soft Photo Icon ]

    No Progress Photos

Take your first photo after
your next workout.

     [ Take Photo ]
```

Use muted beige illustrations and teal action buttons.

---

# 28. TOASTS

Create floating soft toast cards.

Success:

```text
✓ Photo uploaded successfully
```

Info:

```text
ⓘ Workout saved
```

Error:

```text
! Upload failed
```

Use rounded surfaces and subtle shadows.

---

# 29. DIALOGS

Customize dialogs instead of using default AlertDialog styling.

Example:

```text
╭────────────────────────────╮
│                            │
│       Delete Photo?        │
│                            │
│   This cannot be undone.   │
│                            │
│ [ Cancel ]    [ Delete ]   │
╰────────────────────────────╯
```

---

# 30. LOADING

Use:

- Soft spinner
- Skeleton cards
- Skeleton rows
- Upload progress
- Subtle shimmer only where appropriate

Skeletons should use cream/beige tones.

---

# 31. SWITCHES / CHECKBOXES / SLIDERS

Customize all controls to match the reference.

Active:

```text
Teal
```

Inactive:

```text
Cream / muted
```

Use soft inset/raised effects.

---

# 32. DARK MODE

If dark mode already exists, preserve it.

Create a dark neumorphic variant rather than simply inverting the light theme.

Suggested direction:

```text
Background: #182020
Surface:    #202B2B
Primary:    #3BA6A1
Text:       #F4F1E8
```

The warm cream light theme remains the primary/default experience.

---

# 33. REUSABLE COMPONENTS

Create a reusable design system.

Recommended widgets:

```text
NeumorphicCard
NeumorphicButton
NeumorphicIconButton
NeumorphicTextField
NeumorphicSwitch
NeumorphicCheckbox
NeumorphicRadio
MetricCard
ProgressPhotoCard
WorkoutCard
SectionHeader
SoftBottomNavigation
ProgressChartCard
EmptyState
SoftDialog
SoftToast
LoadingState
SkeletonCard
```

Do not duplicate styling logic across screens.

---

# 34. THEME ARCHITECTURE

Create:

```text
AppTheme
AppColors
AppTypography
AppSpacing
AppRadius
AppShadows
```

Example:

```dart
AppSpacing.md
AppRadius.card
AppShadows.raised
AppShadows.inset
```

The entire UI should be adjustable from centralized tokens.

---

# 35. ANIMATIONS

Use subtle animations:

- Page transitions
- Button press
- Tab selection
- Card appearance
- Photo upload
- Chart entrance
- Dialog entrance

Typical duration:

```text
150–300ms
```

Do not over-animate.

The app should feel calm.

---

# 36. RESPONSIVE DESIGN

Support:

- Small phones
- Large phones
- Tablets
- Laptop/web if already supported

Do not hardcode screen dimensions.

Use:

```text
SafeArea
LayoutBuilder
MediaQuery
Flexible
Expanded
ConstrainedBox
```

Make photo grids responsive.

---

# 37. ACCESSIBILITY

Maintain:

- Good contrast
- Semantic labels
- Accessible touch targets
- Screen reader support
- Scalable text
- Status indicators that do not rely only on color

Neumorphism must not reduce usability.

---

# 38. PERFORMANCE

Do not sacrifice performance for appearance.

Requirements:

- Lazy-load photos
- Use thumbnails
- Cache images
- Avoid unnecessary rebuilds
- Dispose camera controllers
- Avoid expensive blur everywhere
- Avoid huge shadows on large lists
- Keep animations smooth

---

# 39. REAL DATA ONLY

Do not replace real backend values with mock data.

For example, do not hardcode:

```text
68.5 kg
24 workouts
86% consistency
```

unless those are explicitly configured demo values.

All displayed metrics should come from the existing data layer.

---

# 40. PRESERVE ALL FEATURES

Do not remove:

```text
Authentication
Workout tracking
Progress photos
Measurements
Weight tracking
Analytics
Streaks
Reminders
Profile
Settings
```

If the existing application has additional features, preserve them too.

Redesign presentation instead of deleting functionality.

---

# 41. IMPLEMENTATION PROCESS

## Step 1 — Inspect

Before coding, inspect:

```text
lib/
pubspec.yaml
theme
routes
screens
providers
repositories
models
```

Understand the existing architecture.

## Step 2 — Create Design System

Implement:

```text
colors
typography
spacing
radius
shadows
buttons
cards
inputs
icons
navigation
```

## Step 3 — Redesign Core Screens

Start with:

```text
Splash
Login
Register
Onboarding
Home
```

## Step 4 — Redesign Fitness Screens

Then:

```text
Progress
Add Photo
Photo Detail
Compare
Workout
Workout Detail
Measurements
Analytics
```

## Step 5 — Redesign Profile

Implement:

```text
Profile
Settings
Privacy
Notifications
Data Export
```

## Step 6 — Polish

Add:

```text
animations
loading
empty states
error states
toasts
dialogs
responsive layouts
```

## Step 7 — Verify

Run:

```bash
flutter analyze
flutter test
flutter build
```

Fix errors introduced by the redesign.

---

# 42. IMPORTANT: DO NOT OVERWRITE FUNCTIONAL LOGIC

When modifying a screen:

1. Read the existing screen.
2. Identify its state/providers.
3. Identify its callbacks.
4. Identify navigation.
5. Identify data dependencies.
6. Preserve them.
7. Replace only the visual structure where possible.

Do not rewrite a working feature just because its UI is being redesigned.

---

# 43. ACCEPTANCE CRITERIA

## Visual

The final app must:

- Clearly resemble the supplied reference.
- Use warm cream/beige as the main light background.
- Use deep teal as the primary accent.
- Use soft neumorphic surfaces.
- Use subtle warm shadows.
- Use rounded cards.
- Use consistent typography.
- Use consistent outlined icons.
- Use generous spacing.
- Have a cohesive design system.

## Functional

Verify:

```text
Login
Register
Logout
Photo upload
Photo viewing
Photo deletion
Workout logging
Measurements
Weight
Analytics
Before/after
Reminders
Profile/settings
```

All existing features must continue working.

## Technical

Verify:

```text
No broken routes
No fake data
No duplicated styling systems
No unnecessary backend changes
No new compile errors
No unnecessary packages
No broken Supabase operations
```

---

# 44. FINAL DESIGN TARGET

The finished app should visually communicate:

```text
                    FITTRACK

          Calm + Premium + Personal

       Warm Cream Background
                 +
          Soft Neumorphism
                 +
           Deep Teal Accent
                 +
          Fitness Analytics
                 +
        Progress Photography
```

The most important action hierarchy is:

```text
Finish Gym
    ↓
Open FitTrack
    ↓
Take Progress Photo
    ↓
Save
    ↓
Track Progress
```

The application should feel premium, tactile, minimal, personal, and trustworthy.

---

# 45. FINAL INSTRUCTION TO THE CODING AGENT

Use the attached reference image as the **visual source of truth**.

Do not merely copy individual components. Reconstruct the visual language and apply it consistently across the entire existing FitTrack application.

**Preserve the existing Supabase/backend functionality.**

Do not change the backend as part of this UI task.

Do not fabricate data.

Do not remove features.

Do not introduce a second unrelated design system.

Build reusable Flutter components and centralized theme tokens so the entire application consistently follows the reference.

The final result should look like a professionally designed fitness product.

> **Redesign the UI completely, but do not break the app.**
