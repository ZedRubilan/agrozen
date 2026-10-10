-- Migration: 001_create_farmers.sql
-- Description: Creates the farmers table with profile data, language, district, daily question tracking, and RLS policies.
-- Idempotent: Can be executed multiple times safely.

-- Ensure UUID generator extension is available
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- 1. Create farmers table
CREATE TABLE IF NOT EXISTS farmers (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    phone TEXT UNIQUE,
    name TEXT,
    language TEXT NOT NULL DEFAULT 'uz' CHECK (language IN ('uz', 'ru', 'en')),
    district TEXT NOT NULL,
    disclaimer_accepted BOOLEAN DEFAULT false,
    daily_question_count INT DEFAULT 0,
    last_question_date DATE,
    fcm_token TEXT,
    created_at TIMESTAMPTZ DEFAULT now(),
    updated_at TIMESTAMPTZ DEFAULT now()
);

-- 2. Create indexes for performance
CREATE INDEX IF NOT EXISTS idx_farmers_phone ON farmers(phone);
CREATE INDEX IF NOT EXISTS idx_farmers_district ON farmers(district);
CREATE INDEX IF NOT EXISTS idx_farmers_last_question_date ON farmers(last_question_date);

-- 3. Trigger to maintain updated_at timestamp
CREATE OR REPLACE FUNCTION set_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = now();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trg_farmers_updated_at ON farmers;
CREATE TRIGGER trg_farmers_updated_at
    BEFORE UPDATE ON farmers
    FOR EACH ROW
    EXECUTE FUNCTION set_updated_at();

-- 4. Atomic function to check and increment daily questions
CREATE OR REPLACE FUNCTION check_and_increment_daily_questions(
    p_farmer_id UUID,
    p_daily_limit INT DEFAULT 30,
    p_max_daily INT DEFAULT NULL
)
RETURNS TABLE (
    allowed BOOLEAN,
    current_count INT,
    remaining INT,
    message TEXT
) AS $$
DECLARE
    v_farmer RECORD;
    v_today DATE := (now() AT TIME ZONE 'Asia/Tashkent')::DATE;
    v_limit INT := COALESCE(p_max_daily, p_daily_limit, 30);
    v_new_count INT;
BEGIN
    SELECT * INTO v_farmer FROM farmers WHERE id = p_farmer_id FOR UPDATE;

    IF NOT FOUND THEN
        RETURN QUERY SELECT false, 0, 0, 'Farmer not found'::TEXT;
        RETURN;
    END IF;

    -- Reset count if date is different
    IF v_farmer.last_question_date IS NULL OR v_farmer.last_question_date < v_today THEN
        v_new_count := 1;
        UPDATE farmers
        SET daily_question_count = v_new_count,
            last_question_date = v_today,
            updated_at = now()
        WHERE id = p_farmer_id;

        RETURN QUERY SELECT true, v_new_count, (v_limit - v_new_count), 'OK'::TEXT;
        RETURN;
    END IF;

    -- If today, check limit
    IF v_farmer.daily_question_count >= v_limit THEN
        RETURN QUERY SELECT false, v_farmer.daily_question_count, 0, 'Daily question limit reached'::TEXT;
        RETURN;
    ELSE
        v_new_count := v_farmer.daily_question_count + 1;
        UPDATE farmers
        SET daily_question_count = v_new_count,
            last_question_date = v_today,
            updated_at = now()
        WHERE id = p_farmer_id;

        RETURN QUERY SELECT true, v_new_count, (v_limit - v_new_count), 'OK'::TEXT;
        RETURN;
    END IF;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 5. Row Level Security (RLS)
ALTER TABLE farmers ENABLE ROW LEVEL SECURITY;

-- Allow public read/write access for application usage (anon / authenticated / service_role)
DROP POLICY IF EXISTS "Allow select farmers" ON farmers;
CREATE POLICY "Allow select farmers"
    ON farmers FOR SELECT
    USING (true);

DROP POLICY IF EXISTS "Allow insert farmers" ON farmers;
CREATE POLICY "Allow insert farmers"
    ON farmers FOR INSERT
    WITH CHECK (true);

DROP POLICY IF EXISTS "Allow update farmers" ON farmers;
CREATE POLICY "Allow update farmers"
    ON farmers FOR UPDATE
    USING (true)
    WITH CHECK (true);

DROP POLICY IF EXISTS "Allow delete farmers" ON farmers;
CREATE POLICY "Allow delete farmers"
    ON farmers FOR DELETE
    USING (true);
