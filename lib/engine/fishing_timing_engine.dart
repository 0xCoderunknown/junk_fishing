import 'dart:math';
import 'package:flutter/animation.dart';

/// Phase types for the Torchlight-style fishing mechanic
enum TimingPhaseType {
  teaseNibble,       // Smooth glide between medium and big/small
  deepTease,         // Deep mind-game contraction almost touching orange (42px) without triggering orange
  strikeContraction, // Smooth continuous contraction down to inner circle (38px)
  strikeWindow,      // Rings meet! Turns fiery ORANGE - player strikes now!
  retreat,           // Player missed window - ring smoothly opens back up at constant speed
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
/// Smooth Constant-Speed Mind Games Mechanics:
/// - Fixed inner ring at 38px.
/// - Dynamic outer ring moves at a completely uniform, constant speed:
///   - Expands and contracts at the EXACT same velocity.
///   - No erratic speedups, slowdowns, lag, or pauses.
///   - Goes from small to medium, big, medium, and can dive close to the inner ring (42px)
///     playing mind games with the player, then smoothly expands back out without turning orange.
/// - When a genuine strike occurs:
///   1. Smoothly closes down to 38px at the same speed.
///   2. Locks at 38px and turns fiery ORANGE for ~500ms.
///   3. Any tap while orange guarantees a catch (100% accuracy).
///   4. If missed, smoothly retreats back to max outer radius at the same speed and generates a new cycle.
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
  Curve _phaseCurve = Curves.linear;

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

  /// Generates a smooth, constant-speed sequence of mind-game movements followed by a strike.
  void generateCycle([int? nowMs]) {
    _phases = [];
    final diff = difficultyMultiplier.clamp(0.8, 1.5);
    // Constant speed in pixels per millisecond (~82 px/sec)
    final speedPxPerMs = 0.082 * diff;

    // Mind-game waypoint paths:
    // Anchors:
    // - Big: 128.0 - 135.0
    // - Medium: 78.0 - 92.0
    // - Small: 55.0
    // - Small almost orange: 42.0 (inner ring is 38.0, gets within 4px but NO orange!)
    // - Strike: innerRingRadius (38.0)
    final patternIndex = _rng.nextInt(5);
    List<double> waypoints;
    switch (patternIndex) {
      case 0:
        // Big -> Medium -> Big -> Small Almost Orange (tease!) -> Medium -> Strike!
        waypoints = [85.0, 130.0, 42.0, 85.0, innerRingRadius];
        break;
      case 1:
        // Big -> Small -> Medium -> Big -> Small Almost Orange -> Medium -> Strike!
        waypoints = [55.0, 92.0, 132.0, 43.0, 80.0, innerRingRadius];
        break;
      case 2:
        // Big -> Medium -> Small Almost Orange -> Big -> Medium -> Strike!
        waypoints = [80.0, 42.0, 128.0, 85.0, innerRingRadius];
        break;
      case 3:
        // Big -> Small Almost Orange (swift deep dive!) -> Big -> Medium -> Strike!
        waypoints = [42.0, 135.0, 85.0, innerRingRadius];
        break;
      case 4:
      default:
        // Big -> Medium -> Big -> Medium -> Small Almost Orange -> Medium -> Strike!
        waypoints = [88.0, 125.0, 78.0, 132.0, 42.0, 82.0, innerRingRadius];
        break;
    }

    double current = _currentRadius;
    for (int i = 0; i < waypoints.length; i++) {
      final target = waypoints[i];
      final isLastStrike = (i == waypoints.length - 1);
      final dist = (target - current).abs();
      // Constant linear duration strictly proportional to distance traveled
      final durationMs = (dist / speedPxPerMs).round().clamp(80, 3000);

      if (isLastStrike) {
        // Strike Contraction: Moving smoothly to 38px at the exact same constant speed
        _phases.add(RingPhase(
          targetRadius: target,
          durationMs: durationMs,
          curve: Curves.linear,
          type: TimingPhaseType.strikeContraction,
        ));

        // Strike Window: Ring locked on inner circle, turns fiery ORANGE for ~500ms
        final windowMs =
            ((500 + _rng.nextInt(40)) / diff).round().clamp(400, 650);
        _phases.add(RingPhase(
          targetRadius: target,
          durationMs: windowMs,
          curve: Curves.linear,
          type: TimingPhaseType.strikeWindow,
        ));

        // Retreat: If missed, ring smoothly expands back to maxOuterRadius at the same speed
        final retreatDist = (maxOuterRadius - innerRingRadius).abs();
        final retreatDuration = (retreatDist / speedPxPerMs).round();
        _phases.add(RingPhase(
          targetRadius: maxOuterRadius,
          durationMs: retreatDuration,
          curve: Curves.linear,
          type: TimingPhaseType.retreat,
        ));
      } else {
        // Teaser motion: smooth constant velocity, NO pauses, NO lag
        final isNearOrange = target <= 46.0;
        _phases.add(RingPhase(
          targetRadius: target,
          durationMs: durationMs,
          curve: Curves.linear,
          type: isNearOrange
              ? TimingPhaseType.deepTease
              : TimingPhaseType.teaseNibble,
        ));
      }
      current = target;
    }

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
