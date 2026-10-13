# AgroZen Design System (`DESIGN.md`)

Simple to use, exciting to look at: an app a broiler farmer can use with one
hand in the barn — big photos, bold numbers, little text. Every screen is built from the same tokens and components — if
something can't be expressed with them, add a token or a component; never
hard-code a one-off colour, size or decoration.

- Tokens: [`lib/config/theme.dart`](lib/config/theme.dart) (`AppColors`, `AppSpace`, `AppRadius`, `AppText`, `AppMotion`)
- Components: [`lib/presentation/ui/components.dart`](lib/presentation/ui/components.dart)
- Number/unit formatting: [`lib/presentation/ui/format.dart`](lib/presentation/ui/format.dart) (`Fmt`)

## 1. Principles
1. **One thing per card.** A card answers one question (How is my flock? What are today's targets?).
2. **Most important first.** Warnings → status → today's targets → record → tasks → weather → extras.
3. **Real data only.** No fake ratings, "LIVE" badges or decorative numbers. Estimates are labelled as estimates.
4. **Same words, same numbers everywhere.** Targets come only from `BroilerGrowerLibrary` (a mirror of `knowledge/norms.json`); flock state only from `FarmStore`.
5. **Big, labelled touch targets.** Buttons ≥ 48 px high (primary 52 px); navigation always shows text labels.

## 2. Palette (`AppColors`)
| Token | Hex | Use |
|---|---|---|
| `primary` — Agro Emerald | `#15803D` | Primary buttons, progress, selected states |
| `primaryDark` | `#14532D` | Text/icons on soft green |
| `primarySoft` | `#E6F4EA` | Selected backgrounds, positive badges |
| `background` — Alabaster Mist | `#F4F7F4` | Screen background |
| `surface` | `#FFFFFF` | Cards |
| `surfaceMuted` | `#F1F5F2` | Tiles inside cards, input fills |
| `border` | `#E2EBE4` | 1 px card and divider lines |
| `ink` — Slate Ink | `#0F172A` | Primary text |
| `inkSecondary` — Muted Sage | `#52665A` | Secondary text |
| `inkMuted` | `#7A8E7E` | Captions, hints |
| `warning` / `warningSoft` | `#B45309` / `#FEF3C7` | Needs attention, temperature |
| `danger` / `dangerSoft` | `#DC2626` / `#FEE2E2` | Mortality, vet referral, destructive actions |
| `info` / `infoSoft` | `#1D4ED8` / `#DBEAFE` | Water, hints, neutral notices |
| `gold` | `#F59E0B` | Certificate accent; solid amber disc for feed (`Tone.warning.solid`) |
| `sun` / `sunDeep` | `#F97316` / `#EA580C` | The one filled "hero" tile per screen (gradient), e.g. house temperature |
| `heroShade` | `#052E16` | Gradient shade over hero photos so white text stays readable |

Colour roles are applied through `Tone` (`neutral`, `primary`, `warning`, `danger`, `info`) — components take a `Tone`, not a colour. `tone.solid` is the bright fill for round discs carrying a white icon.

## 3. Typography (`AppText`, Plus Jakarta Sans)
Plus Jakarta Sans has no basic Cyrillic, so every style names `AppFonts.fallback` — a bundled Noto Sans Cyrillic subset (`assets/fonts/`, 5 weights, ~80 KB, SIL OFL). Russian then renders immediately on web and the same offline on every phone. New theme-level `TextStyle`s must include `fontFamilyFallback: AppFonts.fallback`.
| Style | Size / weight | Use |
|---|---|---|
| `screenTitle` | 24 / w800 | Page and onboarding titles |
| `section` | 17 / w700 | Section headers |
| `cardTitle` | 15 / w700 | Card and row titles |
| `body` | 15 / w500, 1.45 | Reading text, tasks, answers |
| `bodyMuted` | 14 / w500 | Subtitles, descriptions |
| `caption` | 12.5 / w600 | Labels under numbers, metadata (minimum size) |
| `metric` | 22 / w800 | Key numbers (24 on Today tiles) |
| `display` | 34 / w800 | Day counter inside the hero ring |

## 4. Spacing & shape
- Spacing scale `4 · 8 · 12 · 16 · 24 · 32` (`AppSpace`). Screen padding 16; gap between cards 12; between sections 24 on Today.
- Radius (`AppRadius`): 12 buttons/inputs · 18 tiles · 24 cards and sheets · 32 photo hero and floating nav bar · pill for chips.
- Cards float on a soft shadow (`AppShadow.card`), no outline. Raised elements (flock card over the hero, nav bar) use `AppShadow.raised`; solid discs and the hero tile use `AppShadow.glow(colour)`.
- Gradients only in two places: the photo-hero shade and the one `sun` hero tile per screen.
- Photos: real, relevant farm photos only (`assets/images/`), always with an `errorBuilder` fallback. One hero photo per tab at most; thumbnails on link cards.
- Content width is capped at 640 px; on desktop the app is centred in a phone frame (`DesktopWebShell`).

## 5. Components (`components.dart`)
`AppCard` (shadowed, press-to-shrink when tappable), `SectionHeader`, `PageHeader`, `PageBody`, `IconBadge`, `StatusPill`, `MetricTile` + `MetricGrid`, `NoticeBanner`, `ListRow` + `ListGroup`, `AppProgressBar`, `PrimaryButton`, `LoadingView`, `Gap`.
Motion & photo pieces: `Reveal` (staggered entrance), `CountUpText` (numbers count up, settle on the exact `Fmt` text), `ProgressRing`, `GlassPill` (frosted pill on photos), `PhotoCard` (rounded photo with the `heroShade` gradient for white content).
Charts: `GrowthChartCard` — sample weighings (primary green, 2 px line, 8 px dots with a 2 px surface ring) vs the Ross-308 target (info blue, 2 px dashed); legend above, hairline grid, direct label on the latest weighing only, tap/drag crosshair. The x-axis runs from day 1 to a week past today (14–42), and the scale fits that window. The green/blue pair passes the dataviz palette validator; grey failed it, so don't use grey for a data series.
Shared widgets: `AlertCard` (flock alert + call vet), `TaskChecklistCard`, `WeatherSummaryCard`, `showLocationPicker`.
Weather: `WeatherSummaryCard` = animated `WeatherScene` (sky from the WMO weather code, never from temperature; day/night from today's sunrise/sunset; hills + poultry house whose windows glow at night) with the big temperature and "feels like" → outside vs barn row → humidity / wind / today's rain chance → risk pill + advice → tap for ventilation, water & feed, and 3 forecast tiles on pale versions of each day's sky.

## 6. App structure
- **Navigation:** floating rounded `NavigationBar` (white, `AppShadow.raised`, solid green pill on the selected tab) with four labelled tabs — *Bugun / Today*, *Kundalik / Diary*, *Yordamchi / Assistant*, *O'rganish / Learn*. Settings is the gear on the Today header.
- **Today:** photo hero (greeting, location, settings, day ring X/42, phase) with the flock card (alive, lost, days left) floating over its edge → alerts → today's targets (temperature as the filled `sun` tile; feed, water, weight) → record discs (deaths, feed, weight) → today's checklist → weather → useful (calculators photo card, district vet with a call button).
- **Diary:** record cards (solid disc + big "+"; feed shows a fed-vs-target bar; under-watch stepper) → batch summary (survival ring, alive count, lost / feed / days recorded) → growth chart → day-by-day history (off-norm values highlighted).
- **Assistant:** one chat with the chick logo as the assistant's avatar; before the first question: a "check a photo" `PhotoCard` and four quick-question tiles (solid discs). Mic when the input is empty, send when typing; optional read-aloud.
- **Learn:** course `PhotoCard` (lessons ring X/5, white pill button) → 5 lesson cards (gradient icon tile per lesson, duration pill, done check, green outline + "Up next" on the next one) → two reference tiles (42-day plan, ask the assistant).
- Pushed screens (plan, calculators, settings, logging, lessons) use a plain `AppBar` with a back arrow.
- **Logging (`LogEntryScreen`, one screen for deaths / feed / weight):** tinted header with the record's solid disc and the question → big number with round −/+ steppers (1 bird, 1 kg, 10 g) and "+N" quick-add pills, unit under the number → live gauge that updates while typing (feed: today's total vs target; deaths: today's % vs the 1 % norm, same formula as `AlertEngine`; weight: % of target with the −15 % line) → Save pinned at the bottom.
- **42-day plan:** day strip tinted by phase (starter gold, grower green, finisher orange; dot = today, filled green = selected) → phase-coloured day card with cycle ring → `TargetTile` grid (temperature is the hero tile) → feed type → tasks → tip card → previous / next day buttons; swipe left/right also changes day.
- `TargetTile` (in `components.dart`) is the one tile for a target number on Today and in the plan.
- **Settings:** `PhotoCard` profile (logo avatar, name, day · phase and flock pills, edit-name button) → language as three flag tiles → farm list → "Start a new batch" as a red card → about.
- **Lesson / quiz / certificate:** each lesson keeps one icon and colour everywhere (`lessonLook`). Lesson: lesson-coloured hero → numbered rule cards → "why it matters" card → detail → video `PhotoCard`; quiz button pinned at the bottom. Quiz: lesson-coloured question card → A–D answers that turn green / red (wrong one shakes once) → result card; a correct answer fires `ConfettiBurst` once. Certificate: cream paper in a double gold frame with the chick medal (one shine sweep) and confetti once; locked = gold progress ring + the five lesson discs.
- **Calculators:** FCR and EPEF as `TargetTile`s plus a round A/B/C grade badge; net profit on a green (loss: red) card that counts up; costs as one stacked bar scaled to revenue (chicks `sunDeep`, feed `info`, other `primary` — validated palette, 2 px gaps) with a labelled legend row each; equipment and space as `TargetTile`s.
- **Splash:** logo on a radial green glow (`primary` → `heroShade`); it hands off after one frame.
- Use only characters the app font has: ranges with an en dash ("33–22°C"), not arrows like "→".

## 7. Onboarding
Four steps sharing `OnboardingScaffold`: an animated 4-segment step bar with `1 / 4`, a gradient icon disc beside the title (none on step 1, which has the photo), content that `Reveal`s in, and one primary button (trailing arrow) pinned to the bottom on a raised white bar. `OptionCard` pops its check when selected.
1. **Language** — `sunset_farm.jpg` hero (one slow zoom) with the `AgroChickIcon` logo; flags via `AgroFlagBadge`.
2. **Region** (green pin) — GPS as a prominent card with a blue disc (status line under it), search, town chips, district list with the selected row tinted.
3. **Batch** (gold) — name, arrival date, count with 500 / 1 000 / 2 000 / 5 000 pills, and a live `PhotoCard` preview: today's batch day ring, phase and house temperature target for the chosen date.
4. **Notice** (blue shield) — each safety point as its own card with a solid disc.
Launch never shows a spinner.

## 8. Motion (`AppMotion`)
- State changes: 150–220 ms, `Curves.easeOutCubic`.
- Screen entrance: sections `Reveal` one after another (520 ms, 70 ms stagger, capped at 8 steps).
- Numbers and rings fill on first show (900 ms, `easeOutQuart`); the hero photo zooms out once (1.6 s).
- Tappable cards shrink to 0.97 while pressed.
- Nothing loops — except the weather scene (`WeatherScene`), whose rain, snow, clouds, stars and sun rays move on one seamless 40 s loop because the moving sky *is* the information. It pauses when its tab is hidden and becomes a still picture with reduce-motion on. Widget tests run with reduce-motion so `pumpAndSettle` can settle.
- Everything respects the system "reduce motion" setting (`MediaQuery.disableAnimations`) and lands instantly there.

## 9. Language & safety
- Every string is written in `uz`, `ru` and `en` (`AppStrings.tr`); units and numbers go through `Fmt`.
- Never show drug names or doses; health problems always lead to a "call the district vet" action.
