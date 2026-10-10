-- Migration: 008_support_english_and_trigger_fixes.sql
-- Description: Updates language CHECK constraints on farmers and question_logs to include 'en',
--              fixes sync_batch_current_count() on UPDATE when entry_type or batch_id changes,
--              updates check_and_increment_daily_questions() for Uzbekistan time (UTC+5),
--              and tightens write RLS policies on veterinarians and notification_logs.
-- Idempotent: Can be executed multiple times safely.

-- 1. Update farmers language CHECK constraint to allow ('uz', 'ru', 'en')
ALTER TABLE farmers DROP CONSTRAINT IF EXISTS farmers_language_check;
ALTER TABLE farmers ADD CONSTRAINT farmers_language_check CHECK (language IN ('uz', 'ru', 'en'));

-- 2. Update question_logs language CHECK constraint to allow ('uz', 'ru', 'en')
ALTER TABLE question_logs DROP CONSTRAINT IF EXISTS question_logs_language_check;
ALTER TABLE question_logs ADD CONSTRAINT question_logs_language_check CHECK (language IN ('uz', 'ru', 'en'));

-- 3. Update check_and_increment_daily_questions to use Uzbekistan time and accept p_daily_limit / p_max_daily
DROP FUNCTION IF EXISTS check_and_increment_daily_questions(UUID, INT);
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

-- 4. Update sync_batch_current_count() to handle UPDATE when OLD.entry_type = 'mortality' or batch_id changes
CREATE OR REPLACE FUNCTION sync_batch_current_count()
RETURNS TRIGGER AS $$
DECLARE
    v_total_mortality NUMERIC;
    v_initial_count INT;
BEGIN
    IF TG_OP = 'DELETE' THEN
        IF OLD.entry_type = 'mortality' THEN
            SELECT initial_count INTO v_initial_count FROM batches WHERE id = OLD.batch_id;
            IF FOUND THEN
                SELECT COALESCE(SUM(value), 0) INTO v_total_mortality
                FROM diary_entries
                WHERE batch_id = OLD.batch_id AND entry_type = 'mortality';

                UPDATE batches
                SET current_count = GREATEST(0, v_initial_count - v_total_mortality::INT),
                    updated_at = now()
                WHERE id = OLD.batch_id;
            END IF;
        END IF;
    ELSIF TG_OP = 'INSERT' THEN
        IF NEW.entry_type = 'mortality' THEN
            SELECT initial_count INTO v_initial_count FROM batches WHERE id = NEW.batch_id;
            IF FOUND THEN
                SELECT COALESCE(SUM(value), 0) INTO v_total_mortality
                FROM diary_entries
                WHERE batch_id = NEW.batch_id AND entry_type = 'mortality';

                UPDATE batches
                SET current_count = GREATEST(0, v_initial_count - v_total_mortality::INT),
                    updated_at = now()
                WHERE id = NEW.batch_id;
            END IF;
        END IF;
    ELSIF TG_OP = 'UPDATE' THEN
        IF OLD.entry_type = 'mortality' OR NEW.entry_type = 'mortality' THEN
            -- Recalculate NEW.batch_id
            SELECT initial_count INTO v_initial_count FROM batches WHERE id = NEW.batch_id;
            IF FOUND THEN
                SELECT COALESCE(SUM(value), 0) INTO v_total_mortality
                FROM diary_entries
                WHERE batch_id = NEW.batch_id AND entry_type = 'mortality';

                UPDATE batches
                SET current_count = GREATEST(0, v_initial_count - v_total_mortality::INT),
                    updated_at = now()
                WHERE id = NEW.batch_id;
            END IF;

            -- If batch_id changed, also recalculate OLD.batch_id
            IF OLD.batch_id IS DISTINCT FROM NEW.batch_id THEN
                SELECT initial_count INTO v_initial_count FROM batches WHERE id = OLD.batch_id;
                IF FOUND THEN
                    SELECT COALESCE(SUM(value), 0) INTO v_total_mortality
                    FROM diary_entries
                    WHERE batch_id = OLD.batch_id AND entry_type = 'mortality';

                    UPDATE batches
                    SET current_count = GREATEST(0, v_initial_count - v_total_mortality::INT),
                        updated_at = now()
                    WHERE id = OLD.batch_id;
                END IF;
            END IF;
        END IF;
    END IF;

    RETURN NULL;
END;
$$ LANGUAGE plpgsql;

-- 5. Restrict write policies on veterinarians and notification_logs to service_role
DROP POLICY IF EXISTS "Allow insert veterinarians" ON veterinarians;
CREATE POLICY "Allow insert veterinarians"
    ON veterinarians FOR INSERT
    TO service_role
    WITH CHECK (auth.role() = 'service_role');

DROP POLICY IF EXISTS "Allow update veterinarians" ON veterinarians;
CREATE POLICY "Allow update veterinarians"
    ON veterinarians FOR UPDATE
    TO service_role
    USING (auth.role() = 'service_role')
    WITH CHECK (auth.role() = 'service_role');

DROP POLICY IF EXISTS "Allow insert notification_logs" ON notification_logs;
CREATE POLICY "Allow insert notification_logs"
    ON notification_logs FOR INSERT
    TO service_role
    WITH CHECK (auth.role() = 'service_role');

DROP POLICY IF EXISTS "Allow update notification_logs" ON notification_logs;
CREATE POLICY "Allow update notification_logs"
    ON notification_logs FOR UPDATE
    TO service_role
    USING (auth.role() = 'service_role')
    WITH CHECK (auth.role() = 'service_role');
