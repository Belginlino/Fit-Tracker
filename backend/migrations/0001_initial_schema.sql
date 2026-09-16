-- FitTrack D1 Initial Schema Migration

-- Users Table
CREATE TABLE IF NOT EXISTS users (
  id TEXT PRIMARY KEY,
  email TEXT NOT NULL UNIQUE,
  password_hash TEXT NOT NULL,
  name TEXT NOT NULL,
  goal TEXT DEFAULT 'Build Muscle',
  current_weight REAL DEFAULT 74.2,
  target_weight REAL DEFAULT 78.0,
  height REAL DEFAULT 178.0,
  preferred_days TEXT DEFAULT '["Mon","Tue","Thu","Fri"]',
  reminder_time TEXT DEFAULT '18:30',
  workout_streak INTEGER DEFAULT 0,
  photo_streak INTEGER DEFAULT 0,
  has_completed_onboarding INTEGER DEFAULT 0,
  created_at TEXT NOT NULL DEFAULT (datetime('now')),
  updated_at TEXT NOT NULL DEFAULT (datetime('now'))
);

CREATE INDEX IF NOT EXISTS idx_users_email ON users(email);

-- Progress Photos Table (Only stores R2 object keys and metadata, binaries in R2)
CREATE TABLE IF NOT EXISTS progress_photos (
  id TEXT PRIMARY KEY,
  user_id TEXT NOT NULL,
  r2_object_key TEXT NOT NULL,
  thumbnail_object_key TEXT,
  pose TEXT NOT NULL DEFAULT 'Front',
  workout_id TEXT,
  weight_at_capture REAL,
  notes TEXT,
  created_at TEXT NOT NULL DEFAULT (datetime('now')),
  FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
);

CREATE INDEX IF NOT EXISTS idx_photos_user_date ON progress_photos(user_id, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_photos_user_pose ON progress_photos(user_id, pose);

-- Workouts Table
CREATE TABLE IF NOT EXISTS workouts (
  id TEXT PRIMARY KEY,
  user_id TEXT NOT NULL,
  title TEXT NOT NULL,
  date TEXT NOT NULL DEFAULT (datetime('now')),
  duration_minutes INTEGER DEFAULT 45,
  notes TEXT,
  created_at TEXT NOT NULL DEFAULT (datetime('now')),
  FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
);

CREATE INDEX IF NOT EXISTS idx_workouts_user_date ON workouts(user_id, date DESC);

-- Workout Exercises Table
CREATE TABLE IF NOT EXISTS workout_exercises (
  id TEXT PRIMARY KEY,
  workout_id TEXT NOT NULL,
  name TEXT NOT NULL,
  exercise_order INTEGER DEFAULT 0,
  notes TEXT,
  FOREIGN KEY (workout_id) REFERENCES workouts(id) ON DELETE CASCADE
);

CREATE INDEX IF NOT EXISTS idx_exercises_workout ON workout_exercises(workout_id);

-- Workout Sets Table
CREATE TABLE IF NOT EXISTS workout_sets (
  id TEXT PRIMARY KEY,
  exercise_id TEXT NOT NULL,
  set_number INTEGER NOT NULL,
  weight REAL NOT NULL DEFAULT 0.0,
  reps INTEGER NOT NULL DEFAULT 0,
  is_completed INTEGER DEFAULT 1,
  FOREIGN KEY (exercise_id) REFERENCES workout_exercises(id) ON DELETE CASCADE
);

CREATE INDEX IF NOT EXISTS idx_sets_exercise ON workout_sets(exercise_id);

-- Measurements Table (Weight & Circumference)
CREATE TABLE IF NOT EXISTS measurements (
  id TEXT PRIMARY KEY,
  user_id TEXT NOT NULL,
  type TEXT NOT NULL DEFAULT 'Weight',
  value REAL NOT NULL,
  unit TEXT NOT NULL DEFAULT 'kg',
  note TEXT,
  recorded_at TEXT NOT NULL DEFAULT (datetime('now')),
  FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
);

CREATE INDEX IF NOT EXISTS idx_measurements_user_type ON measurements(user_id, type, recorded_at DESC);

-- Workout Templates Table
CREATE TABLE IF NOT EXISTS workout_templates (
  id TEXT PRIMARY KEY,
  user_id TEXT,
  title TEXT NOT NULL,
  exercises_json TEXT,
  created_at TEXT NOT NULL DEFAULT (datetime('now'))
);

-- Personal Records Table
CREATE TABLE IF NOT EXISTS personal_records (
  id TEXT PRIMARY KEY,
  user_id TEXT NOT NULL,
  exercise_name TEXT NOT NULL,
  max_weight REAL NOT NULL,
  achieved_at TEXT NOT NULL DEFAULT (datetime('now')),
  workout_id TEXT,
  FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
  UNIQUE(user_id, exercise_name)
);

CREATE INDEX IF NOT EXISTS idx_prs_user ON personal_records(user_id);
