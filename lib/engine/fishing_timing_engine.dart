import 'dart:math';
import 'package:flutter/animation.dart';

/// Phase types for the Torchlight-style fishing mechanic
enum TimingPhaseType {
  teaseNibble,
  deepTease,
  strikeContraction, // Ring contracting toward center (blue/cyan)
  strikeWindow,      // RINGS MET! TURNS ORANGE - PLAYER MUST TAP HERE!
  retreat,           // Missed window - ring smoothly opens back up
}

class RingPhase {
  final double targetRadius;
  final int durationMs;
  final Curve curve;
  final TimingPhaseType type;

  RingPhase({
    required this.targetRadius,
    required this.durationMs,
    required this.curve,
    required this.type,
  });

  bool get isOrangeStrike => type == TimingPhaseType.strikeWindow;
}

/// Pure Dart fishing timing simulation engine.
///
/// Torchlight Timing Dynamics:
/// - A central hook sits inside a fixed inner ring (radius: 38px).
/// - Outer ring glides calmly through 1-2 teasing contractions.
/// - When a strike occurs:
///   1. `strikeContraction`: The ring contracts down toward the inner ring (~1200ms). It is still BLUE/CYAN here!
///   2. `strikeWindow`: The instant the ring reaches the inner ring, IT LOCKS AT 38px AND TURNS ORANGE!
///      The orange window stays active for a generous 950ms (human-friendly reaction window).
///      Any tap during this period is a guaranteed catch!
///   3. If the player doesn't tap during the orange window, it smoothly expands back out to retry without game over.
class FishingTimingEngine {
  final double difficultyMultiplier;
  final Random _rng;

  static const double innerRingRadius = 38.0;
  static const double maxOuterRadius = 135.0;

  late final double strikeTolerance;

  List<RingPhase> _phases = [];
  int _phaseIndex = 0;
  double _currentRadius = maxOuterRadius;
  double _startRadius = maxOuterRadius;
  double _targetRadius = maxOuterRadius;
  int _phaseStartTimeMs = 0;
  int _phaseDurationMs = 1200;
  Curve _phaseCurve = Curves.easeInOut;

  bool _isFinished = false;

  FishingTimingEngine({
    this.difficultyMultiplier = 1.0,
    Random? rng,
  }) : _rng = rng ?? Random() {
    // Generous strike tolerance: 22px buffer
    strikeTolerance = (22.0 / difficultyMultiplier).clamp(16.0, 30.0);
    generateCycle();
  }

  double get currentRadius => _currentRadius;
  bool get isFinished => _isFinished;
  RingPhase? get currentPhase =>
      _phaseIndex < _phases.length ? _phases[_phaseIndex] : null;

  /// Exactly matches what the user sees on screen:
  /// True if and only if the current phase is [TimingPhaseType.strikeWindow]
  /// OR the ring is within the generous strike tolerance of the center hook!
  bool get isInOrangeStrikeWindow {
    if (_isFinished || currentPhase == null) return false;
    
    // During the dedicated orange linger window, it is ALWAYS active orange!
    if (currentPhase!.isOrangeStrike) {
      return true;
    }
    
    // Also active if contracting close during a strike attempt
    if (currentPhase!.type == TimingPhaseType.strikeContraction) {
      final dist = (_currentRadius - innerRingRadius).abs();
      return dist <= strikeTolerance;
    }
    
    return false;
  }

  /// Generates a smooth, natural Torchlight-paced movement cycle
  void generateCycle() {
    _phases = [];
    final diff = difficultyMultiplier;

    // 1 to 2 calm teasing contractions
    final teaseCount = 1 + _rng.nextInt(2);

    for (int i = 0; i < teaseCount; i++) {
      final teaseKind = _rng.nextInt(3);
      double shrinkTo;
      TimingPhaseType pType;

      if (teaseKind == 0) {
        // Deep tease: smoothly glides near the inner ring (65-75px), but doesn't strike or turn orange!
        shrinkTo = innerRingRadius + strikeTolerance + 15.0 + _rng.nextDouble() * 15.0;
        pType = TimingPhaseType.deepTease;
      } else if (teaseKind == 1) {
        // Moderate nibble
        shrinkTo = 75.0 + _rng.nextDouble() * 20.0;
        pType = TimingPhaseType.teaseNibble;
      } else {
        // Shallow ripple
        shrinkTo = 95.0 + _rng.nextDouble() * 25.0;
        pType = TimingPhaseType.teaseNibble;
      }

      // Smooth deliberate travel speed: ~1100ms - 1500ms
      final shrinkDuration = (1200 + _rng.nextInt(400)) ~/ diff;
      _phases.add(RingPhase(
        targetRadius: shrinkTo,
        durationMs: shrinkDuration.clamp(900, 1600),
        curve: Curves.easeInOutSine,
        type: pType,
      ));

      // Gentle pause/float back out: ~1000ms - 1400ms
      final expandTo = min(maxOuterRadius, shrinkTo + 35.0 + _rng.nextDouble() * 40.0);
      final expandDuration = (1100 + _rng.nextInt(350)) ~/ diff;
      _phases.add(RingPhase(
        targetRadius: expandTo,
        durationMs: expandDuration.clamp(800, 1500),
        curve: Curves.easeInOutSine,
        type: TimingPhaseType.teaseNibble,
      ));
    }

    // STEP 1: Contraction down to the inner ring (Steady, predictable motion)
    final strikeDuration = (1250 + _rng.nextInt(250)) ~/ diff;
    _phases.add(RingPhase(
      targetRadius: innerRingRadius,
      durationMs: strikeDuration.clamp(1000, 1600),
      curve: Curves.easeInOutQuad,
      type: TimingPhaseType.strikeContraction,
    ));

    // STEP 2: The ORANGE BITE WINDOW (Outer ring meets inner ring & turns fiery orange!)
    // Generous human-friendly window: ~950ms
    final windowMs = (950 / diff).clamp(750, 1200).toInt();
    _phases.add(RingPhase(
      targetRadius: innerRingRadius,
      durationMs: windowMs,
      curve: Curves.linear,
      type: TimingPhaseType.strikeWindow,
    ));

    // STEP 3: Smooth retreat without penalty if player missed the window
    final retreatRadius = maxOuterRadius - (_rng.nextDouble() * 15.0);
    _phases.add(RingPhase(
      targetRadius: retreatRadius,
      durationMs: (1100 + _rng.nextInt(300)) ~/ diff,
      curve: Curves.easeOutSine,
      type: TimingPhaseType.retreat,
    ));

    _applyPhase(0);
  }

  void _applyPhase(int index) {
    if (index >= _phases.length) {
      generateCycle();
      return;
    }

    _phaseIndex = index;
    final phase = _phases[index];
    _startRadius = _currentRadius;
    _targetRadius = phase.targetRadius;
    _phaseDurationMs = phase.durationMs;
    _phaseCurve = phase.curve;
    _phaseStartTimeMs = DateTime.now().millisecondsSinceEpoch;
  }

  /// Updates radius based on elapsed frame time. Returns whether orange state changed.
  bool update(int nowMs) {
    if (_isFinished) return false;

    final elapsed = nowMs - _phaseStartTimeMs;
    final progress = (elapsed / _phaseDurationMs).clamp(0.0, 1.0);
    final curvedProgress = _phaseCurve.transform(progress);

    final prevOrange = isInOrangeStrikeWindow;
    _currentRadius = _startRadius + (_targetRadius - _startRadius) * curvedProgress;

    if (progress >= 1.0) {
      _applyPhase(_phaseIndex + 1);
    }

    return prevOrange != isInOrangeStrikeWindow;
  }

  /// Resolves a player tap.
  /// Returns a record with `success` and `accuracy` [0.0, 1.0].
  ({bool success, double accuracy}) registerTap() {
    if (_isFinished) return (success: false, accuracy: 0.0);
    _isFinished = true;

    if (isInOrangeStrikeWindow) {
      final dist = (_currentRadius - innerRingRadius).abs();
      final accuracy = (1.0 - (dist / strikeTolerance)).clamp(0.2, 1.0);
      return (success: true, accuracy: accuracy);
    } else {
      // Tap outside strike window = premature strike fail
      return (success: false, accuracy: 0.0);
    }
  }

  void stop() {
    _isFinished = true;
  }
}
