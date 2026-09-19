-- Migration: Add day_number to progress_photos
ALTER TABLE progress_photos ADD COLUMN day_number INTEGER DEFAULT 1;
CREATE INDEX IF NOT EXISTS idx_photos_user_day ON progress_photos(user_id, day_number);
