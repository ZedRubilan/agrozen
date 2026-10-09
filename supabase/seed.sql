-- Seed: supabase/seed.sql
-- Description: Idempotent seed data for AgroZen platform (veterinarians, reference test farmers, batches, diary entries, course progress, and Q&A logs).

-- 1. Insert veterinarians from regional network
INSERT INTO veterinarians (id, district, name, phone, organization, address, is_active)
VALUES
    ('v0000001-0000-0000-0000-000000000001', 'Toshkent', 'Dr. Rustam Karimov', '+998901234501', 'Toshkent viloyati Parrandachilik va Veterinariya markazi', 'Toshkent viloyati, Zangiota tumani, Qatortol ko''chasi 14', true),
    ('v0000002-0000-0000-0000-000000000002', 'Samarqand', 'Dr. Jamshid Ergashev', '+998933334502', 'Samarqand Davlat Veterinariya Boshqarmasi', 'Samarqand sh., Mirzo Ulug''bek ko''chasi 45', true),
    ('v0000003-0000-0000-0000-000000000003', 'Buxoro', 'Dr. Alisher Narzullayev', '+998914004503', 'Buxoro Parrandachilik Diagnostika Markazi', 'Buxoro sh., Ibrohim Mo''minov ko''chasi 12', true),
    ('v0000004-0000-0000-0000-000000000004', 'Andijon', 'Dr. Nodirbek Usmonov', '+998902004504', 'Andijon Parranda Salomatligi Xizmati', 'Andijon sh., Bobur shoh ko''chasi 78', true),
    ('v0000005-0000-0000-0000-000000000005', 'Farg''ona', 'Dr. Mansur Qodirov', '+998911504505', 'Farg''ona Viloyati Davlat Veterinariya Bo''limi', 'Farg''ona sh., Al-Farg''oniy ko''chasi 22', true),
    ('v0000006-0000-0000-0000-000000000006', 'Namangan', 'Dr. Salohiddin Mirzayev', '+998932114506', 'Namangan Parrandachilik Ilmiy-Amaliy Markazi', 'Namangan sh., Kosonsoy ko''chasi 5', true),
    ('v0000007-0000-0000-0000-000000000007', 'Qashqadaryo', 'Dr. Baxtiyor Normurodov', '+998973104507', 'Qashqadaryo Veterinariya Diagnostika Laboratoriyasi', 'Qarshi sh., Mustaqillik shoh ko''chasi 33', true),
    ('v0000008-0000-0000-0000-000000000008', 'Surxondaryo', 'Dr. Ilhom Xoliqov', '+998994404508', 'Termiz Parrandachilik Xizmati', 'Termiz sh., At-Termiziy ko''chasi 19', true),
    ('v0000009-0000-0000-0000-000000000009', 'Jizzax', 'Dr. Otabek Sobirov', '+998905504509', 'Jizzax Viloyati Veterinariya Stansiyasi', 'Jizzax sh., Sharof Rashidov ko''chasi 10', true),
    ('v0000010-0000-0000-0000-000000000010', 'Sirdaryo', 'Dr. Farrux Yusupov', '+998916604510', 'Guliston Veterinariya Laboratoriyasi', 'Guliston sh., O''zbekiston ko''chasi 6', true),
    ('v0000011-0000-0000-0000-000000000011', 'Xorazm', 'Dr. Sherzod Matyoqubov', '+998937704511', 'Urganch Parrandachilik Maslahat Markazi', 'Urganch sh., Al-Xorazmiy ko''chasi 15', true),
    ('v0000012-0000-0000-0000-000000000012', 'Navoiy', 'Dr. G''ayrat Hamroyev', '+998792204512', 'Navoiy Parranda Salomatligi Markazi', 'Navoiy sh., G''alaba shoh ko''chasi 8', true),
    ('v0000013-0000-0000-0000-000000000013', 'Qoraqalpog''iston', 'Dr. Azamat Seytov', '+998612204513', 'Qoraqalpog''iston Respublikasi Veterinariya Qo''mitasi', 'Nukus sh., Dosliq guzari 52', true)
ON CONFLICT (id) DO UPDATE SET
    district = EXCLUDED.district,
    name = EXCLUDED.name,
    phone = EXCLUDED.phone,
    organization = EXCLUDED.organization,
    address = EXCLUDED.address;

-- 2. Insert test farmers
INSERT INTO farmers (id, phone, name, language, district, disclaimer_accepted, daily_question_count, last_question_date, created_at)
VALUES
    ('11111111-1111-1111-1111-111111111111', '+998901112233', 'Anvar Rahimov', 'uz', 'Toshkent', true, 2, CURRENT_DATE, now() - INTERVAL '10 days'),
    ('22222222-2222-2222-2222-222222222222', '+998934445566', 'Дмитрий Ким', 'ru', 'Samarqand', true, 0, CURRENT_DATE - INTERVAL '1 day', now() - INTERVAL '20 days'),
    ('33333333-3333-3333-3333-333333333333', '+998917778899', 'Otabek Yoqubov', 'uz', 'Andijon', true, 1, CURRENT_DATE, now() - INTERVAL '60 days')
ON CONFLICT (id) DO UPDATE SET
    phone = EXCLUDED.phone,
    name = EXCLUDED.name,
    language = EXCLUDED.language,
    district = EXCLUDED.district,
    disclaimer_accepted = EXCLUDED.disclaimer_accepted;

-- 3. Insert test batches
INSERT INTO batches (id, farmer_id, arrival_date, initial_count, current_count, status, created_at)
VALUES
    -- Farmer 1 active batch: day 7 today (arrival 6 days ago)
    ('aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa', '11111111-1111-1111-1111-111111111111', CURRENT_DATE - 6, 1000, 988, 'active', now() - INTERVAL '6 days'),
    -- Farmer 2 active batch: day 14 today (arrival 13 days ago)
    ('bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb', '22222222-2222-2222-2222-222222222222', CURRENT_DATE - 13, 2500, 2460, 'active', now() - INTERVAL '13 days'),
    -- Farmer 3 completed historical batch
    ('cccccccc-cccc-cccc-cccc-cccccccccccc', '33333333-3333-3333-3333-333333333333', CURRENT_DATE - 50, 1500, 1455, 'completed', now() - INTERVAL '50 days')
ON CONFLICT (id) DO UPDATE SET
    status = EXCLUDED.status,
    current_count = EXCLUDED.current_count,
    initial_count = EXCLUDED.initial_count,
    arrival_date = EXCLUDED.arrival_date;

-- 4. Insert sample diary entries for Batch 1 (Anvar Rahimov - 1000 broilers)
INSERT INTO diary_entries (batch_id, entry_date, entry_type, value, notes)
VALUES
    -- Day 1
    ('aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa', CURRENT_DATE - 6, 'mortality', 3, 'Tashish vaqtida nobud bo''lgan zaif jo''jalar'),
    ('aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa', CURRENT_DATE - 6, 'feed', 12.0, 'Start kombikorm berildi'),
    ('aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa', CURRENT_DATE - 6, 'weight', 42.0, 'Kelgandagi o''rtacha vazn'),
    -- Day 2
    ('aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa', CURRENT_DATE - 5, 'mortality', 2, 'Bruder ostida'),
    ('aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa', CURRENT_DATE - 5, 'feed', 15.0, 'Suvga vitamin qo''shildi'),
    -- Day 3
    ('aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa', CURRENT_DATE - 4, 'mortality', 2, 'Kuchsiz jo''jalar ajratildi'),
    ('aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa', CURRENT_DATE - 4, 'feed', 18.5, 'Normal ishtaha'),
    -- Day 4
    ('aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa', CURRENT_DATE - 3, 'mortality', 1, 'Tabiiy nobudlik'),
    ('aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa', CURRENT_DATE - 3, 'feed', 22.0, 'Bunker yemdonlarga o''tildi'),
    ('aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa', CURRENT_DATE - 3, 'weight', 91.5, '4-kun nazorat tortish'),
    -- Day 5
    ('aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa', CURRENT_DATE - 2, 'mortality', 2, 'Podstilka tekshirildi'),
    ('aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa', CURRENT_DATE - 2, 'feed', 27.0, 'Yem yaxshi yeyilmoqda'),
    -- Day 6
    ('aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa', CURRENT_DATE - 1, 'mortality', 2, 'Emlashga tayyorgarlik'),
    ('aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa', CURRENT_DATE - 1, 'feed', 32.0, 'Shamollatish tekshirildi'),
    -- Day 7 (Today)
    ('aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa', CURRENT_DATE, 'weight', 186.0, '1-hafta yakuniy tortish (normada)')
ON CONFLICT DO NOTHING;

-- 5. Insert sample question logs
INSERT INTO question_logs (farmer_id, question, answer, topics_used, language, source)
VALUES
    (
        '11111111-1111-1111-1111-111111111111',
        '1 haftalik jo''jalar uchun xona harorati necha daraja bo''lishi kerak?',
        'Ross-308 / Cobb-500 reglamentiga ko''ra, 1-hafta (1–7 kun) yakunida xona harorati 29–30°C darajada saqlanishi tavsiya etiladi. Jo''jalarning xatti-harakatini kuzating: agar jo''jalar butun maydon bo''ylab erkin tarqalgan bo''lsa, harorat ideal. Agar guruhlanib to''plansa sovuq, og''zini ochib hansirasa issiq hisoblanadi.',
        ARRAY['03_harorat', 'temperature.md'],
        'uz',
        'text'
    ),
    (
        '22222222-2222-2222-2222-222222222222',
        'Какая суточная норма корма на одного цыпленка на 2-й неделе?',
        'По нормативам для бройлеров кроссов Ross-308 / Cobb-500 на 2-й неделе жизни (дни 8–14) среднесуточная норма расхода корма составляет около 54 грамм на голову в сутки. К 14-му дню суммарное потребление корма одним цыпленком достигает примерно 475 грамм. Обеспечьте постоянный доступ к чистой свежей воде.',
        ARRAY['05_feeding', 'feed.md'],
        'ru',
        'text'
    )
ON CONFLICT DO NOTHING;

-- 6. Insert sample course progress
INSERT INTO course_progress (farmer_id, lesson_number, quiz_passed, completed_at)
VALUES
    ('11111111-1111-1111-1111-111111111111', 1, true, now() - INTERVAL '5 days'),
    ('11111111-1111-1111-1111-111111111111', 2, true, now() - INTERVAL '3 days'),
    ('22222222-2222-2222-2222-222222222222', 1, true, now() - INTERVAL '10 days')
ON CONFLICT (farmer_id, lesson_number) DO UPDATE SET
    quiz_passed = EXCLUDED.quiz_passed,
    completed_at = EXCLUDED.completed_at;

-- 7. Insert sample notification logs
INSERT INTO notification_logs (farmer_id, batch_id, batch_day, title, body, status, sent_at)
VALUES
    (
        '11111111-1111-1111-1111-111111111111',
        'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa',
        7,
        'Broyler parvarishi: 7-kun vazifalari',
        '1-hafta yakuni. Jo''jalarni tortish (Ross-308/Cobb-500 normasi: 180-200 g). Ichirish usuli bilan birinchi rejali emlash. Harorat 29°C.',
        'sent',
        now() - INTERVAL '2 hours'
    )
ON CONFLICT DO NOTHING;
