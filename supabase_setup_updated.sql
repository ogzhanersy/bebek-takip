-- =============================================
-- Baby Tracker Flutter - Supabase Database Setup (Updated)
-- =============================================

-- Enable necessary extensions
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- =============================================
-- 1. BABIES TABLE
-- =============================================
CREATE TABLE babies (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
    name VARCHAR(100) NOT NULL,
    birth_date TIMESTAMP WITH TIME ZONE NOT NULL,
    gender VARCHAR(10) NOT NULL CHECK (gender IN ('male', 'female')),
    weight VARCHAR(20),
    height VARCHAR(20),
    is_primary BOOLEAN DEFAULT FALSE,
    avatar TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Index for better performance
CREATE INDEX idx_babies_user_id ON babies(user_id);
CREATE INDEX idx_babies_is_primary ON babies(is_primary);

-- =============================================
-- 2. SLEEP RECORDS TABLE
-- =============================================
CREATE TABLE sleep_records (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    baby_id UUID REFERENCES babies(id) ON DELETE CASCADE,
    start_time TIMESTAMP WITH TIME ZONE NOT NULL,
    end_time TIMESTAMP WITH TIME ZONE,
    notes TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Indexes for better performance
CREATE INDEX idx_sleep_records_baby_id ON sleep_records(baby_id);
CREATE INDEX idx_sleep_records_start_time ON sleep_records(start_time);
CREATE INDEX idx_sleep_records_active ON sleep_records(baby_id, end_time) WHERE end_time IS NULL;

-- =============================================
-- 3. FEEDING RECORDS TABLE
-- =============================================
CREATE TABLE feeding_records (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    baby_id UUID REFERENCES babies(id) ON DELETE CASCADE,
    type VARCHAR(20) NOT NULL CHECK (type IN ('breastfeeding', 'bottle', 'solid')),
    start_time TIMESTAMP WITH TIME ZONE NOT NULL,
    end_time TIMESTAMP WITH TIME ZONE,
    amount INTEGER, -- ml for bottle feeding
    side VARCHAR(10) CHECK (side IN ('left', 'right')), -- for breastfeeding
    notes TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Indexes for better performance
CREATE INDEX idx_feeding_records_baby_id ON feeding_records(baby_id);
CREATE INDEX idx_feeding_records_start_time ON feeding_records(start_time);
CREATE INDEX idx_feeding_records_type ON feeding_records(type);
CREATE INDEX idx_feeding_records_active ON feeding_records(baby_id, end_time) WHERE end_time IS NULL;

-- =============================================
-- 4. DIAPER RECORDS TABLE (NEW)
-- =============================================
CREATE TABLE diaper_records (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    baby_id UUID REFERENCES babies(id) ON DELETE CASCADE,
    type VARCHAR(20) NOT NULL CHECK (type IN ('wet', 'dirty', 'mixed')),
    time TIMESTAMP WITH TIME ZONE NOT NULL,
    notes TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Indexes for better performance
CREATE INDEX idx_diaper_records_baby_id ON diaper_records(baby_id);
CREATE INDEX idx_diaper_records_time ON diaper_records(time);
CREATE INDEX idx_diaper_records_type ON diaper_records(type);

-- =============================================
-- 5. VACCINATIONS TABLE
-- =============================================
CREATE TABLE vaccinations (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    baby_id UUID REFERENCES babies(id) ON DELETE CASCADE,
    vaccine_name VARCHAR(200) NOT NULL,
    scheduled_date TIMESTAMP WITH TIME ZONE NOT NULL,
    administered_date TIMESTAMP WITH TIME ZONE,
    location VARCHAR(200),
    notes TEXT,
    is_completed BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Indexes for better performance
CREATE INDEX idx_vaccinations_baby_id ON vaccinations(baby_id);
CREATE INDEX idx_vaccinations_scheduled_date ON vaccinations(scheduled_date);
CREATE INDEX idx_vaccinations_is_completed ON vaccinations(is_completed);

-- =============================================
-- 6. MEMORIES TABLE
-- =============================================
CREATE TABLE memories (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    baby_id UUID REFERENCES babies(id) ON DELETE CASCADE,
    type VARCHAR(20) NOT NULL CHECK (type IN ('photo', 'video', 'note', 'milestone')),
    title VARCHAR(200) NOT NULL,
    description TEXT,
    media_url TEXT,
    memory_date TIMESTAMP WITH TIME ZONE NOT NULL,
    metadata JSONB, -- For storing additional data like tags
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Indexes for better performance
CREATE INDEX idx_memories_baby_id ON memories(baby_id);
CREATE INDEX idx_memories_memory_date ON memories(memory_date);
CREATE INDEX idx_memories_type ON memories(type);
CREATE INDEX idx_memories_metadata ON memories USING GIN(metadata);

-- =============================================
-- 7. USER PREFERENCES TABLE
-- =============================================
CREATE TABLE user_preferences (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE UNIQUE,
    notification_settings JSONB DEFAULT '{}',
    theme_settings JSONB DEFAULT '{}',
    language VARCHAR(10) DEFAULT 'tr',
    timezone VARCHAR(50) DEFAULT 'Europe/Istanbul',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- =============================================
-- 8. UPDATE TRIGGERS FOR updated_at
-- =============================================

-- Function to update updated_at column
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ language 'plpgsql';

-- Create triggers for all tables
CREATE TRIGGER update_babies_updated_at BEFORE UPDATE ON babies FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_sleep_records_updated_at BEFORE UPDATE ON sleep_records FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_feeding_records_updated_at BEFORE UPDATE ON feeding_records FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_diaper_records_updated_at BEFORE UPDATE ON diaper_records FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_vaccinations_updated_at BEFORE UPDATE ON vaccinations FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_memories_updated_at BEFORE UPDATE ON memories FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_user_preferences_updated_at BEFORE UPDATE ON user_preferences FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- =============================================
-- 9. HELPER FUNCTIONS
-- =============================================

-- Function to get active sleep session for a baby
CREATE OR REPLACE FUNCTION get_active_sleep(p_baby_id UUID)
RETURNS TABLE(
    id UUID,
    start_time TIMESTAMP WITH TIME ZONE,
    notes TEXT
) AS $$
BEGIN
    RETURN QUERY
    SELECT sr.id, sr.start_time, sr.notes
    FROM sleep_records sr
    WHERE sr.baby_id = p_baby_id
    AND sr.end_time IS NULL
    ORDER BY sr.start_time DESC
    LIMIT 1;
END;
$$ LANGUAGE plpgsql;

-- Function to get active feeding session for a baby
CREATE OR REPLACE FUNCTION get_active_feeding(p_baby_id UUID)
RETURNS TABLE(
    id UUID,
    type VARCHAR(20),
    start_time TIMESTAMP WITH TIME ZONE,
    amount INTEGER,
    side VARCHAR(10),
    notes TEXT
) AS $$
BEGIN
    RETURN QUERY
    SELECT fr.id, fr.type, fr.start_time, fr.amount, fr.side, fr.notes
    FROM feeding_records fr
    WHERE fr.baby_id = p_baby_id
    AND fr.end_time IS NULL
    ORDER BY fr.start_time DESC
    LIMIT 1;
END;
$$ LANGUAGE plpgsql;

-- Function to get today's records for a baby
CREATE OR REPLACE FUNCTION get_today_records(p_baby_id UUID, p_date DATE DEFAULT CURRENT_DATE)
RETURNS TABLE(
    sleep_count INTEGER,
    feeding_count INTEGER,
    diaper_count INTEGER
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        (SELECT COUNT(*)::INTEGER FROM sleep_records sr 
         WHERE sr.baby_id = p_baby_id 
         AND DATE(sr.start_time) = p_date),
        (SELECT COUNT(*)::INTEGER FROM feeding_records fr 
         WHERE fr.baby_id = p_baby_id 
         AND DATE(fr.start_time) = p_date),
        (SELECT COUNT(*)::INTEGER FROM diaper_records dr 
         WHERE dr.baby_id = p_baby_id 
         AND DATE(dr.time) = p_date);
END;
$$ LANGUAGE plpgsql;

-- =============================================
-- 10. ROW LEVEL SECURITY (RLS) POLICIES
-- =============================================

-- Enable RLS on all tables
ALTER TABLE babies ENABLE ROW LEVEL SECURITY;
ALTER TABLE sleep_records ENABLE ROW LEVEL SECURITY;
ALTER TABLE feeding_records ENABLE ROW LEVEL SECURITY;
ALTER TABLE diaper_records ENABLE ROW LEVEL SECURITY;
ALTER TABLE vaccinations ENABLE ROW LEVEL SECURITY;
ALTER TABLE memories ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_preferences ENABLE ROW LEVEL SECURITY;

-- Babies table policies
CREATE POLICY "Users can view their own babies" ON babies FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "Users can insert their own babies" ON babies FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "Users can update their own babies" ON babies FOR UPDATE USING (auth.uid() = user_id);
CREATE POLICY "Users can delete their own babies" ON babies FOR DELETE USING (auth.uid() = user_id);

-- Sleep records policies
CREATE POLICY "Users can view sleep records of their babies" ON sleep_records FOR SELECT 
USING (EXISTS (SELECT 1 FROM babies WHERE babies.id = sleep_records.baby_id AND babies.user_id = auth.uid()));
CREATE POLICY "Users can insert sleep records for their babies" ON sleep_records FOR INSERT 
WITH CHECK (EXISTS (SELECT 1 FROM babies WHERE babies.id = sleep_records.baby_id AND babies.user_id = auth.uid()));
CREATE POLICY "Users can update sleep records of their babies" ON sleep_records FOR UPDATE 
USING (EXISTS (SELECT 1 FROM babies WHERE babies.id = sleep_records.baby_id AND babies.user_id = auth.uid()));
CREATE POLICY "Users can delete sleep records of their babies" ON sleep_records FOR DELETE 
USING (EXISTS (SELECT 1 FROM babies WHERE babies.id = sleep_records.baby_id AND babies.user_id = auth.uid()));

-- Feeding records policies
CREATE POLICY "Users can view feeding records of their babies" ON feeding_records FOR SELECT 
USING (EXISTS (SELECT 1 FROM babies WHERE babies.id = feeding_records.baby_id AND babies.user_id = auth.uid()));
CREATE POLICY "Users can insert feeding records for their babies" ON feeding_records FOR INSERT 
WITH CHECK (EXISTS (SELECT 1 FROM babies WHERE babies.id = feeding_records.baby_id AND babies.user_id = auth.uid()));
CREATE POLICY "Users can update feeding records of their babies" ON feeding_records FOR UPDATE 
USING (EXISTS (SELECT 1 FROM babies WHERE babies.id = feeding_records.baby_id AND babies.user_id = auth.uid()));
CREATE POLICY "Users can delete feeding records of their babies" ON feeding_records FOR DELETE 
USING (EXISTS (SELECT 1 FROM babies WHERE babies.id = feeding_records.baby_id AND babies.user_id = auth.uid()));

-- Diaper records policies
CREATE POLICY "Users can view diaper records of their babies" ON diaper_records FOR SELECT 
USING (EXISTS (SELECT 1 FROM babies WHERE babies.id = diaper_records.baby_id AND babies.user_id = auth.uid()));
CREATE POLICY "Users can insert diaper records for their babies" ON diaper_records FOR INSERT 
WITH CHECK (EXISTS (SELECT 1 FROM babies WHERE babies.id = diaper_records.baby_id AND babies.user_id = auth.uid()));
CREATE POLICY "Users can update diaper records of their babies" ON diaper_records FOR UPDATE 
USING (EXISTS (SELECT 1 FROM babies WHERE babies.id = diaper_records.baby_id AND babies.user_id = auth.uid()));
CREATE POLICY "Users can delete diaper records of their babies" ON diaper_records FOR DELETE 
USING (EXISTS (SELECT 1 FROM babies WHERE babies.id = diaper_records.baby_id AND babies.user_id = auth.uid()));

-- Vaccinations policies
CREATE POLICY "Users can view vaccinations of their babies" ON vaccinations FOR SELECT 
USING (EXISTS (SELECT 1 FROM babies WHERE babies.id = vaccinations.baby_id AND babies.user_id = auth.uid()));
CREATE POLICY "Users can insert vaccinations for their babies" ON vaccinations FOR INSERT 
WITH CHECK (EXISTS (SELECT 1 FROM babies WHERE babies.id = vaccinations.baby_id AND babies.user_id = auth.uid()));
CREATE POLICY "Users can update vaccinations of their babies" ON vaccinations FOR UPDATE 
USING (EXISTS (SELECT 1 FROM babies WHERE babies.id = vaccinations.baby_id AND babies.user_id = auth.uid()));
CREATE POLICY "Users can delete vaccinations of their babies" ON vaccinations FOR DELETE 
USING (EXISTS (SELECT 1 FROM babies WHERE babies.id = vaccinations.baby_id AND babies.user_id = auth.uid()));

-- Memories policies
CREATE POLICY "Users can view memories of their babies" ON memories FOR SELECT 
USING (EXISTS (SELECT 1 FROM babies WHERE babies.id = memories.baby_id AND babies.user_id = auth.uid()));
CREATE POLICY "Users can insert memories for their babies" ON memories FOR INSERT 
WITH CHECK (EXISTS (SELECT 1 FROM babies WHERE babies.id = memories.baby_id AND babies.user_id = auth.uid()));
CREATE POLICY "Users can update memories of their babies" ON memories FOR UPDATE 
USING (EXISTS (SELECT 1 FROM babies WHERE babies.id = memories.baby_id AND babies.user_id = auth.uid()));
CREATE POLICY "Users can delete memories of their babies" ON memories FOR DELETE 
USING (EXISTS (SELECT 1 FROM babies WHERE babies.id = memories.baby_id AND babies.user_id = auth.uid()));

-- User preferences policies
CREATE POLICY "Users can view their own preferences" ON user_preferences FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "Users can insert their own preferences" ON user_preferences FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "Users can update their own preferences" ON user_preferences FOR UPDATE USING (auth.uid() = user_id);
CREATE POLICY "Users can delete their own preferences" ON user_preferences FOR DELETE USING (auth.uid() = user_id);

-- =============================================
-- 11. STORAGE BUCKETS (Run in Supabase Dashboard)
-- =============================================

-- Create storage buckets for media files
-- Note: These should be created via Supabase Dashboard or Storage API

-- INSERT INTO storage.buckets (id, name, public) VALUES ('memories', 'memories', true);
-- INSERT INTO storage.buckets (id, name, public) VALUES ('avatars', 'avatars', true);

-- Storage policies will be created separately in the Dashboard

-- =============================================
-- 12. SAMPLE DATA (Optional - for testing)
-- =============================================

-- Insert a sample baby (will only work after user authentication)
-- INSERT INTO babies (user_id, name, birth_date, gender, weight, height, is_primary)
-- VALUES (
--     auth.uid(),
--     'Test Bebek',
--     NOW() - INTERVAL '90 days',
--     'female',
--     '6.2 kg',
--     '65 cm',
--     true
-- );

-- =============================================
-- END OF SETUP
-- =============================================
