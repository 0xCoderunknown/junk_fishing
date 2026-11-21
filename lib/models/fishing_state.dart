/// Single-screen state machine states for Junk Fishing.
enum FishingState {
  /// Menu slides off-screen. Tapping the water pond initiates the cast.
  readyToCast,

  /// Background blurs. Centered timing overlay appears showing an oscillating ripple wave
  /// moving up/down toward target boundary rings.
  rippleActive,

  /// Player tapped. Rod pull animation triggers for 1.5s, background unblurs, ripple fades.
  pullingRod,

  /// Success Polaroid discovery card modal OR comic speech bubble fail ("Caught nothing...").
  resultModal,
}
