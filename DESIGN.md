# AgroZen Design System (`DESIGN.md`)

A high-craft, photographic-first fintech & agritech visual language inspired by **Payme**, **Linear**, and **Emil Kowalski's Design Engineering** principles, tailored for poultry farmers in Uzbekistan.

## 1. Core Palette
- **Deep Forest Obsidian (`#0B2214`)**: Hero headers, welcome backdrop, and primary dark surfaces.
- **Lush Agro Emerald (`#15803D` / `#1B5E20`)**: Primary brand actions, active progress dots, and selected card borders.
- **Vibrant Mint Accent (`#22C55E` / `#34D399`)**: Live status beacons, checkmarks, and interactive highlights.
- **Warm Harvest Gold (`#F59E0B` / `#FBBF24`)**: Broiler warmth indicators, badges, and microclimate alerts.
- **alabaster Mist (`#F4F7F4`)**: Clean, high-contrast light surface background for forms and cards.
- **Pure Surface White (`#FFFFFF`)**: Elevated interactive cards with crisp `1.5px` borders (`#E2EBE4`).
- **Slate Ink (`#0F172A`)**: Primary high-legibility typography.
- **Muted Sage (`#52665A`)**: Secondary descriptions and subtitles.

## 2. Typography & Hierarchy
- **Display / Hero Headlines**: `22px–28px`, `FontWeight.w900`, tight tracking (`-0.5`), crisp contrast over photographic backdrops.
- **Section Titles**: `17px–20px`, `FontWeight.w800`, letter-spacing `-0.3`.
- **Interactive Card Titles**: `15px–17px`, `FontWeight.w800`.
- **Body & Guidance Copy**: `13px–14px`, `FontWeight.w600`, line-height `1.45`.

## 3. Onboarding & Welcome Flow Architecture (Payme-Inspired)
1. **Instant Launch (Zero Spinner)**:
   - Opening the app never blocks on a loading spinner. Un-onboarded users immediately enter the full-screen photographic Welcome & Language experience; onboarded users go straight to `/home`.
2. **Hero Photographic Showcase**:
   - Full-bleed rounded hero visual card featuring real poultry photography (`assets/images/sunset_farm.jpg`, `assets/images/broiler_flock.jpg`, `assets/images/chick_starter.jpg`), a frosted glass badge, and the circular photographic `AgroChickIcon` (`assets/images/agrozen_logo.png`).
3. **Uncropped Vector Flag Badges (`AgroFlagBadge`)**:
   - Wide `4:3` rounded-rectangle (`BorderRadius.circular(10)`) custom-painted flags for Uzbekistan (`uz`), Russia (`ru`), and English (`en` Union Jack) with full internal padding so stripes, crescents, and crosses are never clipped.
4. **Progress Dots & Arrow Navigation Bar**:
   - Every onboarding step (`1/4` Language, `2/4` Region & GPS, `3/4` Flock Setup, `4/4` Safety Agreement) displays animated pill-dots (`AnimatedContainer` expanding from `8px` circle to `26px` emerald pill) paired with a tactile arrow CTA button.

## 4. Motion & Interaction Rules (Emil Kowalski Principles)
- **Duration**: All UI state transitions (`AnimatedContainer`, `AnimatedScale`, `AnimatedSwitcher`) run between `150ms` and `240ms` with `Curves.easeOutCubic`.
- **No `scale(0)` entrances**: Elements scale from `0.94` with fade-in.
- **Tactile press**: Interactive cards and primary CTA buttons respond immediately on press without layout shift.
