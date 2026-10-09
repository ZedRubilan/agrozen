-- Migration: 005_create_course_progress.sql
-- Description: Creates the course_progress table to track farmer progress in educational broiler courses.
-- Idempotent: Can be executed multiple times safely.

-- 1. Create course_progress table
CREATE TABLE IF NOT EXISTS course_progress (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    farmer_id UUID NOT NULL REFERENCES farmers(id) ON DELETE CASCADE,
    lesson_number INT NOT NULL CHECK (lesson_number >= 1),
    quiz_passed BOOLEAN DEFAULT false,
    completed_at TIMESTAMPTZ DEFAULT now(),
    CONSTRAINT uq_farmer_lesson UNIQUE (farmer_id, lesson_number)
);

-- 2. Indexes for user progress queries
CREATE INDEX IF NOT EXISTS idx_course_progress_farmer_id ON course_progress(farmer_id);
CREATE INDEX IF NOT EXISTS idx_course_progress_farmer_lesson ON course_progress(farmer_id, lesson_number);

-- 3. Row Level Security (RLS)
ALTER TABLE course_progress ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Allow select course_progress" ON course_progress;
CREATE POLICY "Allow select course_progress"
    ON course_progress FOR SELECT
    USING (true);

DROP POLICY IF EXISTS "Allow insert course_progress" ON course_progress;
CREATE POLICY "Allow insert course_progress"
    ON course_progress FOR INSERT
    WITH CHECK (true);

DROP POLICY IF EXISTS "Allow update course_progress" ON course_progress;
CREATE POLICY "Allow update course_progress"
    ON course_progress FOR UPDATE
    USING (true)
    WITH CHECK (true);

DROP POLICY IF EXISTS "Allow delete course_progress" ON course_progress;
CREATE POLICY "Allow delete course_progress"
    ON course_progress FOR DELETE
    USING (true);
