# AGENTS.md — AI Maintainer Charter & Guardrails

> **CRITICAL DIRECTIVE**: This project is 100% built, maintained, and operated by AI agents.
> Every AI agent interacting with this repository MUST strictly follow the architecture and guardrails defined in this document to prevent feature and design drift.

---

## 1. Core Architectural Pillars (Non-Negotiable)

1. **Platform Target**: Android-only casual/gacha collection game in Flutter. All UX, ratios, haptics, and layouts must cater to mobile portrait touch devices.
2. **Determinism**: All game mechanics, loot tables, drop odds, collection criteria, and locations MUST be driven by local JSON data (`assets/data/`). Do NOT introduce remote servers, ads, or non-deterministic server dependencies without explicit instruction.
3. **Single-Screen Stack State Machine**:
   - The game runs on a single screen (`MainFishingScreen`) utilizing a layered `Stack`.
   - Transitions strictly follow the `FishingState` enum:
     ```
     idleMenu ──> readyToCast ──> rippleActive ──> pullingRod (1.5s) ──> resultModal ──> idleMenu
     ```
   - **Never** replace this flow with traditional multi-route page navigation. Dialogs/drawers (Inventory, Collections, Map, Settings) are secondary bottom sheets or overlays on top of this state stack.
4. **Timing Mechanic Fidelity**:
   - The fishing cast timing relies on `CustomPainter` with an oscillating ripple wave moving against target boundary rings.
   - Accuracy is computed deterministically from the oscillation controller phase `[0.0, 1.0]`.
5. **Aesthetic Direction**:
   - 2D/3D isometric hybrid with vibrant dark palettes, water effects, and tactile feedback.
   - Success result is ALWAYS the vintage Polaroid discovery card modal.
   - Fail result is ALWAYS the comic speech bubble (*"Caught nothing..."*).

---

## 2. Codebase Organization

```
junk_fishing/
├── assets/
│   ├── data/                 # Deterministic local JSON datasets
│   │   ├── items.json        # Absurd item definitions, rarities, values
│   │   ├── locations.json    # Fishing zones, difficulties, drop tables
│   │   └── collections.json  # Absurd item collections & rewards
│   └── images/               # Graphic assets (character, locations, items)
├── lib/
│   ├── models/               # Pure Dart data models & enums
│   │   ├── fishing_state.dart
│   │   ├── item.dart
│   │   ├── location.dart
│   │   ├── collection.dart
│   │   └── player_state.dart
│   ├── services/             # Core logic, JSON loading & persistence
│   │   └── game_data_service.dart
│   ├── utils/                # Icon mappings, color helpers
│   ├── widgets/              # Stack layers and sub-components
│   │   ├── isometric_world.dart
│   │   ├── ripple_timing_overlay.dart
│   │   ├── polaroid_result_card.dart
│   │   ├── comic_speech_bubble.dart
│   │   ├── collapsible_nav_menu.dart
│   │   └── modals/           # Bottom sheets (inventory, collections, map, settings)
│   ├── screens/
│   │   └── main_fishing_screen.dart
│   └── main.dart
├── test/                     # Smoke and unit tests
├── CHANGELOG.md              # Log of all changes (MANDATORY UPDATE ON EDITS)
├── README.md                 # Project vision and technical manual
└── AGENTS.md                 # This file
```

---

## 3. Mandatory AI Operational Protocols

Whenever an AI agent touches this project, the agent MUST:
1. **Preserve State Machine Integrity**: Never bypass `FishingState` or split `MainFishingScreen` into separate navigators.
2. **Update CHANGELOG.md**: Every modification, bugfix, or new feature MUST be documented with clear bullet points under an appropriate version or `[Unreleased]` section.
3. **Verify Zero Linter Errors**: Run `flutter analyze` after making changes. Zero errors and zero warnings are acceptable.
4. **Validate Tests**: Run `flutter test` and update test suites if state machine transitions or models change.
5. **Keep JSON Sync**: When adding new items, ensure their `id` is mapped to valid `locations.json` and `collections.json` entries.
