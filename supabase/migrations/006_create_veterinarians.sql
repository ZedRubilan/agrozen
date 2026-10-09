-- Migration: 006_create_veterinarians.sql
-- Description: Creates the veterinarians table to store regional veterinary contacts across Uzbekistan.
-- Idempotent: Can be executed multiple times safely.

-- 1. Create veterinarians table
CREATE TABLE IF NOT EXISTS veterinarians (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    district TEXT NOT NULL,
    name TEXT NOT NULL,
    phone TEXT NOT NULL,
    organization TEXT,
    address TEXT,
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMPTZ DEFAULT now()
);

-- 2. Indexes for search by district and name
CREATE INDEX IF NOT EXISTS idx_veterinarians_district ON veterinarians(district);
CREATE INDEX IF NOT EXISTS idx_veterinarians_name ON veterinarians(name);

-- 3. Row Level Security (RLS)
ALTER TABLE veterinarians ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Allow select veterinarians" ON veterinarians;
CREATE POLICY "Allow select veterinarians"
    ON veterinarians FOR SELECT
    USING (true);

DROP POLICY IF EXISTS "Allow insert veterinarians" ON veterinarians;
CREATE POLICY "Allow insert veterinarians"
    ON veterinarians FOR INSERT
    WITH CHECK (true);

DROP POLICY IF EXISTS "Allow update veterinarians" ON veterinarians;
CREATE POLICY "Allow update veterinarians"
    ON veterinarians FOR UPDATE
    USING (true)
    WITH CHECK (true);
