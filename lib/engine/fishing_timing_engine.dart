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
/// Handles all Torchlight-style timing behavior:
/// - Organic pseudorandom contractions and expansions
/// - Deep teases that pull close to the inner ring without turning orange
/// - Decisive orange strike windows with configurable tolerance
/// - Automatic cycle recycling when a strike is missed (no premature game over)
/// - Deterministic accuracy scoring
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
  int _phaseDurationMs = 1000;
  Curve _phaseCurve = Curves.easeInOut;

  bool _isFinished = false;

  FishingTimingEngine({
    this.difficultyMultiplier = 1.0,
    Random? rng,
  }) : _rng = rng ?? Random() {
    strikeTolerance = (12.0 / difficultyMultiplier).clamp(7.0, 18.0);
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

  /// Generates a randomized movement cycle
  void generateCycle() {
    _phases = [];
    final diff = difficultyMultiplier;
    final teaseCount = 1 + _rng.nextInt(4);

    for (int i = 0; i < teaseCount; i++) {
      final teaseKind = _rng.nextInt(3);
      double shrinkTo;
      TimingPhaseType pType;

      if (teaseKind == 0) {
        // Deep tease: gets close to inner ring without turning orange
        shrinkTo = innerRingRadius + strikeTolerance + 3.0 + _rng.nextDouble() * 10.0;
        pType = TimingPhaseType.deepTease;
      } else if (teaseKind == 1) {
        // Medium nibble
        shrinkTo = 60.0 + _rng.nextDouble() * 25.0;
        pType = TimingPhaseType.teaseNibble;
      } else {
        // Shallow ripple
        shrinkTo = 85.0 + _rng.nextDouble() * 30.0;
        pType = TimingPhaseType.teaseNibble;
      }

      final shrinkSpeed = (350 + _rng.nextInt(450)) ~/ diff;
      _phases.add(RingPhase(
        targetRadius: shrinkTo,
        durationMs: shrinkSpeed.clamp(280, 1000),
        curve: _rng.nextBool() ? Curves.easeOutQuad : Curves.easeInOutCubic,
        type: pType,
      ));

      // Expand back out (full or halfway)
      final expandTo = min(maxOuterRadius, shrinkTo + 20.0 + _rng.nextDouble() * 60.0);
      final expandSpeed = (300 + _rng.nextInt(400)) ~/ diff;
      _phases.add(RingPhase(
        targetRadius: expandTo,
        durationMs: expandSpeed.clamp(250, 850),
        curve: Curves.easeInOutCubic,
        type: TimingPhaseType.teaseNibble,
      ));
    }

    // Rapid strike contraction toward inner ring
    final strikeDuration = (550 + _rng.nextInt(300)) ~/ diff;
    _phases.add(RingPhase(
      targetRadius: innerRingRadius,
      durationMs: strikeDuration.clamp(380, 850),
      curve: Curves.easeInQuad,
      type: TimingPhaseType.strikeWindow,
    ));

    // Orange strike linger window
    final windowMs = (420 / diff).clamp(260, 580).toInt();
    _phases.add(RingPhase(
      targetRadius: innerRingRadius,
      durationMs: windowMs,
      curve: Curves.linear,
      type: TimingPhaseType.strikeWindow,
    ));

    // Seamless retreat without failing
    final retreatRadius = maxOuterRadius - (_rng.nextDouble() * 20.0);
    _phases.add(RingPhase(
      targetRadius: retreatRadius,
      durationMs: (450 + _rng.nextInt(250)) ~/ diff,
      curve: Curves.easeOutCubic,
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

