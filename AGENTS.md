# AGENTS.md — AI Maintainer Charter & Technical Manual

> **CRITICAL DIRECTIVE**: This project is 100% designed, maintained, and coded by AI agents.
> Every AI agent interacting with this repository MUST strictly follow the architecture, design principles, and guardrails defined in this document to prevent code rot, feature drift, and architectural decay.

---

## 1. Project Identity & Vision

- **App Name**: Junk Fishing (Official Title: `JUNK FISHING`)
- **Platform Target**: Android-only casual/gacha collection game built with Flutter.
- **Orientation**: Portrait-only (`DeviceOrientation.portraitUp`). All UI components, hit targets, and touch interactions must cater strictly to one-handed mobile touch ergonomics.
- **Theme & Lore**: Instead of catching ordinary fish, the player dredges absurd junk, bizarre relics, obsolete technology, and eccentric curiosities from forgotten wells and strange waterways.
- **Core Aesthetic**: Atmospheric 2D/3D top-down isometric view with dark woodland palettes, animated water ripples, warm lantern lighting, and tactile haptic feedback.

---

## 2. Core Architectural Pillars (Non-Negotiable)

### Pillar I: Deterministic & 100% Offline
- All drop rates, item pools, locations, and collections MUST be driven by local JSON datasets in `assets/data/`:
  - `items.json`: Absurd items, rarity stars (1 to 5), scrap coin values, weights, flavor text.
  - `locations.json`: Fishing zones, difficulty multipliers, water/theme hex colors, available item drop IDs.
  - `collections.json`: Absurd thematic milestone sets and coin rewards.
- **NEVER** introduce remote servers, web APIs, cloud databases, ads, analytics, or non-deterministic external dependencies without explicit user command.

### Pillar II: Single-Screen Stack State Machine
- The entire game executes within a single `Scaffold` (`MainFishingScreen`) utilizing a layered Flutter `Stack`.
- State transitions strictly follow the 4-state `FishingState` enum:
  ```
  readyToCast ──(tap hole)──> rippleActive ──(tap orange)──> pullingRod (1.5s) ──> resultModal ──(dismiss)──> readyToCast
  ```
- **Direct Cast Loop**: The app launches directly into `readyToCast` (`[TAP THE HOLE]`). When a result card is dismissed, the game returns directly to `readyToCast` for immediate replayability.
- **Legacy States Dropped**: The legacy `idleMenu` state is completely removed. There is no intermediate idle menu state.
- **NEVER** replace this state stack with traditional multi-route page navigation (`Navigator.push`). All secondary features (Market, Inventory, Collections, Map, Settings) are secondary bottom sheets (`showModalBottomSheet`) or overlays on top of this state stack.

### Pillar III: Separation of Concerns (Engine vs Presentation)
To prevent spaghetti code, pure game logic is strictly isolated from Flutter UI widgets:
```
junk_fishing/
├── assets/data/                 # Local deterministic JSON datasets
├── lib/
│   ├── engine/                  # Pure Dart mechanics (ZERO Flutter UI dependencies)
│   │   ├── fishing_timing_engine.dart # Torchlight ring velocity & mind-game simulation
│   │   └── loot_engine.dart           # Weighted drop roller & rarity calculations
│   ├── models/                  # Pure Dart data models & enums
│   ├── services/                # SharedPreferences & local JSON data service
│   ├── rendering/               # Modular CustomPainters & canvas drawing
│   │   └── scene_painters.dart        # Environment, Lantern, Well & Fisherman painters
│   ├── utils/                   # Icon mappings & rarity palette helpers
│   ├── widgets/                 # Presentation layers & bottom sheets
│   │   ├── isometric_world.dart       # World scene with stone well & fisherman
│   │   ├── ripple_timing_overlay.dart # Blur overlay driving the ring animation
│   │   ├── polaroid_result_card.dart  # Retro Polaroid discovery card (Success)
│   │   ├── comic_speech_bubble.dart   # Comic fail speech bubble (Miss)
│   │   ├── collapsible_nav_menu.dart  # Sliding left drawer & top HUD capsule
│   │   └── modals/                    # Bottom sheets (market, inventory, collections, map, settings)
│   ├── screens/
│   │   └── main_fishing_screen.dart   # Stack coordinator & state machine driver
│   └── main.dart                      # Portrait-locked entrypoint
├── test/                        # Deterministic engine & widget test suites
├── CHANGELOG.md                 # Change history (MANDATORY UPDATE ON EVERY EDIT)
├── README.md                    # Project manual & documentation
└── AGENTS.md                    # This AI operational charter
```

---

## 3. How the Game Mechanics Work

### A. The Timing Engine (`FishingTimingEngine`)
The fishing minigame is inspired by the Torchlight fishing timing mechanic, tuned for smooth psychological tension:
1. **Geometry**:
   - Fixed central hook and inner ring at radius `innerRingRadius = 38.0px`.
   - Dynamic outer ring travels between `maxOuterRadius = 135.0px` and `38.0px`.
2. **Organic Easing with Constant Travel Budget**:
   - Travel duration is strictly budgeted at ~82 px/sec constant velocity proportional to distance.
   - Within each phase, motion curves organically via pure Dart mathematical easing (`easeInOut` for nibbles, `decelerate` for deep teases, `easeIn` for strike surges, `easeOut` for retreats).
   - There are **ZERO** artificial pauses, lags, or jitter steps during travel.
3. **Mind-Games Paths**:
   - Waypoints cycle smoothly through Small (~55px), Medium (~80–90px), and Big (~130px).
   - **Deep Tease**: The ring can smoothly dive close to the inner circle (**42px**, just 4px away from the hook), **without turning orange**, and then smoothly head back out. This plays mind games with the player's reflexes.
4. **Strike Window**:
   - On a genuine strike, the ring contacts the 38px inner ring, locks, and turns **fiery ORANGE** for **~500ms**.
   - Haptic feedback fires the instant it turns orange.
   - Any tap on the screen while orange guarantees a **100% successful catch**.
5. **Non-Punitive Misses**:
   - If the player lets the orange window pass without tapping, the fish releases the hook and the ring smoothly expands outward at the same constant speed, seamlessly beginning a new pattern without game over.
   - Only tapping prematurely while the ring is blue/cyan results in a snapped line / early pull.

### B. The Loot Engine (`LootEngine`)
- When a catch succeeds, `LootEngine.rollCatch()` selects an item from the current location's `availableItemIds`.
- Drop rolls use weighted rarity thresholds:
  - 1 Star (Common): High probability (~50%)
  - 2 Stars (Uncommon): Moderate probability (~28%)
  - 3 Stars (Rare): Low probability (~14%)
  - 4 Stars (Epic): Rare probability (~6%)
  - 5 Stars (Legendary): Extreme rarity (~2%)
- Timing accuracy from the tap provides a bonus multiplier toward higher rarity brackets (shifting odds toward 3★, 4★, and 5★ tiers).

### C. The Economy & Market (`MarketSheet`)
- **Top HUD**: Strictly displays only three core resources in a clean capsule:
  - **Cash** (`🪙 ${playerState.money}`)
  - **Inventory** (`🎒 ${inventory.length}/${storageLimit}`)
  - **Bait** (`🪱 ${playerState.baitCount}`)
- **Harbor Market (`MarketSheet`)**:
  - Tapping Cash or Bait in the top HUD (or choosing Market from the nav menu) opens `MarketSheet`.
  - **Bait Supplies**: Starter Worms (5 for 🪙 50), Angler Bundle (20 for 🪙 180), Commercial Cask (50 for 🪙 400).
  - **Backpack Upgrades**: Expand storage capacity (+5 slots for 🪙 150, +15 slots for 🪙 400).
  - **Scrap Pawn Dealer**: One-tap "Quick Sell All Scrap" converts caught junk into coins.

---

## 4. Mandatory Operational Protocols for AI Agents

Whenever an AI agent touches this project, the agent **MUST** adhere to the following checklist:

1. **State Machine Integrity**:
   - Never bypass the 4-state `FishingState` flow (`readyToCast`, `rippleActive`, `pullingRod`, `resultModal`).
   - Never reintroduce `idleMenu` or split `MainFishingScreen` into separate route navigators.
   - The app must always launch directly in `FishingState.readyToCast` and return to `readyToCast` upon dismissal.
2. **Modern Imports & Deprecation Bans**:
   - **BANNED**: `package:flutter/material.dart` and `package:flutter/cupertino.dart` are deprecated in Flutter 3.50+ and strictly forbidden.
   - **REQUIRED**: All UI code MUST import `package:material_ui/material_ui.dart`.
3. **Zero Linter Warnings**:
   - Run `flutter analyze` after every modification.
   - Zero errors and zero warnings are acceptable. Remove any unused imports, dead variables, or obsolete code immediately.
4. **Automated Test Validation**:
   - Run `flutter test` after code changes.
   - All tests in `test/` must pass (100% pass rate) before completing your turn.
   - If engine mechanics or state transitions change, update the corresponding test cases in `test/engine_test.dart` or `test/models_and_service_test.dart`.
5. **UTF-8 Encoding & Anti-Mojibake Mandate**:
   - All source code, data files, tests, and markdown files MUST be encoded in strict UTF-8 without BOM.
   - Corrupted byte sequences (e.g. `â˜…`, `ðŸª™`, `â€¢`, `â€”`, `â€œ`) are strictly prohibited. Always use clean UTF-8 literals: `★`, `🪙`, `•`, `—`, `“`, `”`, `→`, `°`, `×`.
6. **Player-Focused CHANGELOG.md Updates**:
   - Document user-facing features, balance tweaks, visual enhancements, and bug fixes under standard sections (`Added`, `Changed`, `Fixed`).
   - Do not pollute `CHANGELOG.md` with internal code refactoring trivia, plumbing details, or build-environment notes. Keep it clean and meaningful.
7. **Local JSON Consistency**:
   - If adding new items in `assets/data/items.json`, ensure their `id` is mapped to at least one entry in `locations.json` and a matching category in `collections.json`.
8. **Git Protocol**:
   - Maintain clean, descriptive commit messages describing what changed and why.

---

## 5. Toolchain Baseline & Dropped Legacy Support

### Dropped Legacy Support (Strictly Prohibited)
- **NO Legacy Java**: JDK 8, 11, and 17 are deprecated/dropped. Java 24 is the pinned standard.
- **NO Legacy Gradle**: Gradle < 9.0 is dropped. Gradle 9.5.0 is the project standard.
- **NO Legacy AGP**: Android Gradle Plugin < 9.0 is dropped. AGP 9.3.1 is the project standard.
- **NO Legacy Kotlin**: Kotlin < 2.4.0 is dropped. Kotlin 2.4.20 is the project standard.
- **NO Legacy Deprecated Gradle DSL**: `kotlinOptions { jvmTarget = ... }` is forbidden. Use `kotlin { jvmToolchain(24) }`.
- **NO Multi-Platform Targets**: Web, iOS, macOS, Windows desktop, and Linux targets are explicitly unsupported and removed. The app is 100% Android-only.

### Active Pinned Toolchain Specifications
- **Flutter SDK**: `>= 3.50.0`
- **Dart SDK**: `^3.14.0` (Dart 3 with records, patterns, sealed classes, and sound null safety)
- **Gradle Distribution**: `9.5.0` (`android/gradle/wrapper/gradle-wrapper.properties`)
- **Android Gradle Plugin (AGP)**: `9.3.1` (`android/settings.gradle.kts`)
- **Kotlin Gradle Plugin**: `2.4.20` (`android/settings.gradle.kts`)
- **JVM Toolchain**: JDK 24 (`kotlin { jvmToolchain(24) }`, `sourceCompatibility = JavaVersion.VERSION_24`, `targetCompatibility = JavaVersion.VERSION_24`)
- **Gradle Java Home**: Pinned to `C:\Program Files\Java\jdk-24` in `android/gradle.properties` (`org.gradle.java.home=C:\\Program Files\\Java\\jdk-24`).
- **Android SDK**: `C:\Users\coderunknown\AppData\Local\Android\Sdk` (Platforms 34, 35, 36; CMake 3.22.1).
- **Windows Cross-Drive Pub Cache**:
  - Pub cache is isolated to `K:\Android\.pub-cache` via `PUB_CACHE=K:\Android\.pub-cache` to avoid Windows cross-drive Gradle path failures.
  - In `android/gradle.properties`, `kotlin.incremental=false` is enforced for build stability.
