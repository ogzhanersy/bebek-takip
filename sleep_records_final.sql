-- Drop existing views first
DROP VIEW IF EXISTS daily_sleep_summary;
DROP VIEW IF EXISTS weekly_sleep_summary;
DROP VIEW IF EXISTS monthly_sleep_summary;
DROP VIEW IF EXISTS sleep_duration_view;

-- Add duration columns to existing sleep_records table
ALTER TABLE sleep_records 
ADD COLUMN IF NOT EXISTS duration_minutes INTEGER,
ADD COLUMN IF NOT EXISTS duration_hours DECIMAL(4,2);

-- Create indexes for better performance (if not exists)
CREATE INDEX IF NOT EXISTS idx_sleep_records_baby_id ON sleep_records(baby_id);
CREATE INDEX IF NOT EXISTS idx_sleep_records_start_time ON sleep_records(start_time);
CREATE INDEX IF NOT EXISTS idx_sleep_records_end_time ON sleep_records(end_time);
CREATE INDEX IF NOT EXISTS idx_sleep_records_duration ON sleep_records(duration_hours);

-- Update existing records with calculated duration
UPDATE sleep_records 
SET 
  duration_minutes = EXTRACT(EPOCH FROM (end_time - start_time)) / 60,
  duration_hours = ROUND((EXTRACT(EPOCH FROM (end_time - start_time)) / 60 / 60)::DECIMAL, 2)
WHERE end_time IS NOT NULL 
  AND duration_minutes IS NULL;

-- Function to calculate duration when end_time is set
CREATE OR REPLACE FUNCTION calculate_sleep_duration()
RETURNS TRIGGER AS $$
BEGIN
  -- Only calculate if end_time is not null
  IF NEW.end_time IS NOT NULL THEN
    NEW.duration_minutes := EXTRACT(EPOCH FROM (NEW.end_time - NEW.start_time)) / 60;
    NEW.duration_hours := ROUND((NEW.duration_minutes / 60)::DECIMAL, 2);
  ELSE
    NEW.duration_minutes := NULL;
    NEW.duration_hours := NULL;
  END IF;
  
  NEW.updated_at := NOW();
  RETURN NEW;
END;
$$ language 'plpgsql';

-- Drop existing trigger if exists
DROP TRIGGER IF EXISTS calculate_sleep_duration_trigger ON sleep_records;

-- Trigger to automatically calculate duration
CREATE TRIGGER calculate_sleep_duration_trigger
  BEFORE INSERT OR UPDATE ON sleep_records
  FOR EACH ROW
  EXECUTE FUNCTION calculate_sleep_duration();

-- Drop existing trigger if exists
DROP TRIGGER IF EXISTS update_sleep_records_updated_at ON sleep_records;

-- Create updated_at trigger
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ language 'plpgsql';

CREATE TRIGGER update_sleep_records_updated_at
  BEFORE UPDATE ON sleep_records
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();
