-- Migration: 003_create_diary_entries.sql
-- Description: Creates the diary_entries table to record mortality, feed, and weight logs.
-- Idempotent: Can be executed multiple times safely.

-- 1. Create diary_entries table
CREATE TABLE IF NOT EXISTS diary_entries (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    batch_id UUID NOT NULL REFERENCES batches(id) ON DELETE CASCADE,
    entry_date DATE NOT NULL DEFAULT CURRENT_DATE,
    entry_type TEXT NOT NULL CHECK (entry_type IN ('mortality', 'feed', 'weight')),
    value NUMERIC NOT NULL CHECK (value >= 0),
    notes TEXT,
    created_at TIMESTAMPTZ DEFAULT now()
);

-- 2. Indexes for batch diary history and daily lookups
CREATE INDEX IF NOT EXISTS idx_diary_entries_batch_id ON diary_entries(batch_id);
CREATE INDEX IF NOT EXISTS idx_diary_entries_entry_date ON diary_entries(entry_date);
CREATE INDEX IF NOT EXISTS idx_diary_entries_entry_type ON diary_entries(entry_type);
CREATE INDEX IF NOT EXISTS idx_diary_entries_batch_date_type ON diary_entries(batch_id, entry_date, entry_type);

-- 3. Automatic synchronization of current_count in batches when mortality entries are logged
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

DROP TRIGGER IF EXISTS trg_sync_batch_mortality ON diary_entries;
CREATE TRIGGER trg_sync_batch_mortality
    AFTER INSERT OR UPDATE OR DELETE ON diary_entries
    FOR EACH ROW
    EXECUTE FUNCTION sync_batch_current_count();

-- 4. Row Level Security (RLS)
ALTER TABLE diary_entries ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Allow select diary_entries" ON diary_entries;
CREATE POLICY "Allow select diary_entries"
    ON diary_entries FOR SELECT
    USING (true);

DROP POLICY IF EXISTS "Allow insert diary_entries" ON diary_entries;
CREATE POLICY "Allow insert diary_entries"
    ON diary_entries FOR INSERT
    WITH CHECK (true);

DROP POLICY IF EXISTS "Allow update diary_entries" ON diary_entries;
CREATE POLICY "Allow update diary_entries"
    ON diary_entries FOR UPDATE
    USING (true)
    WITH CHECK (true);

DROP POLICY IF EXISTS "Allow delete diary_entries" ON diary_entries;
CREATE POLICY "Allow delete diary_entries"
    ON diary_entries FOR DELETE
    USING (true);
