-- Migration: 004_create_question_logs.sql
-- Description: Creates the question_logs table to log Q&A interactions, sources used, and audio transcriptions.
-- Idempotent: Can be executed multiple times safely.

-- 1. Create question_logs table
CREATE TABLE IF NOT EXISTS question_logs (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    farmer_id UUID REFERENCES farmers(id) ON DELETE SET NULL,
    question TEXT NOT NULL,
    answer TEXT,
    topics_used TEXT[],
    language TEXT NOT NULL DEFAULT 'uz' CHECK (language IN ('uz', 'ru', 'en')),
    source TEXT NOT NULL DEFAULT 'text' CHECK (source IN ('text', 'voice')),
    transcribed_text TEXT,
    created_at TIMESTAMPTZ DEFAULT now()
);

-- 2. Indexes for farmer query history and analysis
CREATE INDEX IF NOT EXISTS idx_question_logs_farmer_id ON question_logs(farmer_id);
CREATE INDEX IF NOT EXISTS idx_question_logs_created_at ON question_logs(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_question_logs_farmer_created ON question_logs(farmer_id, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_question_logs_source ON question_logs(source);
CREATE INDEX IF NOT EXISTS idx_question_logs_language ON question_logs(language);

-- 3. Row Level Security (RLS)
ALTER TABLE question_logs ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Allow select question_logs" ON question_logs;
CREATE POLICY "Allow select question_logs"
    ON question_logs FOR SELECT
    USING (true);

DROP POLICY IF EXISTS "Allow insert question_logs" ON question_logs;
CREATE POLICY "Allow insert question_logs"
    ON question_logs FOR INSERT
    WITH CHECK (true);

DROP POLICY IF EXISTS "Allow update question_logs" ON question_logs;
CREATE POLICY "Allow update question_logs"
    ON question_logs FOR UPDATE
    USING (true)
    WITH CHECK (true);

DROP POLICY IF EXISTS "Allow delete question_logs" ON question_logs;
CREATE POLICY "Allow delete question_logs"
    ON question_logs FOR DELETE
    USING (true);
