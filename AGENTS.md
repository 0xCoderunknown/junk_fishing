# AGENTS.md — AI Maintainer Charter & Technical Manual

> **CRITICAL DIRECTIVE**: This project is 100% designed, maintained, and coded by AI agents.
> Every AI agent interacting with this repository MUST strictly follow the architecture, design principles, and guardrails defined in this document to prevent code rot, feature drift, and architectural decay.

---

## 1. Project Identity & Vision

- **App Name**: Junk Fishing
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
- **NEVER** introduce remote servers, web APIs, cloud databases, ads, or non-deterministic external dependencies without explicit user command.

### Pillar II: Single-Screen Stack State Machine
- The entire game executes within a single `Scaffold` (`MainFishingScreen`) utilizing a layered Flutter `Stack`.
- State transitions strictly follow the `FishingState` enum:
  ```
  readyToCast ──(tap hole)──> rippleActive ──(tap orange)──> pullingRod (1.5s) ──> resultModal ──(dismiss)──> readyToCast
  ```
- **Direct Cast Loop**: The app launches directly into `readyToCast` (`[TAP THE HOLE]`). When a result card is dismissed, the game returns directly to `readyToCast` for immediate replayability.
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
2. **Uniform Constant Speed**:
   - The outer ring expands and contracts at the **exact same constant linear speed** (`Curves.linear`, ~82 px/sec).
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
  - 1 Star (Common): High probability (~55%)
  - 2 Stars (Uncommon): Moderate probability (~25%)
  - 3 Stars (Rare): Low probability (~13%)
  - 4 Stars (Epic): Rare probability (~6%)
  - 5 Stars (Legendary): Extreme rarity (~1%)
- Timing accuracy from the tap provides a bonus multiplier toward higher rarity brackets.

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
   - Never bypass the `FishingState` flow.
   - Never split `MainFishingScreen` into separate route navigators.
   - The app must always launch directly in `FishingState.readyToCast` and return to `readyToCast` upon dismissal.
2. **Zero Linter Warnings**:
   - Run `flutter analyze` after every modification.
   - Zero errors and zero warnings are acceptable. Remove any unused imports or variables immediately.
3. **Automated Test Validation**:
   - Run `flutter test` after code changes.
   - All tests in `test/` must pass before finishing your turn.
   - If engine mechanics or state transitions change, update the corresponding test cases in `test/engine_test.dart` or `test/models_and_service_test.dart`.
4. **Mandatory CHANGELOG.md Updates**:
   - Every modification, refactoring, bugfix, or feature addition MUST be documented with clear bullet points under an appropriate section in `CHANGELOG.md`.
5. **Local JSON Consistency**:
   - If adding new items in `assets/data/items.json`, ensure their `id` is mapped to at least one entry in `locations.json` and a matching category in `collections.json`.
6. **Git Protocol**:
   - Maintain clean, descriptive commit messages describing what changed and why.

---

## 5. Environment & Tooling Troubleshooting Notes

- **Android SDK & NDK**:
  - Android SDK is located at `C:\Users\coderunknown\AppData\Local\Android\Sdk`.
  - Platforms 34, 35, 36 and CMake 3.22.1 are installed.
- **Windows Cross-Drive Pub Cache**:
  - The project resides on `K:\Android\junk_fishing`.
  - Pub cache is configured to `K:\Android\.pub-cache` via the user environment variable `PUB_CACHE=K:\Android\.pub-cache` to avoid Gradle cross-drive root path errors.
  - In `android/gradle.properties`, `kotlin.incremental=false` is set to ensure reliable builds.
