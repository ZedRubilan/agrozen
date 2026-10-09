# AgroZen 🐔🌱

**AgroZen** — AI-powered mobile assistant for beginner poultry farmers (broilers) in Uzbekistan.

> O'zbekiston parrandachilari uchun sun'iy intellektga asoslangan aqlli mobil yordamchi. Ross-308 va Cobb-500 xalqaro standartlari hamda mahalliy tajribaga asoslangan.

---

## 📱 Features

1. **Daily Plan & Care Instructions (Kunlik reja 1–42 kun)**
   - Day-by-day tasks based on the batch arrival date.
   - Temperature recommendations for each growth phase.
   - Stage guidance (Start, Growth, Finish).
   - Curated instructional videos for critical milestones.

2. **Batch Diary & Real-time Alerts (Partiya kundaligi va Ogohlantirishlar)**
   - One-tap recording for **Mortality (Nobodlik)**, **Feed Intake (Yem)**, and **Weight (Vazn)**.
   - **Deterministic Alert Engine (No AI hallucinations)**: Automatically evaluates daily mortality (>1%) and weight deviations (>15% below target).
   - Instant emergency call button connecting the farmer directly to certified local poultry veterinarians across all 13 regions of Uzbekistan.

3. **AI Agricultural Q&A with RAG (Sun'iy Intellekt Maslahatchi)**
   - Context-grounded Q&A utilizing vet-verified knowledge base articles.
   - Strictly obeys safety constraints: **never prescribes antibiotics or medicines**, refers farmers to veterinarians for disease diagnosis.
   - Supports voice input (Speech-to-Text) in Uzbek and Russian.
   - Daily rate-limiting (30 questions/day) to control API consumption.

4. **Pre-Credit Training Course & Certificate (Kreditdan oldingi kurs va Sertifikat)**
   - 5 bite-sized interactive lessons covering sanitation, brooding, climate control, feeding phases, and biosecurity.
   - Knowledge quizzes with instant feedback after each lesson.
   - Official readiness certificate for banks and microfinance organizations upon course completion.

5. **Bilingual Support (Ikki tilli interfeys)**
   - Full support for **O'zbekcha (Lotin)** and **Русский**.

---

## 🛠️ Architecture & Tech Stack

```
Mobile Client (Flutter) ──► Supabase Backend (PostgreSQL + RLS)
                             ├── Edge Functions (Deno / TS)
                             │     ├── ask-question (RAG + Gemini 2.5 Flash)
                             │     ├── transcribe-voice (STT)
                             │     └── send-daily-plan (pg_cron 7:00 AM)
                             └── Knowledge Base Assets
```

- **Client**: Flutter 3.44+ (Android, iOS, Web)
- **State Management**: `flutter_bloc`
- **Routing**: `go_router`
- **Backend**: Supabase (PostgreSQL 15+, Row Level Security, Edge Functions)
- **AI Models**: Google Gemini 2.5 Flash via Edge Functions
- **Speech-to-Text**: Google Cloud STT / Whisper swappable adapter
- **Testing**: 87 automated unit, repository, domain, and widget tests

---

## 📂 Project Structure

```
agrozen/
├── lib/
│   ├── app.dart                   # MaterialApp, routing & localization
│   ├── main.dart                  # App entry point
│   ├── config/                    # Theme, SupabaseConfig & AppConstants
│   ├── data/
│   │   ├── models/                # Farmer, Batch, DiaryEntry, DailyPlan, etc.
│   │   ├── providers/             # Supabase & AI providers
│   │   └── repositories/          # Auth, Farmer, Batch, Diary, Knowledge, Course
│   ├── domain/
│   │   ├── alerts/                # AlertEngine & NormsData (Pure logic, no AI)
│   │   ├── scheduler/             # DayCalculator (42-day cycle)
│   │   └── validators/            # DiaryValidators (input validation)
│   ├── l10n/                      # ARB localization files (uz, ru)
│   ├── presentation/
│   │   ├── blocs/                 # Onboarding, Home, Diary, Ask, Course, DailyPlan
│   │   ├── screens/               # Splash, Onboarding (4 steps), Dashboard, Diary, Course, Chat
│   │   └── widgets/               # StatCard, AlertCard, DailyTaskCard, VoiceInputButton
│   └── services/                  # Notification & Voice STT services
├── knowledge/                     # Vet-verified agricultural guidelines
│   ├── broiler_plan.json          # 42-day daily care checklist (uz + ru)
│   ├── norms.json                 # Ross-308 / Cobb-500 standards
│   ├── vets.json                  # Veterinary directory (13 regions of Uzbekistan)
│   ├── videos.json                # Curated video guides
│   ├── broilers/                  # Markdown topic articles
│   └── course/                    # 5 pre-credit lessons & quizzes
├── supabase/
│   ├── migrations/                # 001 to 007 SQL schema & RLS policies
│   ├── functions/                 # ask-question, transcribe-voice, send-daily-plan
│   └── seed.sql                   # Sample veterinarians and reference data
└── test/                          # Comprehensive test suite (87 tests)
```

---

## 🚀 Getting Started

### Prerequisites
- Flutter SDK 3.22+ / 3.44+
- Dart 3.12+

### Installation & Run

1. Clone the repository:
   ```bash
   git clone https://github.com/ZedRubilan/agrozen.git
   cd agrozen
   ```

2. Get dependencies:
   ```bash
   flutter pub get
   ```

3. Run automated tests:
   ```bash
   flutter test
   ```

4. Analyze code:
   ```bash
   flutter analyze
   ```

5. Launch the app:
   ```bash
   flutter run
   ```

---

## 🧪 Testing Coverage

The project includes 87 automated unit and widget tests:
- `test/domain/day_calculator_test.dart` (26 tests): 42-day cycle calculation, active status, week numbers.
- `test/domain/alert_engine_test.dart` (24 tests): Mortality thresholds, weight deviations, critical alerts, zero division safety.
- `test/domain/diary_validators_test.dart` (18 tests): Input validation rules for mortality, feed, and weight.
- `test/data_layer_test.dart` (15 tests): JSON serialization, theme, knowledge loading, vet district filters.
- `test/presentation/presentation_test.dart` (4 tests): StatCard, AlertCard, DailyTaskCard, LanguageSelector widget tests.

---

## 📜 Safety & Ethical AI Principles

1. **AI answers ONLY from verified knowledge base** — No hallucinations.
2. **Never prescribes medicines or dosages** — Always directs farmers to local veterinarians.
3. **Alerts run purely on deterministic mathematical rules** — No LLM in the alert trigger path.
4. **Data privacy** — Compliant with Uzbekistan data protection regulations.

---

## 👨‍🌾 Author & Project Info

- **Project**: AgroZen (Parrandachilik bo'yicha aqlli yordamchi)
- **Author**: Salimbek Zamalitdinov (`ZedRubilan`)
- **License**: MIT
