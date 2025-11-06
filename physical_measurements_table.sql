-- Physical Measurements Table
CREATE TABLE IF NOT EXISTS physical_measurements (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  baby_id UUID NOT NULL REFERENCES babies(id) ON DELETE CASCADE,
  weight DECIMAL(5,2), -- kg, precision 5 digits, 2 decimal places
  height DECIMAL(5,2), -- cm, precision 5 digits, 2 decimal places  
  head_circumference DECIMAL(5,2), -- cm, precision 5 digits, 2 decimal places
  notes TEXT,
  measured_at TIMESTAMP WITH TIME ZONE NOT NULL,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create indexes for better performance
CREATE INDEX IF NOT EXISTS idx_physical_measurements_baby_id ON physical_measurements(baby_id);
CREATE INDEX IF NOT EXISTS idx_physical_measurements_measured_at ON physical_measurements(measured_at);

-- Enable Row Level Security
ALTER TABLE physical_measurements ENABLE ROW LEVEL SECURITY;

-- Create RLS policies
CREATE POLICY "Users can view their babies' physical measurements" ON physical_measurements
  FOR SELECT USING (
    baby_id IN (
      SELECT id FROM babies WHERE user_id = auth.uid()
    )
  );

CREATE POLICY "Users can insert physical measurements for their babies" ON physical_measurements
  FOR INSERT WITH CHECK (
    baby_id IN (
      SELECT id FROM babies WHERE user_id = auth.uid()
    )
  );

CREATE POLICY "Users can update their babies' physical measurements" ON physical_measurements
  FOR UPDATE USING (
    baby_id IN (
      SELECT id FROM babies WHERE user_id = auth.uid()
    )
  );

CREATE POLICY "Users can delete their babies' physical measurements" ON physical_measurements
  FOR DELETE USING (
    baby_id IN (
      SELECT id FROM babies WHERE user_id = auth.uid()
    )
  );

-- Create updated_at trigger
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ language 'plpgsql';

CREATE TRIGGER update_physical_measurements_updated_at
  BEFORE UPDATE ON physical_measurements
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();
