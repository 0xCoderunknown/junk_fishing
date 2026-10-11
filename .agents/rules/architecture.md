# Junk Fishing Anti-Drift Architecture Rules

1. **Android Only**: Game layout, resolution, and touch targets are strictly designed for Android mobile portrait.
2. **Single-Screen Stack**: Never introduce Navigator routes for the core game loop. All game states exist within `MainFishingScreen`'s `Stack` state machine (`FishingState`).
3. **Deterministic Mechanics**: All items, locations, and collections must come from `assets/data/*.json`. No backend dependencies.
4. **Fidelity of Feedback**:
   - `rippleActive`: `BackdropFilter` + `CustomPainter` ripple timing mechanic.
   - `pullingRod`: Exactly 1.5 seconds rod tension/splash animation before showing results.
   - `resultModal`: Polaroid discovery card for success; comic speech bubble for fail.
5. **Mandatory Documentation**: Always record modifications in `CHANGELOG.md` and adhere to `AGENTS.md`.
