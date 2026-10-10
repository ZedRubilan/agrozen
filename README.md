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

5. **Trilingual Support (Uch tilli interfeys)**
   - Full support for **O'zbekcha (Lotin)**, **Русский**, and **English**.

---

## 🛠️ Architecture & Tech Stack

```
Mobile Client (Flutter) ──► Supabase Backend (PostgreSQL + RLS)
                             ├── Edge Functions (Deno / TS)
                             │     ├── ask-question (RAG + Gemini 2.5 Flash)
                             │     ├── transcribe-voice (STT)
                             │     └── send-daily-plan (pg_cron 7:00 AM)
                             └── Knowledge Base Assets (uz, ru, en)
```

- **Client**: Flutter 3.44+ (Android, iOS, Web)
- **State Management**: `flutter_bloc` + reactive local persistence
- **Routing**: `go_router`
- **Backend**: Supabase (PostgreSQL 15+, Row Level Security, Edge Functions) with full offline `SharedPreferences` fallback
- **AI Models**: Google Gemini 2.5 Flash / 2.0 Flash via Edge Functions + deterministic local RAG fallback
- **Speech-to-Text**: Google Cloud STT / Whisper / Gemini Audio swappable adapter
- **Testing**: 200 automated unit, repository, BLoC, domain, service, widget, and end-to-end flow tests

---

## 📂 Project Structure

```
agrozen/
├── lib/
│   ├── app.dart                   # MaterialApp, routing & localization
│   ├── main.dart                  # App entry point
│   ├── config/                    # Theme, SupabaseConfig & AppConstants
│   ├── core/                      # Localization strings & helpers
│   ├── data/
│   │   ├── models/                # Farmer, Batch, DiaryEntry, DailyPlan, WeatherData, etc.
│   │   ├── providers/             # Supabase & AI providers
│   │   └── repositories/          # Offline-capable Auth, Farmer, Batch, Diary, Knowledge, Course
│   ├── domain/
│   │   ├── alerts/                # AlertEngine & NormsData (Pure logic, no AI)
│   │   ├── climate/               # ClimateAdvisor (Brooder & barn ventilation guidance)
│   │   ├── scheduler/             # DayCalculator (42-day cycle)
│   │   └── validators/            # DiaryValidators (trilingual input validation)
│   ├── l10n/                      # ARB localization files (uz, ru, en)
│   ├── presentation/
│   │   ├── blocs/                 # Onboarding, Home, Diary, Ask, Course, DailyPlan
│   │   ├── screens/               # Splash, Onboarding (4 steps), Dashboard, Diary, Course, Chat
│   │   └── widgets/               # StatCard, AlertCard, DailyTaskCard, WeatherClimateCard, etc.
│   └── services/                  # LocalRag, Voice, TTS, Weather, Vision, Notification & Counters
├── knowledge/                     # Vet-verified agricultural guidelines (uz, ru, en)
│   ├── broiler_plan.json          # 42-day daily care checklist (uz + ru + en)
│   ├── norms.json                 # Reconciled Ross-308 / Cobb-500 standards
│   ├── vets.json                  # Veterinary directory (13 regions of Uzbekistan)
│   ├── videos.json                # Curated video guides (uz + ru + en)
│   ├── broilers/                  # Markdown topic articles (en, ru, uz)
│   └── course/                    # 5 pre-credit lessons & quizzes (en, ru, uz)
├── supabase/
│   ├── migrations/                # 001 to 008 SQL schema, triggers & RLS policies
│   ├── functions/                 # ask-question, transcribe-voice, send-daily-plan
│   └── seed.sql                   # Idempotent sample veterinarians and reference data
└── test/                          # Comprehensive test suite (200 tests)
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

The project includes 200 automated unit, repository, BLoC, service, widget, and end-to-end flow tests:
- `test/domain/day_calculator_test.dart`: 42-day cycle calculation, DST-safe calendar math, active status, week numbers.
- `test/domain/alert_engine_test.dart`: Mortality thresholds, cumulative mortality, weight deviations, temperature deviations, zero-division safety.
- `test/domain/diary_validators_test.dart`: Trilingual (`uz`, `ru`, `en`) input validation rules, `NaN`/`Infinity` guards, and comma decimal support.
- `test/domain/norms_parsing_test.dart`: Reconciled `norms.json` daily/weekly consistency, feed/weight/temperature target lookups, and Day > 42 clamping.
- `test/data_layer_test.dart` & `test/data/repositories/repositories_test.dart`: Model serialization, trilingual `DailyPlan` & `WeatherData`, knowledge loading, and offline repository persistence (`Farmer`, `Batch`, `Diary`, `Course`, `Auth`).
- `test/services/`: `LocalRag` (Uzbek numbered manuals, HTML comment stripping, apostrophe tokenization, emergency & medical guardrails), `TextToSpeechSanitizer` (decimal preservation), `ClimateAdvisor`, `WeatherService` cache invalidation, `DailyCounters`, and `VoiceService` UI.
- `test/presentation/blocs/blocs_test.dart`: Full event/state coverage for `HomeBloc`, `DiaryBloc`, `DailyPlanBloc`, `AskBloc`, `CourseBloc`, and `OnboardingBloc`.
- `test/presentation/presentation_test.dart` & `test/logical_flow_test.dart`: Widget and 18-step end-to-end user journey verification.

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
