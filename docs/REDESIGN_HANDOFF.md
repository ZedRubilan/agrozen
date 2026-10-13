# AgroZen redesign — handoff

Status as of 2026-10-13. Read this first when picking the work up in a new session.

## Where the work is

- **Branch:** `redesign/photo-led-ui` (pushed to `origin`, https://github.com/ZedRubilan/agrozen). **Not merged to `main` yet.**
- **Commits:** `0540fe3` holds the whole redesign; this handoff file is the next commit.
- **Release APK:** pushing or merging to `main` triggers `.github/workflows/android-release.yml`, which builds the APK and publishes a GitHub Release. To build locally instead, run `flutter build apk --release`. Output: `build/app/outputs/flutter-apk/app-release.apk` (about 64 MB).
- **State at handoff:** `flutter analyze` is clean and `flutter test` passes all 236 tests.
- **Not committed on purpose:** `zenustoz-main.zip` belongs to a different project ("ZenUstoz").

## Project rules (from `AGENTS.md`)

- Present an "Enhanced Prompt" block (from the enhance-prompt skill and `DESIGN.md`) at the top of each response.
- Base poultry numbers on Ross-308 / Cobb-500, taken from `BroilerGrowerLibrary` and `knowledge/norms.json`.
- Write every string in `uz`, `ru` and `en` via `AppStrings.tr(...)`.
- Never name medicines or doses; always point to the district vet.

## What was done (all screens)

`DESIGN.md` is the up-to-date design spec. Key pieces:

- **Tokens** (`lib/config/theme.dart`):
  - colours: `sun`, `sunDeep`, `heroShade`;
  - `AppShadow` (card / raised / glow), `AppRadius` (md 18, lg 24, hero 32);
  - `AppText.display`, `AppMotion.enter/stagger/count`;
  - `AppFonts.fallback`.
- **Components** (`lib/presentation/ui/components.dart`):
  - `AppCard` (shadow, shrinks when pressed), `Reveal` (staggered entrance), `CountUpText`, `ProgressRing`;
  - `GlassPill`, `PhotoCard`, `TargetTile`, `ConfettiBurst` (one-shot), `PrimaryButton(iconAtEnd:)`;
  - `Tone.solid`.
- **Screens:**
  - Today: photo hero, day ring, floating flock card.
  - Diary: growth chart in `widgets/growth_chart_card.dart`.
  - Learn, lesson, quiz, certificate: the shared per-lesson icon and colour live in `screens/course/lesson_look.dart`.
  - Assistant welcome, Settings, onboarding (`OnboardingScaffold` with step bar and icon disc).
  - Log entry (live gauges), 42-day plan (phase strip, swipe), calculators (grade badge, profit card, cost bar), splash.
- **Weather:**
  - `widgets/weather_scene.dart` draws animated skies (7 sky types × day/night).
  - The sky comes from the WMO weather code (`weatherSkyFor`), never from temperature.
  - `WeatherData` stores `weatherCode`, `sunrise`, `sunset` and `isDayAt()`. Forecast days store `precipChance` and real daily humidity.
  - `fog` is a new condition.
- **Cyrillic font:** `assets/fonts/NotoSansCyrillic-*.ttf` (5 weights, about 80 KB, OFL licence in `assets/fonts/NotoSans-OFL.txt`). Plus Jakarta Sans has no basic Cyrillic. Without this, Russian was blank for 6–20 s on web.
- **FCR plausibility:** `BroilerGrowerLibrary.isPlausibleFcr(day:, fcr:)` flags an FCR below 0.7 × the day's target. The old fixed 0.9 cutoff rejected on-target flocks before about day 18.
- **Tests:**
  - Widget test harnesses run with `disableAnimations: true`. The weather scene loops forever, so `pumpAndSettle` would otherwise hang.
  - New tests: `test/services/weather_sky_test.dart` and the FCR group in `test/broiler_grower_library_test.dart`.

## Next task: real broiler photos (not started in code)

Goal: replace the unsuitable photo and make the Today hero follow the flock's age.

- `assets/images/broiler_flock.jpg` is a brown **laying hen**, not a broiler. It is currently unused; drop it or replace it.
- Today hero (`_HeroPhoto` in `lib/presentation/screens/today_screen.dart`) always uses `chick_starter.jpg`. Plan: choose the photo by `farm.spec.phaseKey`:
  - starter: chicks;
  - grower: 2–3-week-old broilers;
  - finisher: grown white broilers.
- Other places that could use better photos:
  - `PhotoCard`s in Learn (`sunset_farm.jpg`), Settings, the Assistant "check a photo" card, and the lesson video card;
  - the onboarding batch preview.

Candidates from Wikimedia Commons. **Look at each one before use** (I only shortlisted them by title and licence).

| File | Licence | Author | Page |
|---|---|---|---|
| Baby chickens in a grower broiler house. (24481449624).jpg | Public domain | USDA NRCS Texas | https://commons.wikimedia.org/wiki/File:Baby_chickens_in_a_grower_broiler_house._(24481449624).jpg |
| Baby chickens in a grower broiler house. (24485263333).jpg | Public domain | USDA NRCS Texas | https://commons.wikimedia.org/wiki/File:Baby_chickens_in_a_grower_broiler_house._(24485263333).jpg |
| Baby chickens in a grower broiler house. (24744460509).jpg | Public domain | USDA NRCS Texas | https://commons.wikimedia.org/wiki/File:Baby_chickens_in_a_grower_broiler_house._(24744460509).jpg |
| Baby chickens in a grower broiler house. (24993924222).jpg | Public domain | USDA NRCS Texas | https://commons.wikimedia.org/wiki/File:Baby_chickens_in_a_grower_broiler_house._(24993924222).jpg |
| Baby chickens in a grower broiler house. (25018838441).jpg | Public domain | USDA NRCS Texas | https://commons.wikimedia.org/wiki/File:Baby_chickens_in_a_grower_broiler_house._(25018838441).jpg |
| Baby chickens in a grower broiler house. (25112103855).jpg | Public domain | USDA NRCS Texas | https://commons.wikimedia.org/wiki/File:Baby_chickens_in_a_grower_broiler_house._(25112103855).jpg |
| Broiler Chicken at a farm.jpg | CC BY-SA 4.0 | Umar2z | https://commons.wikimedia.org/wiki/File:Broiler_Chicken_at_a_farm.jpg |
| Broiler Chickens 001.jpg | CC BY-SA 4.0 | Icem4k | https://commons.wikimedia.org/wiki/File:Broiler_Chickens_001.jpg |
| Broiler Chickens 002.jpg | CC BY-SA 4.0 | Icem4k | https://commons.wikimedia.org/wiki/File:Broiler_Chickens_002.jpg |
| Broiler Chicks.jpg | CC BY-SA 4.0 | Ibgroup2018 | https://commons.wikimedia.org/wiki/File:Broiler_Chicks.jpg |
| Broiler chicks Armenia 01.jpg | CC BY-SA 4.0 | Narek Avetisyan | https://commons.wikimedia.org/wiki/File:Broiler_chicks_Armenia_01.jpg |
| Broiler chicks Armenia 02.jpg | CC BY-SA 4.0 | Narek Avetisyan | https://commons.wikimedia.org/wiki/File:Broiler_chicks_Armenia_02.jpg |
| Broiler chicks around a week old.jpg | CC BY-SA 4.0 | Shadow Ayush | https://commons.wikimedia.org/wiki/File:Broiler_chicks_around_a_week_old.jpg |
| Image of 8 weeks old broiler chicken.jpg | CC BY-SA 4.0 | AJ.Adekunle | https://commons.wikimedia.org/wiki/File:Image_of_8_weeks_old_broiler_chicken.jpg |

Steps:

1. **Find the files.** Search with the Commons API: `https://commons.wikimedia.org/w/api.php?action=query&format=json&generator=search&gsrnamespace=6&gsrsearch=broiler%20chickens&prop=imageinfo&iiprop=url|size|extmetadata|mime&iiurlwidth=640`. Each result's `imageinfo.thumburl` gives a resized copy.
2. **Download and check.** Download into a fresh folder, look at every image, and pick the ones that clearly show broilers in a clean house.
3. **Optimise.** Resize to about 1200 px on the long side with JPEG quality about 80 (each file under about 250 KB), then save to `assets/images/`.
4. **Credit CC BY-SA photos.** For each one, add a credit (title, author, licence, link) to a new `assets/images/CREDITS.md`, and show credits in Settings → About. Public-domain photos need no credit.
5. **Wire them in.** Make the phase-based hero, update `DESIGN.md` (section 4, Photos), then run `flutter analyze` and `flutter test`.
6. **Ship.** Commit to `redesign/photo-led-ui`, push, then rebuild the APK.

## Other open items

- **Merge:** merge `redesign/photo-led-ui` into `main` when you're happy (this triggers the release workflow).
- **Backups:** pre-change copies of every redesigned file are under `.git/agrozen-redesign-backup/` (local only, not pushed). The commit history is the real backup now.
- **Web screenshots:** to verify UI on web, run `flutter build web --release`, serve `build/web` on a **free** port (something else uses 8765), and drive headless Chromium (Playwright). Seed `localStorage` with `flutter.<key>` = JSON-encoded values, for example `is_onboarded`, `app_language`, `farmer_name`, `farmer_district`, `arrival_date`, `initial_count` and `current_count`. Deep links use `/#/route`.
