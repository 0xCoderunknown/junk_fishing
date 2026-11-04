import 'dart:math';
import 'package:flutter/animation.dart';

/// Phase types for the Torchlight-style fishing mechanic
enum TimingPhaseType {
  teaseNibble,
  deepTease,
  strikeWindow,
  retreat,
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
/// - Smooth, steady pacing: A full fishing cycle unfolds over ~3.5 to 5.0 seconds.
/// - Tease contractions move steadily (800ms - 1400ms) rather than erratic jitter.
/// - Deep teases shrink toward the inner ring smoothly without snapping.
/// - When the fish bites, the outer ring contracts smoothly into the center and turns ORANGE.
/// - Generous strike linger window (650ms - 850ms) gives the player comfortable reaction time.
/// - If missed, the ring smoothly floats back out and repeats seamlessly without game over.
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
    strikeTolerance = (14.0 / difficultyMultiplier).clamp(9.0, 20.0);
    generateCycle();
  }

  double get currentRadius => _currentRadius;
  bool get isFinished => _isFinished;
  RingPhase? get currentPhase =>
      _phaseIndex < _phases.length ? _phases[_phaseIndex] : null;

  /// Whether the outer ring is currently in the active strike window
  bool get isInOrangeStrikeWindow {
    if (_isFinished || currentPhase == null) return false;
    if (!currentPhase!.isOrangeStrike) return false;
    final dist = (_currentRadius - innerRingRadius).abs();
    return dist <= strikeTolerance;
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
        // Deep tease: smoothly glides near the inner ring (48-56px), but doesn't strike or turn orange!
        shrinkTo = innerRingRadius + strikeTolerance + 4.0 + _rng.nextDouble() * 12.0;
        pType = TimingPhaseType.deepTease;
      } else if (teaseKind == 1) {
        // Moderate nibble
        shrinkTo = 65.0 + _rng.nextDouble() * 25.0;
        pType = TimingPhaseType.teaseNibble;
      } else {
        // Shallow ripple
        shrinkTo = 90.0 + _rng.nextDouble() * 25.0;
        pType = TimingPhaseType.teaseNibble;
      }

      // Smooth, deliberate travel speed: ~900ms - 1500ms
      final shrinkDuration = (1000 + _rng.nextInt(500)) ~/ diff;
      _phases.add(RingPhase(
        targetRadius: shrinkTo,
        durationMs: shrinkDuration.clamp(750, 1600),
        curve: Curves.easeInOutSine,
        type: pType,
      ));

      // Gentle pause/float back out: ~800ms - 1300ms
      final expandTo = min(maxOuterRadius, shrinkTo + 30.0 + _rng.nextDouble() * 45.0);
      final expandDuration = (900 + _rng.nextInt(400)) ~/ diff;
      _phases.add(RingPhase(
        targetRadius: expandTo,
        durationMs: expandDuration.clamp(700, 1400),
        curve: Curves.easeInOutSine,
        type: TimingPhaseType.teaseNibble,
      ));
    }

    // THE REAL STRIKE: Outer ring contracts steadily and deliberately right down to the inner ring
    final strikeDuration = (1100 + _rng.nextInt(300)) ~/ diff;
    _phases.add(RingPhase(
      targetRadius: innerRingRadius,
      durationMs: strikeDuration.clamp(800, 1500),
      curve: Curves.easeInOutQuad,
      type: TimingPhaseType.strikeWindow,
    ));

    // The strike linger window (ORANGE GLOW):
    // Comfortable human reaction time (~650ms to 850ms)
    final windowMs = (750 / diff).clamp(550, 950).toInt();
    _phases.add(RingPhase(
      targetRadius: innerRingRadius,
      durationMs: windowMs,
      curve: Curves.linear,
      type: TimingPhaseType.strikeWindow,
    ));

    // Smooth retreat without penalty if player missed the window
    final retreatRadius = maxOuterRadius - (_rng.nextDouble() * 15.0);
    _phases.add(RingPhase(
      targetRadius: retreatRadius,
      durationMs: (1000 + _rng.nextInt(300)) ~/ diff,
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
      final accuracy = (1.0 - (dist / strikeTolerance)).clamp(0.0, 1.0);
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
