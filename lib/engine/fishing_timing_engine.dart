import 'dart:math';
import 'package:flutter/animation.dart';

/// Phase types for the Torchlight-style fishing mechanic
enum TimingPhaseType {
  teaseNibble,       // Smooth organic glide between waypoints — easeInOut
  deepTease,         // Dives fast then decelerates near hook — decelerate curve
  strikeContraction, // Fish commits: accelerates into inner ring — easeIn
  strikeWindow,      // Rings meet! Turns fiery ORANGE — player strikes now!
  retreat,           // Missed window: snaps away fast then drifts — easeOut
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
/// Organic Motion Mechanics:
/// - Fixed inner ring at 38px.
/// - Dynamic outer ring moves with organic easing curves per phase:
///   - Tease waypoints use easeInOut: decelerates into each point and accelerates
///     away, like a living creature cautiously circling.
///   - Deep tease uses decelerate: dives fast then slows near the inner ring,
///     maximizing the fake-out tension.
///   - Strike contraction uses easeIn: accelerates as it closes — the fish commits.
///   - Retreat uses easeOut: snaps away fast then drifts off.
/// - Duration of each phase is still calculated from constant-speed distance,
///   so the total cycle timing is predictable, but motion within each phase
///   is curved for organic feel.
/// - When a genuine strike occurs:
///   1. Accelerates down to 38px (easeIn — urgent surge).
///   2. Locks at 38px and turns fiery ORANGE for ~500ms.
///   3. Any tap while orange guarantees a catch (100% accuracy).
///   4. If missed, retreats with easeOut (fast snap, then drift back to max).
class FishingTimingEngine {
  final double difficultyMultiplier;
  final Random _rng;

  static const double innerRingRadius = 38.0;
  static const double maxOuterRadius = 135.0;

  /// Exposed for difficulty display — NOT used in tap resolution.
  /// Success is determined solely by being in [TimingPhaseType.strikeWindow].
  late final double strikeTolerance;

  List<RingPhase> _phases = [];
  int _phaseIndex = 0;
  double _currentRadius = maxOuterRadius;
  double _startRadius = maxOuterRadius;
  double _targetRadius = maxOuterRadius;
  // Initialized to -1 as a safe sentinel (epoch 0 is a valid timestamp).
  // Set to real millisecondsSinceEpoch in _applyPhase before first update.
  int _phaseStartTimeMs = -1;
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

  /// Generates a cycle of organic waypoint movements followed by a strike.
  ///
  /// Phase duration is calculated at ~82 px/sec constant speed so total
  /// timing stays predictable, but each phase uses a different [Curve] for
  /// natural organic feel.
  void generateCycle([int? nowMs]) {
    _phases = [];
    final diff = difficultyMultiplier.clamp(0.8, 1.5);
    // Base speed: ~82 px/sec. Used for duration calculation only.
    final speedPxPerMs = 0.082 * diff;

    // Waypoint anchors:
    // - Big:          ~125 – 135px
    // - Medium:       ~78 – 92px
    // - Small:        ~55px
    // - Near-orange:  ~42 – 44px  (inner is 38px — close but NOT orange)
    // - Strike:       38px
    final patternIndex = _rng.nextInt(5);
    double j() => _rng.nextDouble() * 8.0 - 4.0; // ±4px natural jitter

    List<double> waypoints;
    switch (patternIndex) {
      case 0:
        // Medium → Big → Near-orange tease → Medium → Strike
        waypoints = [
          85.0 + j(),
          (130.0 + j()).clamp(120.0, maxOuterRadius),
          42.0 + (_rng.nextDouble() * 2.5),
          85.0 + j(),
          innerRingRadius,
        ];
        break;
      case 1:
        // Small → Medium → Big → Near-orange → Medium → Strike
        waypoints = [
          55.0 + j(),
          88.0 + j(),
          (132.0 + j()).clamp(120.0, maxOuterRadius),
          43.0 + (_rng.nextDouble() * 2.0),
          80.0 + j(),
          innerRingRadius,
        ];
        break;
      case 2:
        // Medium → Near-orange tease → Big → Medium → Strike
        waypoints = [
          80.0 + j(),
          42.0 + (_rng.nextDouble() * 2.0),
          (128.0 + j()).clamp(120.0, maxOuterRadius),
          85.0 + j(),
          innerRingRadius,
        ];
        break;
      case 3:
        // Near-orange swift dive → Big → Medium → Strike
        waypoints = [
          42.0 + (_rng.nextDouble() * 2.5),
          (133.0 + j()).clamp(120.0, maxOuterRadius),
          85.0 + j(),
          innerRingRadius,
        ];
        break;
      case 4:
      default:
        // Medium → Big → Medium → Big → Near-orange → Medium → Strike
        waypoints = [
          88.0 + j(),
          (125.0 + j()).clamp(118.0, maxOuterRadius),
          78.0 + j(),
          (132.0 + j()).clamp(120.0, maxOuterRadius),
          42.0 + (_rng.nextDouble() * 2.5),
          82.0 + j(),
          innerRingRadius,
        ];
        break;
    }

    double current = _currentRadius;
    for (int i = 0; i < waypoints.length; i++) {
      final target = waypoints[i];
      final isLastStrike = (i == waypoints.length - 1);
      final dist = (target - current).abs();
      // Duration based on constant-speed distance; easing happens within that budget.
      final durationMs = (dist / speedPxPerMs).round().clamp(80, 3000);

      if (isLastStrike) {
        // ── Strike Contraction ──────────────────────────────────────────────
        // easeIn: starts slow, accelerates into the hook. Fish commits hard.
        _phases.add(RingPhase(
          targetRadius: target,
          durationMs: durationMs,
          curve: Curves.easeIn,
          type: TimingPhaseType.strikeContraction,
        ));

        // ── Strike Window ────────────────────────────────────────────────────
        // Ring locked at 38px. Fiery ORANGE for ~500ms. Linear (no movement).
        final windowMs =
            ((500 + _rng.nextInt(40)) / diff).round().clamp(400, 650);
        _phases.add(RingPhase(
          targetRadius: target,
          durationMs: windowMs,
          curve: Curves.linear,
          type: TimingPhaseType.strikeWindow,
        ));

        // ── Retreat ───────────────────────────────────────────────────────────
        // easeOut: snaps away fast, then drifts. The tension releases.
        final retreatDist = (maxOuterRadius - innerRingRadius).abs();
        final retreatDuration = (retreatDist / speedPxPerMs).round();
        _phases.add(RingPhase(
          targetRadius: maxOuterRadius,
          durationMs: retreatDuration,
          curve: Curves.easeOut,
          type: TimingPhaseType.retreat,
        ));
      } else {
        final isNearOrange = target <= 46.0;

        if (isNearOrange) {
          // ── Deep Tease ─────────────────────────────────────────────────────
          // decelerate: dives in fast then creeps to a stop just outside orange.
          // Maximum fake-out effect — player thinks it's a strike, then... nothing.
          _phases.add(RingPhase(
            targetRadius: target,
            durationMs: durationMs,
            curve: Curves.decelerate,
            type: TimingPhaseType.deepTease,
          ));
        } else {
          // ── Tease Nibble ───────────────────────────────────────────────────
          // easeInOut: decelerates into the waypoint and accelerates out.
          // Feels like a living creature tugging the line — smooth and organic.
          _phases.add(RingPhase(
            targetRadius: target,
            durationMs: durationMs,
            curve: Curves.easeInOut,
            type: TimingPhaseType.teaseNibble,
          ));
        }
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

    // Guard: should never fire after constructor sets it via _applyPhase,
    // but defensively handle the case to avoid a division-by-zero or negative elapsed.
    if (_phaseStartTimeMs < 0) {
      _phaseStartTimeMs = nowMs;
    }

    final elapsed = nowMs - _phaseStartTimeMs;
    final progress = (elapsed / _phaseDurationMs).clamp(0.0, 1.0);
    final curvedProgress = _phaseCurve.transform(progress);

    final prevOrange = isInOrangeStrikeWindow;
    _currentRadius =
        _startRadius + (_targetRadius - _startRadius) * curvedProgress;

    if (progress >= 1.0) {
      _currentRadius = _targetRadius; // Snap to exact target — no float drift
      _applyPhase(_phaseIndex + 1, nowMs);
    }

    return prevOrange != isInOrangeStrikeWindow;
  }

  /// Resolves a player tap.
  /// Returns a record with `success` and graded `accuracy` [0.65 – 1.0] based
  /// on timing precision within the orange bite window.
  ({bool success, double accuracy}) registerTap([int? tapTimeMs]) {
    if (_isFinished) return (success: false, accuracy: 0.0);

    final wasOrange = isInOrangeStrikeWindow;
    _isFinished = true;

    if (wasOrange) {
      final now = tapTimeMs ?? DateTime.now().millisecondsSinceEpoch;
      final elapsedInStrike =
          (now - _phaseStartTimeMs).clamp(0, _phaseDurationMs);
      final progress =
          _phaseDurationMs > 0 ? elapsedInStrike / _phaseDurationMs : 0.5;

      // Peak accuracy (1.0) is centered in the bite window.
      // Tapping near either edge grants ~0.65 – 0.70 accuracy.
      final distanceFromCenter = (progress - 0.5).abs() * 2.0;
      final calculatedAccuracy =
          (1.0 - (distanceFromCenter * 0.35)).clamp(0.65, 1.0);

      return (success: true, accuracy: calculatedAccuracy);
    } else {
      // Tap outside strike window = premature strike fail
      return (success: false, accuracy: 0.0);
    }
  }

  void stop() {
    _isFinished = true;
  }
}
