# 🎣 Junk Fishing

An Android-only casual/gacha collection game built with Flutter.

Instead of fishing for normal aquatic life, the player dredges up weird, absurd artifacts, obsolete technology, and bizarre curiosities from polluted waterways and cybernetic canals.

---

## 🎮 Core Gameplay Loop

The game runs as a **single-screen Stack state machine**:

```
[1. IDLE_MENU]
       │  (Tap "Cast Line")
       ▼
[2. FISHING_READY]  ── Menu slides away, tap highlighted water pond
       │  (Tap Water Pond)
       ▼
[3. RIPPLE_TIMING]  ── World blurs, oscillating ripple wave moves toward target rings
       │  (Player Taps to Hook)
       ▼
[4. PULL_RESOLVE]   ── World unblurs, character triggers a 1.5s rod pull animation
       │  (1.5s Timer Elapsed)
       ▼
[5. RESULT_POPUP]
       ├── SUCCESS: Polaroid discovery card modal (Keep / Sell / Share)
       └── FAIL: Comic speech bubble ("Caught nothing...")
       │  (Dismissed)
       ▼
[6. RETURN_IDLE]    ── Returns to IDLE_MENU
```

---

## ⚙️ Architecture & Design Principles

- **100% Deterministic & Local**: All mechanics, loot tables, items, and locations are driven entirely by local JSON files located in `assets/data/`.
- **Single-Screen Stack**: The whole game experience resides on `MainFishingScreen` using a layered `Stack` with `BackdropFilter` and `CustomPainter`.
- **No External Servers**: Designed to be fully offline and self-contained.
- **AI-Maintained**: Read [AGENTS.md](file:///k:/Android/junk_fishing/AGENTS.md) for strict rules governing agent contributions and preventing architectural drift.

---

## 📁 Project Structure

```
lib/
├── models/
│   ├── fishing_state.dart      # Enum state machine
│   ├── item.dart               # Absurd junk item data model
│   ├── location.dart           # Fishing zone data model
│   ├── collection.dart         # Collection sets data model
│   └── player_state.dart       # Persistent player wallet, bait & inventory
├── services/
│   └── game_data_service.dart  # JSON asset loader, save/load, gacha roller
├── utils/
│   └── item_icon_helper.dart   # Icon and rarity color mapping
├── widgets/
│   ├── isometric_world.dart    # CustomPainter world: pier, water, fisherman
│   ├── ripple_timing_overlay.dart # Blur + CustomPainter timing mechanic
│   ├── polaroid_result_card.dart  # Retro Polaroid discovery card (with share)
│   ├── comic_speech_bubble.dart   # Cartoon fail speech bubble
│   ├── collapsible_nav_menu.dart  # Sliding left menu and HUD
│   └── modals/                 # Inventory, collections, map, and settings sheets
├── screens/
│   └── main_fishing_screen.dart # Stack state machine root
└── main.dart                   # Android portrait entrypoint
```

---

## 📦 Data Files (`assets/data/`)

- `items.json`: Absurd item descriptions, rarities (1 to 5 stars), estimated values, and collection tags.
- `locations.json`: Fishing locations, difficulty coefficients, and available item loot pools.
- `collections.json`: Thematic item sets with milestone scrap coin rewards.

---

## 🛠️ Development & Testing

Run analysis:
```bash
flutter analyze
```

Run tests:
```bash
flutter test
```

Run on an Android device/emulator:
```bash
flutter run
```

---

## 📜 Maintenance Rules

Refer to:
- [AGENTS.md](file:///k:/Android/junk_fishing/AGENTS.md): Strict guidelines and protocol for AI agents.
- [CHANGELOG.md](file:///k:/Android/junk_fishing/CHANGELOG.md): History of all features and architectural changes.
