-- Migration: 002_create_batches.sql
-- Description: Creates the batches table to track poultry flocks for each farmer.
-- Idempotent: Can be executed multiple times safely.

-- 1. Create batches table
CREATE TABLE IF NOT EXISTS batches (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    farmer_id UUID NOT NULL REFERENCES farmers(id) ON DELETE CASCADE,
    arrival_date DATE NOT NULL,
    initial_count INT NOT NULL CHECK (initial_count > 0),
    current_count INT CHECK (current_count IS NULL OR current_count >= 0),
    status TEXT NOT NULL DEFAULT 'active' CHECK (status IN ('active', 'completed', 'abandoned')),
    created_at TIMESTAMPTZ DEFAULT now(),
    updated_at TIMESTAMPTZ DEFAULT now()
);

-- 2. Indexes for batch lookups and status filtering
CREATE INDEX IF NOT EXISTS idx_batches_farmer_id ON batches(farmer_id);
CREATE INDEX IF NOT EXISTS idx_batches_status ON batches(status);
CREATE INDEX IF NOT EXISTS idx_batches_farmer_status ON batches(farmer_id, status);
CREATE INDEX IF NOT EXISTS idx_batches_arrival_date ON batches(arrival_date);

-- 3. Trigger to maintain updated_at
DROP TRIGGER IF EXISTS trg_batches_updated_at ON batches;
CREATE TRIGGER trg_batches_updated_at
    BEFORE UPDATE ON batches
    FOR EACH ROW
    EXECUTE FUNCTION set_updated_at();

-- 4. Row Level Security (RLS)
ALTER TABLE batches ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Allow select batches" ON batches;
CREATE POLICY "Allow select batches"
    ON batches FOR SELECT
    USING (true);

DROP POLICY IF EXISTS "Allow insert batches" ON batches;
CREATE POLICY "Allow insert batches"
    ON batches FOR INSERT
    WITH CHECK (true);

DROP POLICY IF EXISTS "Allow update batches" ON batches;
CREATE POLICY "Allow update batches"
    ON batches FOR UPDATE
    USING (true)
    WITH CHECK (true);

DROP POLICY IF EXISTS "Allow delete batches" ON batches;
CREATE POLICY "Allow delete batches"
    ON batches FOR DELETE
    USING (true);
