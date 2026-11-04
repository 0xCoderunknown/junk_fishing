# Changelog

All notable changes to the "Junk Fishing" project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

---

## [Unreleased]

### Changed
- **Architectural Separation of Concerns**:
  - Extracted pure Dart game engines into `lib/engine/`:
    - `FishingTimingEngine`: Headless simulation of Torchlight-style timing, tease contractions, strike windows, and accuracy calculations.
    - `LootEngine`: Isolated weighted gacha roller with accuracy bonuses.
  - Extracted modular scene rendering into `lib/rendering/scene_painters.dart`:
    - `EnvironmentPainter`, `LanternLightingPainter`, `FishingHolePainter`, and `FishermanPainter`.
  - Refactored `IsometricWorld` and `RippleTimingOverlay` into lightweight presentation widgets connected to their respective engines and painters.
  - Added unit test suite `test/engine_test.dart` covering engine simulation and gacha roller logic.

### Added
- **Top-Down Isometric Fishing Hole Perspective (Step 1)**:
  - Redesigned `IsometricWorld` from the previous side pier view to match the top-down isometric fishing hole scene from the reference card:
    - Stone-lined circular fishing well/hole with depth gradient and centered animated water ripples.
    - Top-down fisherman standing on the left side (with red/orange outdoor jacket, backpack, dark beanie) holding an angled rod over the hole with a vertical line dropping directly into the water.
    - Lantern post on the upper-right casting a warm atmospheric radial amber glow onto the ground and well.
    - Surrounding clearing background with woodland ground, dirt path contours, and pine tree/boulder silhouettes.
    - "TAP THE HOLE" interactive cast prompt perfectly aligned over the stone well.
- **Torchlight-Style Fishing Mechanic**:
  - Re-engineered `RippleTimingOverlay` to mirror the Torchlight / Torchlight II fishing minigame.
  - Implemented dynamic pseudo-random bait nibbles where the outer ring shrinks, pauses, expands, and changes speed with organic variation.
  - Ring can shrink close to the inner ring without turning orange (false nibble tease) before expanding back out.
  - Added visual strike indicator: when the outer ring contacts the inner ring during a genuine bite, both the ring and hook turn glowing orange/gold and trigger a tactile haptic pulse.
  - Removed punitive timeout/game-over when failing to tap during the orange window: the fish simply retreats, and the minigame automatically generates a new randomized cycle of nibbles and strikes until the player hooks or cancels.
  - Full-screen hit detection allows the player to tap anywhere on the screen during the orange strike window to hook the fish.

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
