# Changelog

All notable changes to the "Junk Fishing" project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

---

## [0.1.0] - 2026-11-04

### Changed
- **Direct Tap-The-Hole Flow & Seamless Re-Cast Loop**:
  - The game now launches immediately in the `readyToCast` state with the animated **"TAP THE HOLE"** prompt active over the stone well, eliminating the redundant "start game" step.
  - The collapsible HUD drawer remains accessible on the left while keeping the hole ready to cast.
  - When a cast finishes (after dismissing a failed comic speech bubble or keeping/selling a catch), the game automatically returns straight to **"TAP THE HOLE"** rather than retreating to an idle menu.
- **Torchlight-Paced Ring Timing Engine**:
  - Re-tuned `FishingTimingEngine` speeds and ease curves (`Curves.easeInOutSine` and `Curves.easeInOutQuad`) to match authentic Torchlight gameplay pacing:
    - Calm, deliberate tease contractions lasting 900ms - 1500ms rather than rapid twitching.
    - Deep teases smoothly glide near the inner ring (48-56px) without turning orange.
    - Generous, human-friendly strike linger window (750ms ± 200ms) with an increased strike tolerance (14.0px).
- **Architectural Separation of Concerns**:
  - Extracted pure Dart game engines into `lib/engine/`:
    - `FishingTimingEngine`: Headless simulation of Torchlight-style timing mechanics, procedural teasing contractions, orange strike windows, tolerance calculations, and precision scoring.
    - `LootEngine`: Isolated weighted gacha roller calculating item rarity drops and factoring in player timing accuracy bonuses.
  - Extracted modular scene rendering into `lib/rendering/scene_painters.dart`:
    - `EnvironmentPainter`: Forest clearing, mossy ground, dirt path contours, pebbles, and pine tree/boulder silhouettes.
    - `LanternLightingPainter`: Wooden stand, crate, lantern housing, and radial ambient lighting shader.
    - `FishingHolePainter`: 3D stone lip blocks, pit depth gradient, and animated concentric ripples.
    - `FishermanPainter`: Top-down character, outdoor jacket/beanie, rod bending, and vertical line drop physics.
  - Refactored `IsometricWorld` and `RippleTimingOverlay` into lightweight presentation widgets driven by their respective engines and painters.
  - Added dedicated unit test suite `test/engine_test.dart` for deterministic engine simulation and loot validation.

### Added
- **Top-Down Isometric Fishing Hole Perspective (Step 1)**:
  - Transitioned the world view from the previous side-pier layout to an atmospheric top-down isometric fishing hole scene matching the design mock:
    - Stone-lined circular fishing well/hole with depth gradient and animated water ripples.
    - Top-down fisherman standing on the left bank holding an angled rod over the hole with a vertical line dropping directly into the water.
    - Wooden lantern post on the upper-right casting a warm atmospheric radial amber glow onto the ground and well.
    - Surrounding clearing background with woodland ground, dirt path contours, and pine tree/boulder silhouettes.
    - "TAP THE HOLE" interactive cast prompt aligned directly over the stone well opening.
- **Torchlight-Style Fishing Mechanic**:
  - Implemented dynamic pseudo-random bait nibbles where the outer ring shrinks, pauses, expands, and changes speed with organic variation.
  - Deep tease behavior: ring can shrink close to the inner ring without turning orange (false nibble tease) before expanding back out.
  - Visual strike indicator: when the outer ring contacts the inner ring during a genuine bite, both the ring and hook turn glowing orange/gold and trigger a tactile haptic pulse.
  - Non-punitive missed bites: failing to tap during an orange window causes the fish to retreat safely, and the minigame automatically generates a new randomized cycle of nibbles and strikes without game over.
  - Full-screen hit detection allows the player to tap anywhere on the screen during the orange strike window to hook the fish.

### Fixed
- **Android Gradle Build Configuration**:
  - Disabled Kotlin incremental compilation (`kotlin.incremental=false` in `android/gradle.properties`) to resolve cross-drive Windows path resolution bug (`IllegalArgumentException: this and base files have different roots`).
  - Configured missing SDK build platform dependencies (`android-34`, `android-35`, `android-36`) and CMake 3.22.1 for JNI native plugin compilation.
  - Re-encoded `force-latest-android-sdk.gradle` to UTF-8 without BOM to resolve Groovy parser startup failure.
  - Relocated and synced global pub cache to `K:\Android\.pub-cache` via `PUB_CACHE` environment variable to permanently unify project and dependencies on drive `K:`.

---

## [0.0.1] - 2026-10-11

### Added
- **Initial Core Prototype & State Machine Architecture**:
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
