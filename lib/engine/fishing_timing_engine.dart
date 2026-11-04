import 'dart:math';
import 'package:flutter/animation.dart';

/// Phase types for the Torchlight-style fishing mechanic
enum TimingPhaseType {
  teaseNibble,       // Fast twitch, quiver, or subtle ripple
  deepTease,         // Aggressive fake-out that surges near the hook then retreats
  strikeContraction, // Decisive rush toward center ring
  strikeWindow,      // Rings meet! Turns fiery ORANGE - player strikes now!
  retreat,           // Player missed window - ring smoothly opens back up
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
/// Unpredictable Torchlight-Style Fishing Dynamics:
/// - A central hook sits inside a fixed inner ring (radius: 38px).
/// - Dynamic outer ring moves unpredictably with varied speeds, deceptive fake-outs,
///   micro-nibbles, creeping crawls, and variable pauses.
/// - When a strike occurs:
///   1. `strikeContraction`: The ring closes in rapidly toward the inner ring.
///   2. `strikeWindow`: The ring contacts the inner circle and turns fiery ORANGE!
///      The orange window lasts ~500ms (halved for a snappy, authentic bite reaction).
///      Any tap while orange guarantees a successful catch (100% accuracy).
///   3. If missed, ring retreats outward smoothly and generates a new unpredictable cycle.
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
    strikeTolerance = (22.0 / difficultyMultiplier).clamp(16.0, 30.0);
    generateCycle();
  }

  double get currentRadius => _currentRadius;
  bool get isFinished => _isFinished;
  RingPhase? get currentPhase =>
      _phaseIndex < _phases.length ? _phases[_phaseIndex] : null;

  /// True when ring is in the fiery orange bite window.
  bool get isInOrangeStrikeWindow {
    if (_isFinished || currentPhase == null) return false;
    return currentPhase!.isOrangeStrike;
  }

  /// Generates an unpredictable, non-rhythmic sequence of behaviors followed by a bite.
  void generateCycle([int? nowMs]) {
    _phases = [];
    final diff = difficultyMultiplier.clamp(0.5, 2.5);

    // Unpredictable teaser count: 2 to 4 erratic actions
    final teaserCount = 2 + _rng.nextInt(3);

    for (int i = 0; i < teaserCount; i++) {
      // Random action:
      // 0: Fast micro-twitch / nervous nibble
      // 1: High-tension fake-out (surges close, stalls, retreats)
      // 2: Hesitant creep (slow, tense contraction)
      // 3: Wandering drift (floats outward)
      final action = _rng.nextInt(4);

      if (action == 0) {
        // Fast nervous micro-twitch
        final twitchIn = (_currentRadius - (15.0 + _rng.nextDouble() * 20.0))
            .clamp(innerRingRadius + 20.0, maxOuterRadius);
        _phases.add(RingPhase(
          targetRadius: twitchIn,
          durationMs: (180 + _rng.nextInt(120)),
          curve: Curves.easeOutQuad,
          type: TimingPhaseType.teaseNibble,
        ));
        // Momentary jitter hesitation
        _phases.add(RingPhase(
          targetRadius: twitchIn,
          durationMs: (100 + _rng.nextInt(150)),
          curve: Curves.linear,
          type: TimingPhaseType.teaseNibble,
        ));
      } else if (action == 1) {
        // High-tension fake-out: plunges near inner ring, freezes, then bolts back out!
        final fakeTarget = innerRingRadius + 8.0 + _rng.nextDouble() * 14.0; // 46-60px
        final surgeDuration = ((380 + _rng.nextInt(220)) / diff).round();
        _phases.add(RingPhase(
          targetRadius: fakeTarget,
          durationMs: surgeDuration.clamp(320, 700),
          curve: Curves.fastOutSlowIn,
          type: TimingPhaseType.deepTease,
        ));
        // Teasing freeze right next to the ring (makes player tense)
        _phases.add(RingPhase(
          targetRadius: fakeTarget,
          durationMs: 220 + _rng.nextInt(200),
          curve: Curves.linear,
          type: TimingPhaseType.deepTease,
        ));
        // Abrupt escape back outwards
        final reboundRadius =
            min(maxOuterRadius, fakeTarget + 45.0 + _rng.nextDouble() * 40.0);
        final reboundDuration = ((450 + _rng.nextInt(250)) / diff).round();
        _phases.add(RingPhase(
          targetRadius: reboundRadius,
          durationMs: reboundDuration.clamp(420, 800),
          curve: Curves.easeOutCubic,
          type: TimingPhaseType.teaseNibble,
        ));
      } else if (action == 2) {
        // Hesitant creep: slow, cautious contraction
        final creepTarget = innerRingRadius + 25.0 + _rng.nextDouble() * 30.0;
        final creepDuration = ((1200 + _rng.nextInt(500)) / diff).round();
        _phases.add(RingPhase(
          targetRadius: creepTarget,
          durationMs: creepDuration.clamp(900, 1800),
          curve: Curves.easeInOutCubic,
          type: TimingPhaseType.teaseNibble,
        ));
      } else {
        // Wandering drift: floating outward
        final driftRadius =
            min(maxOuterRadius, innerRingRadius + 45.0 + _rng.nextDouble() * 50.0);
        final driftDuration = ((800 + _rng.nextInt(350)) / diff).round();
        _phases.add(RingPhase(
          targetRadius: driftRadius,
          durationMs: driftDuration.clamp(700, 1300),
          curve: Curves.easeInOutSine,
          type: TimingPhaseType.teaseNibble,
        ));
      }
    }

    // STRIKE CONTRACTION: Ring closes down swiftly to inner ring (38px)
    final strikeDuration = ((550 + _rng.nextInt(250)) / diff).round();
    _phases.add(RingPhase(
      targetRadius: innerRingRadius,
      durationMs: strikeDuration.clamp(450, 900),
      curve: Curves.easeInOutQuad,
      type: TimingPhaseType.strikeContraction,
    ));

    // STRIKE WINDOW: Hits inner ring and turns fiery ORANGE!
    // Halved from ~1100ms down to ~500ms (500ms - 550ms)
    final windowMs = ((500 + _rng.nextInt(50)) / diff).round().clamp(400, 650);
    _phases.add(RingPhase(
      targetRadius: innerRingRadius,
      durationMs: windowMs,
      curve: Curves.linear,
      type: TimingPhaseType.strikeWindow,
    ));

    // RETREAT: Player missed the bite, fish releases hook and swims back out
    final retreatRadius = maxOuterRadius - (_rng.nextDouble() * 15.0);
    final retreatDuration = ((700 + _rng.nextInt(250)) / diff).round();
    _phases.add(RingPhase(
      targetRadius: retreatRadius,
      durationMs: retreatDuration.clamp(600, 1000),
      curve: Curves.easeOutQuad,
      type: TimingPhaseType.retreat,
    ));

    _applyPhase(0, nowMs);
  }

  void _applyPhase(int index, [int? nowMs]) {
    if (index >= _phases.length) {
      generateCycle(nowMs);
      return;
    }

    _phaseIndex = index;
    final phase = _phases[index];
    _startRadius = _currentRadius;
    _targetRadius = phase.targetRadius;
    _phaseDurationMs = phase.durationMs;
    _phaseCurve = phase.curve;
    _phaseStartTimeMs = nowMs ?? DateTime.now().millisecondsSinceEpoch;
  }

  /// Updates radius based on elapsed frame time. Returns whether orange state changed.
  bool update(int nowMs) {
    if (_isFinished) return false;
    if (_phaseStartTimeMs == 0) {
      _phaseStartTimeMs = nowMs;
    }

    final elapsed = nowMs - _phaseStartTimeMs;
    final progress = (elapsed / _phaseDurationMs).clamp(0.0, 1.0);
    final curvedProgress = _phaseCurve.transform(progress);

    final prevOrange = isInOrangeStrikeWindow;
    _currentRadius =
        _startRadius + (_targetRadius - _startRadius) * curvedProgress;

    if (progress >= 1.0) {
      _applyPhase(_phaseIndex + 1, nowMs);
    }

    return prevOrange != isInOrangeStrikeWindow;
  }

  /// Resolves a player tap.
  /// Returns a record with `success` and `accuracy` [0.0, 1.0].
  ({bool success, double accuracy}) registerTap() {
    if (_isFinished) return (success: false, accuracy: 0.0);

    final wasOrange = isInOrangeStrikeWindow;
    _isFinished = true;

    if (wasOrange) {
      return (success: true, accuracy: 1.0);
    } else {
      // Tap outside strike window = premature strike fail
      return (success: false, accuracy: 0.0);
    }
  }

  void stop() {
    _isFinished = true;
  }
}
