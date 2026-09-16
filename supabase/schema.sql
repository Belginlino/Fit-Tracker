-- ==============================================================================
-- FitTrack: Complete Supabase PostgreSQL Schema, RLS, Triggers & Storage Setup
-- Reference: supabase-migration-plan.md
-- ==============================================================================

-- Enable UUID extension
create extension if not exists "uuid-ossp";

-- ==============================================================================
-- 1. PROFILES TABLE (Linked to auth.users)
-- ==============================================================================
create table if not exists public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  name text,
  goal text default 'Build Muscle',
  height numeric default 178.0,
  current_weight numeric default 74.2,
  target_weight numeric default 78.0,
  fitness_level text default 'Intermediate',
  preferred_reminder_time time default '18:30:00',
  workout_streak integer default 0,
  photo_streak integer default 0,
  has_completed_onboarding boolean default false,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

-- ==============================================================================
-- 2. USER SETTINGS TABLE
-- ==============================================================================
create table if not exists public.user_settings (
  id uuid primary key references auth.users(id) on delete cascade,
  preferred_weight_unit text default 'kg' check (preferred_weight_unit in ('kg', 'lbs')),
  preferred_distance_unit text default 'cm' check (preferred_distance_unit in ('cm', 'inches')),
  dark_mode boolean default true,
  notifications_enabled boolean default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

-- ==============================================================================
-- 3. WORKOUTS TABLE
-- ==============================================================================
create table if not exists public.workouts (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  workout_date timestamptz not null default now(),
  workout_type text default 'Strength',
  title text not null default 'Workout Session',
  duration_minutes integer default 45,
  notes text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

-- ==============================================================================
-- 4. WORKOUT EXERCISES TABLE
-- ==============================================================================
create table if not exists public.workout_exercises (
  id uuid primary key default gen_random_uuid(),
  workout_id uuid not null references public.workouts(id) on delete cascade,
  exercise_name text not null,
  exercise_order integer not null default 0,
  created_at timestamptz not null default now()
);

-- ==============================================================================
-- 5. WORKOUT SETS TABLE
-- ==============================================================================
create table if not exists public.workout_sets (
  id uuid primary key default gen_random_uuid(),
  workout_exercise_id uuid not null references public.workout_exercises(id) on delete cascade,
  set_number integer not null default 1,
  weight numeric not null default 0,
  reps integer not null default 0,
  is_completed boolean default true,
  created_at timestamptz not null default now()
);

-- ==============================================================================
-- 6. WORKOUT TEMPLATES & TEMPLATE EXERCISES
-- ==============================================================================
create table if not exists public.workout_templates (
  id uuid primary key default gen_random_uuid(),
  user_id uuid references auth.users(id) on delete cascade, -- null indicates system template
  name text not null,
  description text,
  is_system boolean default false,
  created_at timestamptz not null default now()
);

create table if not exists public.workout_template_exercises (
  id uuid primary key default gen_random_uuid(),
  template_id uuid not null references public.workout_templates(id) on delete cascade,
  exercise_name text not null,
  exercise_order integer not null default 0,
  target_sets integer default 3,
  target_reps integer default 10,
  created_at timestamptz not null default now()
);

-- ==============================================================================
-- 7. PERSONAL RECORDS (PRs)
-- ==============================================================================
create table if not exists public.personal_records (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  exercise_name text not null,
  max_weight numeric not null default 0,
  max_reps integer not null default 0,
  achieved_at timestamptz not null default now(),
  workout_id uuid references public.workouts(id) on delete set null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint uq_user_exercise unique (user_id, exercise_name)
);

-- ==============================================================================
-- 8. PROGRESS PHOTOS TABLE (Storage paths only, binaries in Storage)
-- ==============================================================================
create table if not exists public.progress_photos (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  storage_path text not null,
  thumbnail_path text,
  pose text not null default 'Front' check (pose in ('Front', 'Side', 'Back', 'Flexed', 'Other')),
  workout_id uuid references public.workouts(id) on delete set null,
  weight_at_capture numeric,
  notes text,
  file_size bigint,
  mime_type text default 'image/webp',
  width integer,
  height integer,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

-- ==============================================================================
-- 9. BODY MEASUREMENTS TABLE
-- ==============================================================================
create table if not exists public.measurements (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  measurement_type text not null check (
    measurement_type in (
      'weight', 'chest', 'waist', 'hips', 'left_arm',
      'right_arm', 'left_thigh', 'right_thigh', 'shoulders', 'body_fat'
    )
  ),
  value numeric not null,
  unit text not null default 'kg',
  recorded_at timestamptz not null default now(),
  notes text,
  created_at timestamptz not null default now()
);

-- ==============================================================================
-- 10. REMINDERS TABLE
-- ==============================================================================
create table if not exists public.reminders (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  reminder_type text not null check (
    reminder_type in ('workout', 'photo', 'weight', 'weekly_review')
  ),
  reminder_time time not null default '18:30:00',
  days_of_week text default '["Mon","Tue","Thu","Fri"]',
  is_enabled boolean default true,
  created_at timestamptz not null default now()
);

-- ==============================================================================
-- INDEXES FOR FAST QUERY PERFORMANCE
-- ==============================================================================
create index if not exists idx_workouts_user_date on public.workouts(user_id, workout_date desc);
create index if not exists idx_workout_exercises_workout on public.workout_exercises(workout_id, exercise_order);
create index if not exists idx_workout_sets_exercise on public.workout_sets(workout_exercise_id, set_number);
create index if not exists idx_photos_user_date on public.progress_photos(user_id, created_at desc);
create index if not exists idx_photos_user_pose on public.progress_photos(user_id, pose);
create index if not exists idx_measurements_user_type_date on public.measurements(user_id, measurement_type, recorded_at desc);
create index if not exists idx_prs_user_exercise on public.personal_records(user_id, exercise_name);

-- ==============================================================================
-- AUTOMATIC TIMESTAMPS & PROFILE INITIALIZATION TRIGGER
-- ==============================================================================
create or replace function public.handle_updated_at()
returns trigger as $$
begin
  new.updated_at = now();
  return new;
end;
$$ language plpgsql;

create trigger tr_profiles_updated_at
  before update on public.profiles
  for each row execute function public.handle_updated_at();

create trigger tr_workouts_updated_at
  before update on public.workouts
  for each row execute function public.handle_updated_at();

create trigger tr_progress_photos_updated_at
  before update on public.progress_photos
  for each row execute function public.handle_updated_at();

create trigger tr_prs_updated_at
  before update on public.personal_records
  for each row execute function public.handle_updated_at();

create trigger tr_user_settings_updated_at
  before update on public.user_settings
  for each row execute function public.handle_updated_at();

-- Trigger: Automatically create public.profiles and public.user_settings on signup
create or replace function public.handle_new_user()
returns trigger as $$
begin
  insert into public.profiles (id, name)
  values (new.id, coalesce(new.raw_user_meta_data->>'name', split_part(new.email, '@', 1)));

  insert into public.user_settings (id)
  values (new.id);

  return new;
end;
$$ language plpgsql security definer;

-- Drop trigger if previously defined
drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
  after insert on auth.users
  for each row execute function public.handle_new_user();

-- ==============================================================================
-- ROW LEVEL SECURITY (RLS) POLICIES
-- ==============================================================================

-- Enable RLS on all tables
alter table public.profiles enable row level security;
alter table public.user_settings enable row level security;
alter table public.workouts enable row level security;
alter table public.workout_exercises enable row level security;
alter table public.workout_sets enable row level security;
alter table public.workout_templates enable row level security;
alter table public.workout_template_exercises enable row level security;
alter table public.personal_records enable row level security;
alter table public.progress_photos enable row level security;
alter table public.measurements enable row level security;
alter table public.reminders enable row level security;

-- Profiles Policies
create policy "Users can view own profile" on public.profiles
  for select using (auth.uid() = id);
create policy "Users can update own profile" on public.profiles
  for update using (auth.uid() = id);
create policy "Users can insert own profile" on public.profiles
  for insert with check (auth.uid() = id);

-- User Settings Policies
create policy "Users can view own settings" on public.user_settings
  for select using (auth.uid() = id);
create policy "Users can update own settings" on public.user_settings
  for update using (auth.uid() = id);
create policy "Users can insert own settings" on public.user_settings
  for insert with check (auth.uid() = id);

-- Workouts Policies
create policy "Users can view own workouts" on public.workouts
  for select using (auth.uid() = user_id);
create policy "Users can insert own workouts" on public.workouts
  for insert with check (auth.uid() = user_id);
create policy "Users can update own workouts" on public.workouts
  for update using (auth.uid() = user_id);
create policy "Users can delete own workouts" on public.workouts
  for delete using (auth.uid() = user_id);

-- Workout Exercises Policies (linked through workouts)
create policy "Users can view own workout exercises" on public.workout_exercises
  for select using (
    exists (
      select 1 from public.workouts
      where public.workouts.id = public.workout_exercises.workout_id
      and public.workouts.user_id = auth.uid()
    )
  );
create policy "Users can insert own workout exercises" on public.workout_exercises
  for insert with check (
    exists (
      select 1 from public.workouts
      where public.workouts.id = public.workout_exercises.workout_id
      and public.workouts.user_id = auth.uid()
    )
  );
create policy "Users can update own workout exercises" on public.workout_exercises
  for update using (
    exists (
      select 1 from public.workouts
      where public.workouts.id = public.workout_exercises.workout_id
      and public.workouts.user_id = auth.uid()
    )
  );
create policy "Users can delete own workout exercises" on public.workout_exercises
  for delete using (
    exists (
      select 1 from public.workouts
      where public.workouts.id = public.workout_exercises.workout_id
      and public.workouts.user_id = auth.uid()
    )
  );

-- Workout Sets Policies (linked through workout_exercises -> workouts)
create policy "Users can view own workout sets" on public.workout_sets
  for select using (
    exists (
      select 1 from public.workout_exercises
      join public.workouts on public.workouts.id = public.workout_exercises.workout_id
      where public.workout_exercises.id = public.workout_sets.workout_exercise_id
      and public.workouts.user_id = auth.uid()
    )
  );
create policy "Users can insert own workout sets" on public.workout_sets
  for insert with check (
    exists (
      select 1 from public.workout_exercises
      join public.workouts on public.workouts.id = public.workout_exercises.workout_id
      where public.workout_exercises.id = public.workout_sets.workout_exercise_id
      and public.workouts.user_id = auth.uid()
    )
  );
create policy "Users can update own workout sets" on public.workout_sets
  for update using (
    exists (
      select 1 from public.workout_exercises
      join public.workouts on public.workouts.id = public.workout_exercises.workout_id
      where public.workout_exercises.id = public.workout_sets.workout_exercise_id
      and public.workouts.user_id = auth.uid()
    )
  );
create policy "Users can delete own workout sets" on public.workout_sets
  for delete using (
    exists (
      select 1 from public.workout_exercises
      join public.workouts on public.workouts.id = public.workout_exercises.workout_id
      where public.workout_exercises.id = public.workout_sets.workout_exercise_id
      and public.workouts.user_id = auth.uid()
    )
  );

-- Workout Templates Policies
create policy "Users can view system or own templates" on public.workout_templates
  for select using (is_system = true or auth.uid() = user_id);
create policy "Users can manage own templates" on public.workout_templates
  for all using (auth.uid() = user_id);

create policy "Users can view template exercises" on public.workout_template_exercises
  for select using (
    exists (
      select 1 from public.workout_templates
      where public.workout_templates.id = public.workout_template_exercises.template_id
      and (public.workout_templates.is_system = true or public.workout_templates.user_id = auth.uid())
    )
  );
create policy "Users can manage own template exercises" on public.workout_template_exercises
  for all using (
    exists (
      select 1 from public.workout_templates
      where public.workout_templates.id = public.workout_template_exercises.template_id
      and public.workout_templates.user_id = auth.uid()
    )
  );

-- Personal Records Policies
create policy "Users can view own PRs" on public.personal_records
  for select using (auth.uid() = user_id);
create policy "Users can manage own PRs" on public.personal_records
  for all using (auth.uid() = user_id);

-- Progress Photos Policies
create policy "Users can view own progress photos" on public.progress_photos
  for select using (auth.uid() = user_id);
create policy "Users can insert own progress photos" on public.progress_photos
  for insert with check (auth.uid() = user_id);
create policy "Users can update own progress photos" on public.progress_photos
  for update using (auth.uid() = user_id);
create policy "Users can delete own progress photos" on public.progress_photos
  for delete using (auth.uid() = user_id);

-- Measurements Policies
create policy "Users can view own measurements" on public.measurements
  for select using (auth.uid() = user_id);
create policy "Users can insert own measurements" on public.measurements
  for insert with check (auth.uid() = user_id);
create policy "Users can update own measurements" on public.measurements
  for update using (auth.uid() = user_id);
create policy "Users can delete own measurements" on public.measurements
  for delete using (auth.uid() = user_id);

-- Reminders Policies
create policy "Users can view own reminders" on public.reminders
  for select using (auth.uid() = user_id);
create policy "Users can manage own reminders" on public.reminders
  for all using (auth.uid() = user_id);

-- ==============================================================================
-- 11. SUPABASE STORAGE BUCKET: progress-photos (PRIVATE)
-- ==============================================================================
insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values (
  'progress-photos',
  'progress-photos',
  false,
  10485760, -- 10MB maximum file size
  array['image/jpeg', 'image/png', 'image/webp']
)
on conflict (id) do update set
  public = false,
  file_size_limit = 10485760,
  allowed_mime_types = array['image/jpeg', 'image/png', 'image/webp'];

-- Storage RLS: Users can only read their own folder {user_id}/*
create policy "Users can read own progress photos"
on storage.objects for select
using (
  bucket_id = 'progress-photos'
  and (storage.foldername(name))[1] = auth.uid()::text
);

-- Storage RLS: Users can only upload into their own folder {user_id}/*
create policy "Users can upload own progress photos"
on storage.objects for insert
with check (
  bucket_id = 'progress-photos'
  and (storage.foldername(name))[1] = auth.uid()::text
);

-- Storage RLS: Users can only update their own objects {user_id}/*
create policy "Users can update own progress photos"
on storage.objects for update
using (
  bucket_id = 'progress-photos'
  and (storage.foldername(name))[1] = auth.uid()::text
);

-- Storage RLS: Users can only delete their own objects {user_id}/*
create policy "Users can delete own progress photos"
on storage.objects for delete
using (
  bucket_id = 'progress-photos'
  and (storage.foldername(name))[1] = auth.uid()::text
);

-- ==============================================================================
-- SEED SYSTEM WORKOUT TEMPLATES
-- ==============================================================================
insert into public.workout_templates (id, user_id, name, description, is_system)
values
  ('11111111-1111-1111-1111-111111111111', null, 'Push Day (Chest, Shoulders, Triceps)', 'Classic upper body push routine', true),
  ('22222222-2222-2222-2222-222222222222', null, 'Pull Day (Back, Biceps)', 'Upper body pull routine for width and thickness', true),
  ('33333333-3333-3333-3333-333333333333', null, 'Leg Day (Quads, Hamstrings, Calves)', 'Full lower body development', true)
on conflict (id) do nothing;

insert into public.workout_template_exercises (template_id, exercise_name, exercise_order, target_sets, target_reps)
values
  -- Push Day
  ('11111111-1111-1111-1111-111111111111', 'Barbell Bench Press', 1, 4, 8),
  ('11111111-1111-1111-1111-111111111111', 'Incline Dumbbell Press', 2, 3, 10),
  ('11111111-1111-1111-1111-111111111111', 'Overhead Shoulder Press', 3, 3, 10),
  ('11111111-1111-1111-1111-111111111111', 'Tricep Rope Pushdown', 4, 3, 12),
  -- Pull Day
  ('22222222-2222-2222-2222-222222222222', 'Barbell Deadlift', 1, 4, 6),
  ('22222222-2222-2222-2222-222222222222', 'Lat Pulldown', 2, 3, 10),
  ('22222222-2222-2222-2222-222222222222', 'Seated Cable Row', 3, 3, 10),
  ('22222222-2222-2222-2222-222222222222', 'Dumbbell Bicep Curl', 4, 3, 12),
  -- Leg Day
  ('33333333-3333-3333-3333-333333333333', 'Barbell Squat', 1, 4, 8),
  ('33333333-3333-3333-3333-333333333333', 'Romanian Deadlift', 2, 3, 10),
  ('33333333-3333-3333-3333-333333333333', 'Leg Extension', 3, 3, 12),
  ('33333333-3333-3333-3333-333333333333', 'Standing Calf Raise', 4, 4, 15)
on conflict do nothing;
