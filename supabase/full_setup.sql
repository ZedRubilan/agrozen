CREATE EXTENSION IF NOT EXISTS "pgcrypto"; 

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

CREATE INDEX IF NOT EXISTS idx_farmers_phone ON farmers(phone); 
CREATE INDEX IF NOT EXISTS idx_farmers_district ON farmers(district); 
CREATE INDEX IF NOT EXISTS idx_farmers_last_question_date ON farmers(last_question_date); 

CREATE OR REPLACE FUNCTION set_updated_at() RETURNS TRIGGER AS $$ 
BEGIN 
    NEW.updated_at = now(); 
    RETURN NEW; 
END; 
$$ LANGUAGE plpgsql; 

DROP TRIGGER IF EXISTS trg_farmers_updated_at ON farmers; 
CREATE TRIGGER trg_farmers_updated_at BEFORE UPDATE ON farmers FOR EACH ROW EXECUTE FUNCTION set_updated_at(); 

CREATE OR REPLACE FUNCTION check_and_increment_daily_questions( 
    p_farmer_id UUID, 
    p_daily_limit INT DEFAULT 30, 
    p_max_daily INT DEFAULT NULL 
) RETURNS TABLE ( 
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

    IF v_farmer.last_question_date IS NULL OR v_farmer.last_question_date < v_today THEN 
        v_new_count := 1; 
        UPDATE farmers SET daily_question_count = v_new_count, last_question_date = v_today, updated_at = now() WHERE id = p_farmer_id; 
        RETURN QUERY SELECT true, v_new_count, (v_limit - v_new_count), 'OK'::TEXT; 
        RETURN; 
    END IF; 

    IF v_farmer.daily_question_count >= v_limit THEN 
        RETURN QUERY SELECT false, v_farmer.daily_question_count, 0, 'Daily question limit reached'::TEXT; 
        RETURN; 
    ELSE 
        v_new_count := v_farmer.daily_question_count + 1; 
        UPDATE farmers SET daily_question_count = v_new_count, last_question_date = v_today, updated_at = now() WHERE id = p_farmer_id; 
        RETURN QUERY SELECT true, v_new_count, (v_limit - v_new_count), 'OK'::TEXT; 
        RETURN; 
    END IF; 
END; 
$$ LANGUAGE plpgsql SECURITY DEFINER; 

ALTER TABLE farmers ENABLE ROW LEVEL SECURITY; 
DROP POLICY IF EXISTS "Allow select farmers" ON farmers; 
CREATE POLICY "Allow select farmers" ON farmers FOR SELECT USING (true); 
DROP POLICY IF EXISTS "Allow insert farmers" ON farmers; 
CREATE POLICY "Allow insert farmers" ON farmers FOR INSERT WITH CHECK (true); 
DROP POLICY IF EXISTS "Allow update farmers" ON farmers; 
CREATE POLICY "Allow update farmers" ON farmers FOR UPDATE USING (true) WITH CHECK (true); 
DROP POLICY IF EXISTS "Allow delete farmers" ON farmers; 
CREATE POLICY "Allow delete farmers" ON farmers FOR DELETE USING (true); 

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

CREATE INDEX IF NOT EXISTS idx_batches_farmer_id ON batches(farmer_id); 
CREATE INDEX IF NOT EXISTS idx_batches_status ON batches(status); 
CREATE INDEX IF NOT EXISTS idx_batches_farmer_status ON batches(farmer_id, status); 
CREATE INDEX IF NOT EXISTS idx_batches_arrival_date ON batches(arrival_date); 

DROP TRIGGER IF EXISTS trg_batches_updated_at ON batches; 
CREATE TRIGGER trg_batches_updated_at BEFORE UPDATE ON batches FOR EACH ROW EXECUTE FUNCTION set_updated_at(); 

ALTER TABLE batches ENABLE ROW LEVEL SECURITY; 
DROP POLICY IF EXISTS "Allow select batches" ON batches; 
CREATE POLICY "Allow select batches" ON batches FOR SELECT USING (true); 
DROP POLICY IF EXISTS "Allow insert batches" ON batches; 
CREATE POLICY "Allow insert batches" ON batches FOR INSERT WITH CHECK (true); 
DROP POLICY IF EXISTS "Allow update batches" ON batches; 
CREATE POLICY "Allow update batches" ON batches FOR UPDATE USING (true) WITH CHECK (true); 
DROP POLICY IF EXISTS "Allow delete batches" ON batches; 
CREATE POLICY "Allow delete batches" ON batches FOR DELETE USING (true); 

CREATE TABLE IF NOT EXISTS diary_entries ( 
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(), 
    batch_id UUID NOT NULL REFERENCES batches(id) ON DELETE CASCADE, 
    entry_date DATE NOT NULL DEFAULT CURRENT_DATE, 
    entry_type TEXT NOT NULL CHECK (entry_type IN ('mortality', 'feed', 'weight')), 
    value NUMERIC NOT NULL CHECK (value >= 0), 
    notes TEXT, 
    created_at TIMESTAMPTZ DEFAULT now() 
); 

CREATE INDEX IF NOT EXISTS idx_diary_entries_batch_id ON diary_entries(batch_id); 
CREATE INDEX IF NOT EXISTS idx_diary_entries_entry_date ON diary_entries(entry_date); 
CREATE INDEX IF NOT EXISTS idx_diary_entries_entry_type ON diary_entries(entry_type); 
CREATE INDEX IF NOT EXISTS idx_diary_entries_batch_date_type ON diary_entries(batch_id, entry_date, entry_type); 

CREATE OR REPLACE FUNCTION sync_batch_current_count() RETURNS TRIGGER AS $$ 
DECLARE 
    v_total_mortality NUMERIC; 
    v_initial_count INT; 
BEGIN 
    IF TG_OP = 'DELETE' THEN 
        IF OLD.entry_type = 'mortality' THEN 
            SELECT initial_count INTO v_initial_count FROM batches WHERE id = OLD.batch_id; 
            IF FOUND THEN 
                SELECT COALESCE(SUM(value), 0) INTO v_total_mortality FROM diary_entries WHERE batch_id = OLD.batch_id AND entry_type = 'mortality'; 
                UPDATE batches SET current_count = GREATEST(0, v_initial_count - v_total_mortality::INT), updated_at = now() WHERE id = OLD.batch_id; 
            END IF; 
        END IF; 
    ELSIF TG_OP = 'INSERT' THEN 
        IF NEW.entry_type = 'mortality' THEN 
            SELECT initial_count INTO v_initial_count FROM batches WHERE id = NEW.batch_id; 
            IF FOUND THEN 
                SELECT COALESCE(SUM(value), 0) INTO v_total_mortality FROM diary_entries WHERE batch_id = NEW.batch_id AND entry_type = 'mortality'; 
                UPDATE batches SET current_count = GREATEST(0, v_initial_count - v_total_mortality::INT), updated_at = now() WHERE id = NEW.batch_id; 
            END IF; 
        END IF; 
    ELSIF TG_OP = 'UPDATE' THEN 
        IF OLD.entry_type = 'mortality' OR NEW.entry_type = 'mortality' THEN 
            SELECT initial_count INTO v_initial_count FROM batches WHERE id = NEW.batch_id; 
            IF FOUND THEN 
                SELECT COALESCE(SUM(value), 0) INTO v_total_mortality FROM diary_entries WHERE batch_id = NEW.batch_id AND entry_type = 'mortality'; 
                UPDATE batches SET current_count = GREATEST(0, v_initial_count - v_total_mortality::INT), updated_at = now() WHERE id = NEW.batch_id; 
            END IF; 
            IF OLD.batch_id IS DISTINCT FROM NEW.batch_id THEN 
                SELECT initial_count INTO v_initial_count FROM batches WHERE id = OLD.batch_id; 
                IF FOUND THEN 
                    SELECT COALESCE(SUM(value), 0) INTO v_total_mortality FROM diary_entries WHERE batch_id = OLD.batch_id AND entry_type = 'mortality'; 
                    UPDATE batches SET current_count = GREATEST(0, v_initial_count - v_total_mortality::INT), updated_at = now() WHERE id = OLD.batch_id; 
                END IF; 
            END IF; 
        END IF; 
    END IF; 
    RETURN NULL; 
END; 
$$ LANGUAGE plpgsql; 

DROP TRIGGER IF EXISTS trg_sync_batch_mortality ON diary_entries; 
CREATE TRIGGER trg_sync_batch_mortality AFTER INSERT OR UPDATE OR DELETE ON diary_entries FOR EACH ROW EXECUTE FUNCTION sync_batch_current_count(); 

ALTER TABLE diary_entries ENABLE ROW LEVEL SECURITY; 
DROP POLICY IF EXISTS "Allow select diary_entries" ON diary_entries; 
CREATE POLICY "Allow select diary_entries" ON diary_entries FOR SELECT USING (true); 
DROP POLICY IF EXISTS "Allow insert diary_entries" ON diary_entries; 
CREATE POLICY "Allow insert diary_entries" ON diary_entries FOR INSERT WITH CHECK (true); 
DROP POLICY IF EXISTS "Allow update diary_entries" ON diary_entries; 
CREATE POLICY "Allow update diary_entries" ON diary_entries FOR UPDATE USING (true) WITH CHECK (true); 
DROP POLICY IF EXISTS "Allow delete diary_entries" ON diary_entries; 
CREATE POLICY "Allow delete diary_entries" ON diary_entries FOR DELETE USING (true); 

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

CREATE INDEX IF NOT EXISTS idx_question_logs_farmer_id ON question_logs(farmer_id); 
CREATE INDEX IF NOT EXISTS idx_question_logs_created_at ON question_logs(created_at DESC); 
CREATE INDEX IF NOT EXISTS idx_question_logs_farmer_created ON question_logs(farmer_id, created_at DESC); 
CREATE INDEX IF NOT EXISTS idx_question_logs_source ON question_logs(source); 
CREATE INDEX IF NOT EXISTS idx_question_logs_language ON question_logs(language); 

ALTER TABLE question_logs ENABLE ROW LEVEL SECURITY; 
DROP POLICY IF EXISTS "Allow select question_logs" ON question_logs; 
CREATE POLICY "Allow select question_logs" ON question_logs FOR SELECT USING (true); 
DROP POLICY IF EXISTS "Allow insert question_logs" ON question_logs; 
CREATE POLICY "Allow insert question_logs" ON question_logs FOR INSERT WITH CHECK (true); 
DROP POLICY IF EXISTS "Allow update question_logs" ON question_logs; 
CREATE POLICY "Allow update question_logs" ON question_logs FOR UPDATE USING (true) WITH CHECK (true); 
DROP POLICY IF EXISTS "Allow delete question_logs" ON question_logs; 
CREATE POLICY "Allow delete question_logs" ON question_logs FOR DELETE USING (true); 

CREATE TABLE IF NOT EXISTS course_progress ( 
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(), 
    farmer_id UUID NOT NULL REFERENCES farmers(id) ON DELETE CASCADE, 
    lesson_number INT NOT NULL CHECK (lesson_number >= 1), 
    quiz_passed BOOLEAN DEFAULT false, 
    completed_at TIMESTAMPTZ DEFAULT now(), 
    CONSTRAINT uq_farmer_lesson UNIQUE (farmer_id, lesson_number) 
); 

CREATE INDEX IF NOT EXISTS idx_course_progress_farmer_id ON course_progress(farmer_id); 
CREATE INDEX IF NOT EXISTS idx_course_progress_farmer_lesson ON course_progress(farmer_id, lesson_number); 

ALTER TABLE course_progress ENABLE ROW LEVEL SECURITY; 
DROP POLICY IF EXISTS "Allow select course_progress" ON course_progress; 
CREATE POLICY "Allow select course_progress" ON course_progress FOR SELECT USING (true); 
DROP POLICY IF EXISTS "Allow insert course_progress" ON course_progress; 
CREATE POLICY "Allow insert course_progress" ON course_progress FOR INSERT WITH CHECK (true); 
DROP POLICY IF EXISTS "Allow update course_progress" ON course_progress; 
CREATE POLICY "Allow update course_progress" ON course_progress FOR UPDATE USING (true) WITH CHECK (true); 
DROP POLICY IF EXISTS "Allow delete course_progress" ON course_progress; 
CREATE POLICY "Allow delete course_progress" ON course_progress FOR DELETE USING (true); 

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

CREATE INDEX IF NOT EXISTS idx_veterinarians_district ON veterinarians(district); 
CREATE INDEX IF NOT EXISTS idx_veterinarians_name ON veterinarians(name); 

ALTER TABLE veterinarians ENABLE ROW LEVEL SECURITY; 
DROP POLICY IF EXISTS "Allow select veterinarians" ON veterinarians; 
CREATE POLICY "Allow select veterinarians" ON veterinarians FOR SELECT USING (true); 
DROP POLICY IF EXISTS "Allow insert veterinarians" ON veterinarians; 
CREATE POLICY "Allow insert veterinarians" ON veterinarians FOR INSERT TO service_role WITH CHECK (auth.role() = 'service_role'); 
DROP POLICY IF EXISTS "Allow update veterinarians" ON veterinarians; 
CREATE POLICY "Allow update veterinarians" ON veterinarians FOR UPDATE TO service_role USING (auth.role() = 'service_role') WITH CHECK (auth.role() = 'service_role'); 

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

CREATE INDEX IF NOT EXISTS idx_notification_logs_farmer_id ON notification_logs(farmer_id); 
CREATE INDEX IF NOT EXISTS idx_notification_logs_sent_at ON notification_logs(sent_at DESC); 
CREATE INDEX IF NOT EXISTS idx_notification_logs_batch_day ON notification_logs(batch_id, batch_day); 

ALTER TABLE notification_logs ENABLE ROW LEVEL SECURITY; 
DROP POLICY IF EXISTS "Allow select notification_logs" ON notification_logs; 
CREATE POLICY "Allow select notification_logs" ON notification_logs FOR SELECT USING (true); 
DROP POLICY IF EXISTS "Allow insert notification_logs" ON notification_logs; 
CREATE POLICY "Allow insert notification_logs" ON notification_logs FOR INSERT TO service_role WITH CHECK (auth.role() = 'service_role'); 
DROP POLICY IF EXISTS "Allow update notification_logs" ON notification_logs; 
CREATE POLICY "Allow update notification_logs" ON notification_logs FOR UPDATE TO service_role USING (auth.role() = 'service_role') WITH CHECK (auth.role() = 'service_role'); 

INSERT INTO veterinarians (id, district, name, phone, organization, address, is_active) 
VALUES 
    ('f0000001-0000-0000-0000-000000000001', 'Toshkent', 'Dr. Rustam Karimov', '+998901234501', 'Toshkent viloyati Parrandachilik va Veterinariya markazi', 'Toshkent viloyati, Zangiota tumani, Qatortol ko''chasi 14', true), 
    ('f0000002-0000-0000-0000-000000000002', 'Samarqand', 'Dr. Jamshid Ergashev', '+998933334502', 'Samarqand Davlat Veterinariya Boshqarmasi', 'Samarqand sh., Mirzo Ulug''bek ko''chasi 45', true), 
    ('f0000003-0000-0000-0000-000000000003', 'Buxoro', 'Dr. Alisher Narzullayev', '+998914004503', 'Buxoro Parrandachilik Diagnostika Markazi', 'Buxoro sh., Ibrohim Mo''minov ko''chasi 12', true), 
    ('f0000004-0000-0000-0000-000000000004', 'Andijon', 'Dr. Nodirbek Usmonov', '+998902004504', 'Andijon Parranda Salomatligi Xizmati', 'Andijon sh., Bobur shoh ko''chasi 78', true), 
    ('f0000005-0000-0000-0000-000000000005', 'Farg''ona', 'Dr. Mansur Qodirov', '+998911504505', 'Farg''ona Viloyati Davlat Veterinariya Bo''limi', 'Farg''ona sh., Al-Farg''oniy ko''chasi 22', true), 
    ('f0000006-0000-0000-0000-000000000006', 'Namangan', 'Dr. Salohiddin Mirzayev', '+998932114506', 'Namangan Parrandachilik Ilmiy-Amaliy Markazi', 'Namangan sh., Kosonsoy ko''chasi 5', true), 
    ('f0000007-0000-0000-0000-000000000007', 'Qashqadaryo', 'Dr. Baxtiyor Normurodov', '+998973104507', 'Qashqadaryo Veterinariya Diagnostika Laboratoriyasi', 'Qarshi sh., Mustaqillik shoh ko''chasi 33', true), 
    ('f0000008-0000-0000-0000-000000000008', 'Surxondaryo', 'Dr. Ilhom Xoliqov', '+998994404508', 'Termiz Parrandachilik Xizmati', 'Termiz sh., At-Termiziy ko''chasi 19', true), 
    ('f0000009-0000-0000-0000-000000000009', 'Jizzax', 'Dr. Otabek Sobirov', '+998905504509', 'Jizzax Viloyati Veterinariya Stansiyasi', 'Jizzax sh., Sharof Rashidov ko''chasi 10', true), 
    ('f0000010-0000-0000-0000-000000000010', 'Sirdaryo', 'Dr. Farrux Yusupov', '+998916604510', 'Guliston Veterinariya Laboratoriyasi', 'Guliston sh., O''zbekiston ko''chasi 6', true), 
    ('f0000011-0000-0000-0000-000000000011', 'Xorazm', 'Dr. Sherzod Matyoqubov', '+998937704511', 'Urganch Parrandachilik Maslahat Markazi', 'Urganch sh., Al-Xorazmiy ko''chasi 15', true), 
    ('f0000012-0000-0000-0000-000000000012', 'Navoiy', 'Dr. G''ayrat Hamroyev', '+998792204512', 'Navoiy Parranda Salomatligi Markazi', 'Navoiy sh., G''alaba shoh ko''chasi 8', true), 
    ('f0000013-0000-0000-0000-000000000013', 'Qoraqalpog''iston', 'Dr. Azamat Seytov', '+998612204513', 'Qoraqalpog''iston Respublikasi Veterinariya Qo''mitasi', 'Nukus sh., Dosliq guzari 52', true) 
ON CONFLICT (id) DO UPDATE SET 
    district = EXCLUDED.district, 
    name = EXCLUDED.name, 
    phone = EXCLUDED.phone, 
    organization = EXCLUDED.organization, 
    address = EXCLUDED.address; 

INSERT INTO farmers (id, phone, name, language, district, disclaimer_accepted, daily_question_count, last_question_date, created_at) 
VALUES 
    ('11111111-1111-1111-1111-111111111111', '+998901112233', 'Anvar Rahimov', 'uz', 'Toshkent', true, 2, CURRENT_DATE, now() - INTERVAL '10 days'), 
    ('22222222-2222-2222-2222-222222222222', '+998934445566', 'Dmitriy Kim', 'ru', 'Samarqand', true, 0, CURRENT_DATE - INTERVAL '1 day', now() - INTERVAL '20 days'), 
    ('33333333-3333-3333-3333-333333333333', '+998917778899', 'Otabek Yoqubov', 'uz', 'Andijon', true, 1, CURRENT_DATE, now() - INTERVAL '60 days') 
ON CONFLICT (id) DO UPDATE SET 
    phone = EXCLUDED.phone, 
    name = EXCLUDED.name, 
    language = EXCLUDED.language, 
    district = EXCLUDED.district, 
    disclaimer_accepted = EXCLUDED.disclaimer_accepted; 

INSERT INTO batches (id, farmer_id, arrival_date, initial_count, current_count, status, created_at) 
VALUES 
    ('aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa', '11111111-1111-1111-1111-111111111111', CURRENT_DATE - 6, 1000, 988, 'active', now() - INTERVAL '6 days'), 
    ('bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb', '22222222-2222-2222-2222-222222222222', CURRENT_DATE - 13, 2500, 2460, 'active', now() - INTERVAL '13 days'), 
    ('cccccccc-cccc-cccc-cccc-cccccccccccc', '33333333-3333-3333-3333-333333333333', CURRENT_DATE - 50, 1500, 1455, 'completed', now() - INTERVAL '50 days') 
ON CONFLICT (id) DO UPDATE SET 
    status = EXCLUDED.status, 
    current_count = EXCLUDED.current_count, 
    initial_count = EXCLUDED.initial_count, 
    arrival_date = EXCLUDED.arrival_date; 

INSERT INTO diary_entries (id, batch_id, entry_date, entry_type, value, notes) 
VALUES 
    ('d0000001-0000-0000-0000-000000000001', 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa', CURRENT_DATE - 6, 'mortality', 3, 'Tashish vaqtida nobud bo''lgan zaif jo''jalar'), 
    ('d0000002-0000-0000-0000-000000000002', 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa', CURRENT_DATE - 6, 'feed', 12.0, 'Start kombikorm berildi'), 
    ('d0000003-0000-0000-0000-000000000003', 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa', CURRENT_DATE - 6, 'weight', 42.0, 'Kelgandagi o''rtacha vazn'), 
    ('d0000004-0000-0000-0000-000000000004', 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa', CURRENT_DATE - 5, 'mortality', 2, 'Bruder ostida'), 
    ('d0000005-0000-0000-0000-000000000005', 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa', CURRENT_DATE - 5, 'feed', 15.0, 'Suvga vitamin qo''shildi'), 
    ('d0000006-0000-0000-0000-000000000006', 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa', CURRENT_DATE - 4, 'mortality', 2, 'Kuchsiz jo''jalar ajratildi'), 
    ('d0000007-0000-0000-0000-000000000007', 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa', CURRENT_DATE - 4, 'feed', 18.5, 'Normal ishtaha'), 
    ('d0000008-0000-0000-0000-000000000008', 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa', CURRENT_DATE - 3, 'mortality', 1, 'Tabiiy nobudlik'), 
    ('d0000009-0000-0000-0000-000000000009', 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa', CURRENT_DATE - 3, 'feed', 22.0, 'Bunker yemdonlarga o''tildi'), 
    ('d0000010-0000-0000-0000-000000000010', 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa', CURRENT_DATE - 3, 'weight', 91.5, '4-kun nazorat tortish'), 
    ('d0000011-0000-0000-0000-000000000011', 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa', CURRENT_DATE - 2, 'mortality', 2, 'Podstilka tekshirildi'), 
    ('d0000012-0000-0000-0000-000000000002', 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa', CURRENT_DATE - 2, 'feed', 27.0, 'Yem yaxshi yeyilmoqda'), 
    ('d0000013-0000-0000-0000-000000000013', 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa', CURRENT_DATE - 1, 'mortality', 2, 'Emlashga tayyorgarlik'), 
    ('d0000014-0000-0000-0000-000000000014', 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa', CURRENT_DATE - 1, 'feed', 32.0, 'Shamollatish tekshirildi'), 
    ('d0000015-0000-0000-0000-000000000015', 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa', CURRENT_DATE, 'weight', 186.0, '1-hafta yakuniy tortish (normada)') 
ON CONFLICT (id) DO NOTHING; 

INSERT INTO question_logs (id, farmer_id, question, answer, topics_used, language, source) 
VALUES 
    ('c0000001-0000-0000-0000-000000000001', '11111111-1111-1111-1111-111111111111', '1 haftalik jo''jalar uchun xona harorati necha daraja bo''lishi kerak?', 'Ross-308 reglamentiga ko''ra, 1-hafta (1-7 kun) yakunida xona harorati 29-30 darajada saqlanishi tavsiya etiladi.', ARRAY['03_harorat', 'temperature.md'], 'uz', 'text'), 
    ('c0000002-0000-0000-0000-000000000002', '22222222-2222-2222-2222-222222222222', 'Norma korma na odnogo tsyplenka na 2-y nedele?', 'Na 2-y nedele zhizni norma raskhoda korma sostavlyaet okolo 54 gramm na golovu v sutki.', ARRAY['05_feeding', 'feed.md'], 'ru', 'text') 
ON CONFLICT (id) DO NOTHING; 

INSERT INTO course_progress (farmer_id, lesson_number, quiz_passed, completed_at) 
VALUES 
    ('11111111-1111-1111-1111-111111111111', 1, true, now() - INTERVAL '5 days'), 
    ('11111111-1111-1111-1111-111111111111', 2, true, now() - INTERVAL '3 days'), 
    ('22222222-2222-2222-2222-222222222222', 1, true, now() - INTERVAL '10 days') 
ON CONFLICT (farmer_id, lesson_number) DO UPDATE SET 
    quiz_passed = EXCLUDED.quiz_passed, 
    completed_at = EXCLUDED.completed_at; 

INSERT INTO notification_logs (id, farmer_id, batch_id, batch_day, title, body, status, sent_at) 
VALUES 
    ('e0000001-0000-0000-0000-000000000001', '11111111-1111-1111-1111-111111111111', 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa', 7, 'Broyler parvarishi: 7-kun vazifalari', '1-hafta yakuni. Jo''jalarni tortish (Ross-308 normasi: 180-200 g). Ichirish usuli bilan birinchi rejali emlash. Harorat 29C.', 'sent', now() - INTERVAL '2 hours') 
ON CONFLICT (id) DO NOTHING; 
