# Changelog

All notable changes to the "Junk Fishing" project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

---

## [0.1.3] - 2026-11-04

### Added
- **Dynamic Polaroid Card Flight Animation**:
  - Tapping **KEEP** or **SELL** sends the Polaroid discovery card flying smoothly from screen center into the exact coordinates of the top HUD bar chips, scaling down as it arrives.
- **Floating HUD Delta Badges**:
  - Gold `+ [amount]` floating badges appear over Cash upon selling, and teal `+1` badges appear over Inventory upon keeping items, floating upward and fading out.
- **Custom Hook App Launcher Icon**:
  - Integrated high-resolution hook icon across all Android launcher densities (`mdpi`, `hdpi`, `xhdpi`, `xxhdpi`, `xxxhdpi`).

### Changed
- **Streamlined Fishing Hole Touch Zone**:
  - Removed central prompt overlay ring to prevent visual overlap with animated water ripples; the entire stone well opening serves as a clean, responsive touch target.
- **Redesigned Bottom Strike Button**:
  - Replaced small indicators with a prominent action capsule providing dynamic cues (*"WAIT FOR STRIKE..."* while watching $\rightarrow$ *"STRIKE NOW!"* during fiery orange bites).
- **Official Title Consistency**:
  - Standardized title to **Junk Fishing** across launcher labels, app headers, and share dialogues.

---

## [0.1.2] - 2026-11-04

### Added
- **Visual Depth & Tension Cues**:
  - Thin curved fishing line drawn from rod tip down to the hook eyelet.
  - Concentric water depth rings providing visual scale for estimating ring distance.
  - Smooth sparkle beads orbiting the outer ring at constant velocity.

### Changed
- **Organic Motion Easing**:
  - Waypoint teases now glide smoothly with natural deceleration and acceleration curves.
  - Deep teases dive inward swiftly then creep to a halt just outside the orange strike zone.
  - Genuine bites accelerate into the hook, while missed bites snap away with a tension-release retreat.
- **Dynamic Proximity & Strike Effects**:
  - Outer ring color continuously warms from cyan toward amber as it nears the center.
  - Inner hook ring strobes with amber light during the orange strike window.
  - Ambient breathing pulse gently illuminates the outer ring during tracking phases.

### Fixed
- Rod pull animation timer lifecycle properly managed to prevent ghost state transitions on rapid taps.

---

## [0.1.1] - 2026-11-04

### Changed
- **Graded Timing Accuracy**:
  - Tapping dead-center within the orange bite window awards 100% accuracy, while edge taps award ~65%–75%.
  - High accuracy directly boosts odds of rolling rare and legendary loot tiers.
- **Precision Haptic Synchronization**:
  - Haptic bite vibration fires on the exact frame the ring turns orange.

### Fixed
- Fixed floating-point boundary calculation in loot gacha weight selection.
- Prevented drift across extended play sessions by snapping ring radius to target boundaries at phase ends.

---

## [0.1.0] - 2026-11-04

### Added
- **Direct Tap-to-Cast Flow**:
  - The game launches directly into the fishing scene ready to cast; dismissing catch cards returns immediately to the fishing hole for fast, repetitive play.
- **Harbor Market Modal**:
  - Added dedicated market sheet offering tiered bait supplies (Starter Worms, Angler Bundle, Commercial Cask), tackle bag expansions (+5 and +15 slots), and instant scrap pawn selling.
- **Zone Exploration & Unlocking**:
  - Interactive map sheet with unlockable fishing zones including the *Abyssal Tech Trench*.
- **Discovery Log Distinction**:
  - First-time item catches feature a glowing *"NEW DISCOVERY!"* banner, while duplicate catches are marked as logged scrap.
- **Top-Down Isometric World View**:
  - Rich forest scene featuring stone well masonry, animated water ripples, lantern post with ambient lighting shader, and top-down character.

### Changed
- **Torchlight-Style Timing Minigame**:
  - Timing ring operates on unpredictable waypoint paths with deep false-bite teases.
  - Orange bite window tuned to ~500ms for a fair, crisp reaction challenge.
  - Missed strikes safely retreat and generate fresh patterns without game over penalties.
- **Economy Rebalance**:
  - Raised scrap values for common junk so catches remain net-profitable against bait costs.
  - Boosted starting player resources to 🪙150 and 20 bait.
- **Streamlined Top HUD**:
  - Simplified top bar to strictly display Cash (`🪙`), Inventory (`🎒`), and Bait (`🪱`) in a clean pill capsule.
- **Default Closed Navigation**:
  - Left navigation drawer is closed by default on launch for an unobstructed view of the fishing scene.

### Fixed
- Resolved RenderFlex layout overflow in the top player HUD on compact screens.
- Eliminated all intrusive floating SnackBars in favor of instant haptic feedback and clean in-place updates.
- Guaranteed 100% catch rate on any tap inside the orange bite window.

---

## [0.0.1] - 2026-10-11

### Added
- Initial release of **Junk Fishing**:
  - Single-screen stack state machine driving core fishing loop.
  - 18 absurd junk items across 3 thematic collections and 3 locations.
  - Offline local JSON data engine and SharedPreferences persistence.
  - Polaroid catch result cards with device screenshot sharing.
  - Comic fail speech bubble for missed catches.
  - Modal sheets for inventory management, collection milestone rewards, and settings.
