# Changelog

All notable changes to the "Junk Fishing" project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

---

## [0.1.3] - 2026-11-04

### Added
- **Official App Branding — JUNK FISHING**:
  - Standardized the official game title to **JUNK FISHING** across `AndroidManifest.xml` (`android:label`), `MaterialApp` title, in-app settings footer, Polaroid share card, and maintainer documentation.
- **Custom Hook Launcher App Icon**:
  - Incorporated `hook.png` into `assets/images/app_icon.png`.
  - Generated full-density Android launcher icons across all mipmap targets (`mdpi` 48x48, `hdpi` 72x72, `xhdpi` 96x96, `xxhdpi` 144x144, `xxxhdpi` 192x192) with high-quality bicubic interpolation and transparency.

### Refactored & Optimized (Codebase Refactor Audit)
- **Zero Flutter UI Dependencies in Engine** (`lib/engine/fishing_timing_engine.dart`):
  - Removed `package:flutter/animation.dart` and implemented pure Dart `EasingCurves` (`linear`, `easeInOut`, `easeIn`, `easeOut`, `decelerate`) with a `typedef EasingCurve = double Function(double t)` signature.
  - Ensures `lib/engine/` strictly adheres to Pillar III (100% pure Dart mechanics).
- **Atomic Single-Pass Scrap Selling** (`lib/services/game_data_service.dart`):
  - Introduced `sellAllScrap()` which computes total value, clears inventory, updates discovered items, and executes a single atomic write to `SharedPreferences`, replacing O(N) sequential disk write loops in inventory and market sheets.
- **Service Reactivity** (`lib/services/game_data_service.dart`):
  - Extended `ChangeNotifier` so data service state mutations automatically notify listening widgets.
- **Unified Modal Shell Architecture** (`lib/widgets/modals/game_bottom_sheet.dart`):
  - Created reusable `GameBottomSheet` standardizing sheet height, drag handle, dark container styling, and header rows across `InventorySheet`, `MarketSheet`, `CollectionsSheet`, `MapSheet`, and `SettingsSheet`.
- **Render & Animation Performance Optimizations**:
  - `IsometricWorld`: Wrapped static environment layers (`EnvironmentPainter`, `LanternLightingPainter`) in `RepaintBoundary` to decouple them from the high-frequency ripple animation.
  - `RippleTimingOverlay`: Isolated `BackdropFilter` in a `RepaintBoundary` so high-frequency ring ticks do not invalidate expensive GPU blur textures.
  - `ComicSpeechBubble`: Replaced `Positioned` layout updates with GPU-accelerated `Transform.translate` within `AnimatedBuilder`.
- **Model Integrity & Deduplication**:
  - `Item`: Implemented `operator ==` and `hashCode` based on item attributes.
  - `Collection`: Added single-pass `getStatus()` returning `({int found, int total, double progress, bool isComplete})` to eliminate duplicate set operations.
- **Dead Code Cleanup & Platform Conformance**:
  - Removed unused `onBuyBait` and `onUpgradeStorage` callbacks from `CollapsibleNavMenu` and `MainFishingScreen`.
  - Removed unused `playerState` constructor parameter from `InventorySheet`.
  - Locked orientation strictly to `[DeviceOrientation.portraitUp]` in `lib/main.dart` per `AGENTS.md`.
  - Corrected `SettingsSheet` copy to reflect actual initial balance (150 coins, 20 bait).

## [0.1.2] - 2026-11-04

### Fixed
- **Rod Pull Timer Lifecycle Managed** (`main_fishing_screen.dart`):
  - Stored `_pullTimer` instance in `_MainFishingScreenState` and added explicit cancellation in `dispose()` and prior to new timer creation, preventing potential memory leaks or post-dispose state mutation callbacks during rapid state transitions.

### Changed (Ring Gameplay Refinements)
- **Organic easing curves per motion phase** (`fishing_timing_engine.dart`):
  - `teaseNibble` → `Curves.easeInOut`: ring decelerates into each waypoint and accelerates away — like a living creature cautiously circling the bait.
  - `deepTease` → `Curves.decelerate`: dives in fast then creeps to a stop just outside orange. Maximum fake-out effect — the ring nearly tricks you into tapping.
  - `strikeContraction` → `Curves.easeIn`: starts slow and accelerates as it closes — the fish commits, urgency builds.
  - `retreat` → `Curves.easeOut`: snaps away fast then drifts off — the tension releases, the fish gets away.
  - Duration of each phase is still calculated from constant-speed distance (~82 px/sec), so total cycle timing is predictable. Only the within-phase motion curve changes.
- **Fishing line drawn from canvas top to hook** (`ripple_timing_overlay.dart`):
  - A thin bezier-curved line is now painted from the top of the ring canvas down to the hook eyelet, giving the hook visual context and making the scene feel grounded.
  - Line brightens and thickens slightly during the orange strike window.
- **Breathing glow on outer ring** (`ripple_timing_overlay.dart`):
  - Outer ring glow width slowly oscillates using a 1.8-second sine wave even when the ring isn't in a strike window, creating an ambient tension "pulse" that feels alive.
  - Glow speed increases significantly during strike (strobe effect).
- **Proximity color tint on outer ring** (`ripple_timing_overlay.dart`):
  - Outer ring color continuously lerps from cyan → amber as the ring approaches the inner ring. At maximum distance it is pure `#90E0EF` (cyan). As it closes in, it warms toward `#FFB347` (amber), giving a visual early warning before orange.
- **Independent bead rotation** (`ripple_timing_overlay.dart`):
  - The 4 sparkle beads now orbit the outer ring at a constant angular velocity (full revolution every 3.5s), decoupled from ring radius. Previously they moved erratically as a function of `radius * 0.05`, which caused jitter.
- **Strike strobe on inner ring** (`ripple_timing_overlay.dart`):
  - Inner ring glow width and fill opacity strobe at ~5Hz during the orange window, creating an unmistakable urgent visual cue.
- **Concentric water depth rings** (`ripple_timing_overlay.dart`):
  - Two faint static ambient rings at 75px and 110px radius provide spatial depth cues, making the outer ring's position easier to judge.

## [0.1.1] - 2026-11-04

### Fixed (Gameplay Mechanics Audit)
- **`_phaseStartTimeMs` sentinel changed from `0` to `-1`** (`fishing_timing_engine.dart`):
  - Using `0` as a sentinel was unsafe because Unix epoch `0` is a theoretically valid timestamp. Changed to `-1` to eliminate any risk of a one-tick stale-frame calculation at phase boundaries. Guard in `update()` now checks `< 0` instead of `== 0`.
- **Radius snaps to exact float target at phase completion** (`fishing_timing_engine.dart`):
  - Added `_currentRadius = _targetRadius` snap when `progress >= 1.0` before advancing to the next phase, preventing tiny floating-point drift from accumulating across hundreds of phase transitions.
- **`setState` guard in `RippleTimingOverlay._onTick`** (`ripple_timing_overlay.dart`):
  - `setState` is now only called when radius actually changed (delta > 0.01px) or strike state flipped, eliminating hundreds of no-op rebuilds per second on idle frames.
- **Haptic now uses `update()` return value** (`ripple_timing_overlay.dart`):
  - Haptic on orange entry now uses the boolean returned by `engine.update()` (true exactly when orange state transitions on that frame) rather than a re-read of `isInOrangeStrikeWindow`. Guarantees the haptic fires precisely on the frame the ring turns orange, with no duplicate triggers.
- **`LootEngine` timing bonus normalization** (`loot_engine.dart`):
  - `timingBonus` is now explicitly normalized from accuracy range `[0.65 – 1.0]` to `[0.0 – 1.0]` before applying rarity weight bonuses. Previously, even a bare edge-tap (accuracy 0.65) received 65% of the maximum rarity bonus, making the bonus nearly constant. Now a perfect center tap (1.0) grants full bonus; an edge tap (0.65) grants zero.
  - Changed weighted roll comparison from `roll <= cumulative` to `roll < cumulative` to correctly handle the floating-point edge case where `roll` exactly equals `totalWeight`.
- **Clarified `strikeTolerance` as display-only** (`fishing_timing_engine.dart`):
  - Added code comment clarifying `strikeTolerance` is not used in tap resolution (purely time-based), preventing future maintainers from treating it as a pixel-proximity gate.

### Added (Tests)
- **`engine_test.dart` expanded from 7 to 13 tests**:
  - `After retreat phase engine automatically begins a new cycle` — engine perpetually recycles without finishing after missed strikes.
  - `Radius snaps to exact target value at phase boundary` — large time jumps don't leave radius outside valid bounds.
  - `LootEngine with timingBonus=0.0 uses base weights` — no-bonus catches return valid pool items.
  - `LootEngine with perfect accuracy (1.0) still returns valid item` — high-bonus path works end-to-end.
  - `LootEngine with minimum accuracy (0.65) grants no rarity bonus` — normalization verified: edge-tap accuracy is indistinguishable from zero bonus with identical RNG seed.
  - `LootEngine returns fallback item when pool is empty` — empty location pool fallback branch covered.

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
