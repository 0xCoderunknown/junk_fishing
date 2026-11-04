# Changelog

All notable changes to the "Junk Fishing" project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

---

## [0.1.0] - 2026-11-04

### Changed
- **Precision Timing Accuracy Gradient**:
  - Replaced flat binary accuracy (1.0) with an authentic reaction gradient: tapping dead-center in the 500ms orange strike window awards maximum 1.0 (100%) accuracy, while early or late edge taps award a graded ~0.65–0.75 accuracy.
  - Graded accuracy feeds directly into `LootEngine.rollCatch(timingBonus: accuracy)` to scale high-rarity loot odds and is displayed in the reeling HUD banner.
- **Waypoint Anchor Radius Jitter**:
  - Added ±4px natural radius jitter to the mind-game waypoint anchors in `FishingTimingEngine`, ensuring no two fishing cycles traverse identical coordinates while strictly preserving the ~82 px/sec constant velocity.
- **Early-Game Economy Rebalance**:
  - Raised baseline sell values for ★ junk items (e.g., Soggy Homework, USB Drive, Croc) to 24–35 coins (up from 8–22) so common catches are always net-profitable against the 10-coin bait cost.
  - Increased starting player resources in `PlayerState` to 🪙150 (up from 100) and 20 bait (up from 15).
- **First Discovery vs Duplicate Polaroid Distinction**:
  - `PolaroidResultCard` now inspects discovery status: true first-time discoveries trigger the glowing amber `"✨ NEW DISCOVERY!"` badge, whereas duplicate catches display a subtle `"LOGGED JUNK (DUPLICATE)"` scrapbook tag.
- **In-Game Location Unlocking**:
  - Added `unlockedLocationIds` persistence to `PlayerState` and `unlockLocation` API to `GameDataService`.
  - `MapSheet` now features interactive travel and unlock controls, allowing players to unlock locked zones (e.g. *Abyssal Tech Trench*) for 🪙350 with live coin check and haptic feedback.
- **Default Closed Navigation Menu**:
  - The left drawer menu is now in the closed position (`_menuCollapsed = true`) by default on launch, ensuring a clean, distraction-free view of the fishing hole while keeping the toggle tab accessible on the edge.
- **Enlarged & Polished Top HUD Bar**:
  - Increased the top HUD capsule padding (16px horizontal, 8px vertical) and chip padding (10px horizontal, 5px vertical).
  - Scaled stat icons from 14px to 18px and value typography to 13px `FontWeight.w800` for significantly better readability and one-handed touch ergonomics.
- **Removed All Intrusive SnackBars**:
  - Completely removed all floating `SnackBar` popups across the core game loop (`MainFishingScreen`), market modal, inventory sheet, collections sheet, and Polaroid card.
  - Kept/sold items, purchases, and out-of-bait warnings now update state immediately with tactile haptic feedback and seamless modal transitions without blocking screen space.
- **Smooth, Constant-Speed Mind Games Ring Animation**:
  - Rebuilt the timing motion in `FishingTimingEngine` to eliminate all stuttering, erratic twitches, lag, and artificial freeze-pauses:
    - Ring expands and contracts at the exact same constant linear velocity (`Curves.linear`, ~82 px/sec) in both directions.
    - Implemented psychological mind-game paths where the ring smoothly transitions between small, medium, and big, and dives close to the inner circle (42px — 4px away from the hook) without turning orange before flowing back out.
    - Locks at 38px and turns fiery orange for ~500ms on genuine strikes, guaranteeing 100% catch on tap. If missed, smoothly retreats at the exact same constant speed without game over.
- **Streamlined Top Bar HUD (Cash, Inventory, Bait Only)**:
  - Removed the location badge ("Rusty Scrapyard Pier") entirely from the top bar.
  - Centered a clean stats capsule displaying only Cash (`🪙`), Inventory (`🎒`), and Bait (`🪱`).
  - Directs players to the dedicated Market screen on tap for refilling bait, expanding storage, or trading.
- **Added Harbor Market Screen (`MarketSheet`)**:
  - Introduced `MarketSheet` bottom modal and added `NavAction.market` to the collapsible navigation menu.
  - Features tiered bait purchases with bulk discounts (Starter Worms, Angler Bundle, Commercial Cask).
  - Features backpack upgrades to expand tackle inventory slots (+5 and +15 expansions).
  - Features integrated Scrap Pawn Dealer to quickly sell all caught junk for instant coins.
- **Unpredictable, Non-Rhythmic Fishing Motion Engine**:
  - Upgraded `FishingTimingEngine` to eliminate rhythmic metronome oscillations and deliver organic, unpredictable fish behavior:
    - Procedurally generates 2–4 randomized teaser actions before every strike: jittery micro-twitches (180ms–260ms), slow creeping crawls (900ms–1800ms), wandering drifts, and deceptive fake-outs that surge down to 46px–60px, freeze on the brink of the hook, and suddenly bolt back out.
    - Utilizes diverse easing curves (`Curves.fastOutSlowIn`, `Curves.easeOutCubic`, `Curves.easeInOutCubic`, `Curves.easeOutQuad`) and variable durations.
  - **Halved Orange Strike Window**: Cut the orange strike duration in half from ~1100ms down to ~500ms (400ms–650ms difficulty-scaled) for a tight, authentic bite reaction window.
  - Connected `RippleTimingOverlay` directly to `FishingTimingEngine`, establishing a single source of truth and removing duplicated animation state.
- **Removed Outer Border/Glow Circle from "TAP THE HOLE"**:
  - Removed the outer pulsating amber/cyan circle border and box shadow container over the stone well in `IsometricWorld`, leaving only the clean central touch badge while keeping the entire hole surface touch-sensitive.
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
- **Comprehensive AI Maintainer Manual & Technical Charter (`AGENTS.md`)**:
  - Expanded `AGENTS.md` into an in-depth technical manual for future AI agents operating on this repository.
  - Documents the full architectural layering, state machine lifecycle, constant-speed timing physics, loot math, economic loops, and the 6 mandatory operational protocols.
  - Updated `README.md` to mirror the latest direct cast state flow, market system, and constant-velocity mind-games mechanics.
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
- **Timing Catch Guarantee & Direct State Synchronization**:
  - Eliminated the race condition where `registerTap()` evaluated against sub-pixel distances rather than the active orange window state. Any tap while the ring is orange now **guarantees a successful catch**.
  - Unified the visual orange state and the logical strike state into a single authoritative property with a generous 1100ms reaction window.
- **Top HUD RenderFlex Overflow**:
  - Fixed RenderFlex overflow on the top player bar by making the location chip `Flexible` with `TextOverflow.ellipsis` and tightening stat chip padding.
- **Removed Distracting Prompt Ring**:
  - Cleaned up the `ComicSpeechBubble` dismiss button by removing the distracting background border/ring around "TAP TO CONTINUE".
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
