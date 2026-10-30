# Changelog

All notable changes to the "Junk Fishing" project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

---

## [Unreleased]

### Fixed
- **Android Gradle Build Configuration**:
  - Disabled Kotlin incremental compilation (`kotlin.incremental=false` in `android/gradle.properties`) to resolve cross-drive Windows path resolution bug (`IllegalArgumentException: this and base files have different roots`).
  - Configured missing SDK build platform dependencies (`android-34`, `android-35`, `android-36`) and CMake 3.22.1 for JNI native plugin compilation.

---

## [1.0.0] - 2026-10-11

### Added
- **Core State Machine Architecture**:
  - Implemented `FishingState` enum (`idleMenu`, `readyToCast`, `rippleActive`, `pullingRod`, `resultModal`).
  - Implemented unified `MainFishingScreen` operating as a single-screen `Stack` with dynamic overlays.
- **Data Models**:
  - `Location` model with difficulty multipliers, themes, and drop pool lists.
  - `Item` model with rarity tiers (1-5 stars), flavor texts, weight, collection tags, and sell values.
  - `Collection` model with progress calculation and reward redemption.
  - `PlayerState` supporting currency (🪙 scrap coins), bait counter, inventory capacity, and discovery tracking.
- **Data & Local Persistence Service**:
  - `GameDataService` loading local JSON assets (`locations.json`, `items.json`, `collections.json`) via `rootBundle`.
  - Local state persistence using `SharedPreferences`.
  - Deterministic gacha roller with weighted rarity odds (★ 50%, ★★ 28%, ★★★ 14%, ★★★★ 6%, ★★★★★ 2%) boosted by timing accuracy.
- **Visuals & Interactive Mechanics**:
  - `IsometricWorld`: Custom-drawn isometric pier, dynamic water waves, floating junk, animated fisherman, and tension line physics.
  - `RippleTimingOverlay`: Concentric target boundary rings and oscillating ripple wave using `BackdropFilter` and `CustomPainter`.
  - `PolaroidResultCard`: Vintage discovery modal with photo frame, rarity glow, screenshot capture (`screenshot`), and share functionality (`share_plus`).
  - `ComicSpeechBubble`: Wobbling fail speech bubble (*"Caught nothing..."*) with cartoon tail.
  - `CollapsibleNavMenu`: Left navigation drawer (Fish, Inventory, Collections, Map, Settings) and top player HUD.
- **Interactive Bottom Sheet Overlays**:
  - `InventorySheet`: Pouch overview, rarity filters, and single/batch sell functionality.
  - `CollectionsSheet`: Discovery checklists and milestone rewards.
  - `MapSheet`: Fast-travel between unlocked fishing spots.
  - `SettingsSheet`: Haptic/audio toggles and save reset option.
- **Documentation & Governance**:
  - `AGENTS.md`: AI-only development charter and anti-drift rules.
  - `README.md`: Architecture manual and developer reference.
- **Verification & Testing**:
  - `models_and_service_test.dart`: Automated unit test coverage for item/location/collection models, `PlayerState` mutation logic, and `FishingState` order.
  - Smoke widget test validating clean app mounting.
