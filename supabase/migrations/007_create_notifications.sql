-- Migration: 007_create_notifications.sql
-- Description: Creates the notification_logs table for tracking daily plan notifications dispatched to farmers.
-- Idempotent: Can be executed multiple times safely.

-- 1. Create notification_logs table
CREATE TABLE IF NOT EXISTS notification_logs (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    farmer_id UUID NOT NULL REFERENCES farmers(id) ON DELETE CASCADE,
    batch_id UUID NOT NULL REFERENCES batches(id) ON DELETE CASCADE,
    batch_day INT NOT NULL,
    title TEXT NOT NULL,
    body TEXT NOT NULL,
    status TEXT NOT NULL DEFAULT 'sent' CHECK (status IN ('pending', 'sent', 'failed')),
    metadata JSONB,
    sent_at TIMESTAMPTZ DEFAULT now()
);

-- 2. Indexes for farmer notifications lookup
CREATE INDEX IF NOT EXISTS idx_notification_logs_farmer_id ON notification_logs(farmer_id);
CREATE INDEX IF NOT EXISTS idx_notification_logs_sent_at ON notification_logs(sent_at DESC);
CREATE INDEX IF NOT EXISTS idx_notification_logs_batch_day ON notification_logs(batch_id, batch_day);

-- 3. Row Level Security (RLS)
ALTER TABLE notification_logs ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Allow select notification_logs" ON notification_logs;
CREATE POLICY "Allow select notification_logs"
    ON notification_logs FOR SELECT
    USING (true);

DROP POLICY IF EXISTS "Allow insert notification_logs" ON notification_logs;
CREATE POLICY "Allow insert notification_logs"
    ON notification_logs FOR INSERT
    WITH CHECK (true);
