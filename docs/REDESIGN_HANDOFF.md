# AgroZen redesign — handoff

Status as of 2026-10-13 (broiler photos done). Read this first when picking the work up in a new session.

## Where the work is

- **Branch:** `redesign/photo-led-ui` (pushed to `origin`, https://github.com/ZedRubilan/agrozen). **Not merged to `main` yet.**
- **Commits:** `0540fe3` holds the whole redesign; this handoff file is the next commit.
- **Release APK:** pushing or merging to `main` triggers `.github/workflows/android-release.yml`, which builds the APK and publishes a GitHub Release. To build locally instead, run `flutter build apk --release`. Output: `build/app/outputs/flutter-apk/app-release.apk` (about 64 MB).
- **State at handoff:** `flutter analyze` is clean and `flutter test` passes all 242 tests.
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

## Done: real broiler photos

- **Photos** (all from Wikimedia Commons, about 1200 px wide, under 250 KB each):
  - `broiler_starter.jpg`: chicks along a feeder line (USDA NRCS Texas, public domain);
  - `broiler_grower.jpg`: white 2–3-week birds (Icem4k, CC BY-SA 4.0);
  - `broiler_finisher.jpg`: grown broilers in a modern house (USDA, Bob Nichols, public domain).
- **Deleted:** `broiler_flock.jpg` (it showed a laying hen and nothing used it).
- **Code:** `BroilerPhotos.forDay(day)` in `lib/presentation/ui/broiler_photos.dart` maps the Ross-308 phase to a photo (days 1–10, 11–24, 25–42).
  - Used by the Today hero, the Settings profile card and the onboarding batch preview.
  - The Learn course card uses the finisher photo.
- **Credits:** listed in `assets/images/CREDITS.md` and in `PhotoCredit.all`. Settings → About → *Photo credits* shows them in a dialog; tapping a row opens its Commons page (`ExternalActions.openLink`).
- **Tests:** `test/presentation/broiler_photos_test.dart` checks the phase mapping, that each file exists and is under 250 KB, and that every photo is credited. The suite now has 242 tests.
- **Still on older photos:** `chick_starter.jpg` (Assistant "check a photo", lesson video card) and `sunset_farm.jpg` (onboarding language hero). Their source and licence are not recorded anywhere. Replace them with credited Commons photos if that matters.
- **Unused candidates:** the original search list is in git history (commit `99ef5bc`). Other good finds: `20130822-OC-RBN-2957` (USDA, public domain, finisher house with a farmer) and `Broiler Chicks.jpg` (Ibgroup2018, CC BY-SA 4.0, modern house with young birds). The Commons API rate-limits quickly; leave about a second between requests.

## Other open items

- **Merge:** merge `redesign/photo-led-ui` into `main` when you're happy (this triggers the release workflow).
- **Backups:** pre-change copies of every redesigned file are under `.git/agrozen-redesign-backup/` (local only, not pushed). The commit history is the real backup now.
- **Web screenshots:** to verify UI on web, run `flutter build web --release`, serve `build/web` on a **free** port (something else uses 8765), and drive headless Chromium (Playwright). Seed `localStorage` with `flutter.<key>` = JSON-encoded values, for example `is_onboarded`, `app_language`, `farmer_name`, `farmer_district`, `arrival_date`, `initial_count` and `current_count`. Deep links use `/#/route`.
