import 'dart:math';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

typedef RippleResolveCallback = void Function(bool success, double accuracy);

/// Single self-contained Torchlight-style fishing timing overlay.
///
/// Built on a single AnimationController with explicit state checking:
/// - Fixed inner ring (radius: 38px) with hook and bait.
/// - Dynamic outer ring shrinks and expands with organic variations.
/// - When in strike window:
///   - Ring contacts inner circle and turns fiery ORANGE.
///   - Haptic feedback fires.
///   - Any tap while [isStrikeWindow] is true GUARANTEES a successful catch.
///   - If missed, the ring smoothly opens back up and restarts a new tease pattern.
class RippleTimingOverlay extends StatefulWidget {
  final RippleResolveCallback onResolve;
  final double difficultyMultiplier;

  const RippleTimingOverlay({
    super.key,
    required this.onResolve,
    this.difficultyMultiplier = 1.0,
  });

  @override
  State<RippleTimingOverlay> createState() => _RippleTimingOverlayState();
}

class _RippleTimingOverlayState extends State<RippleTimingOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animController;
  final Random _rng = Random();

  static const double innerRingRadius = 38.0;
  static const double maxOuterRadius = 135.0;

  double _currentRadius = maxOuterRadius;
  double _startRadius = maxOuterRadius;
  double _targetRadius = maxOuterRadius;

  int _phaseStartTimeMs = 0;
  int _phaseDurationMs = 1000;
  Curve _phaseCurve = Curves.easeInOutSine;

  bool _isStrikeWindow = false;
  bool _resolved = false;
  bool _hapticFired = false;

  late List<_PhaseData> _phases;
  int _phaseIndex = 0;

  @override
  void initState() {
    super.initState();
    _generatePattern();

    _animController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..addListener(_onTick);

    _animController.repeat();
  }

  void _generatePattern() {
    _phases = [];
    final diff = widget.difficultyMultiplier;

    // 1 to 2 tease nibbles
    final teaseCount = 1 + _rng.nextInt(2);

    for (int i = 0; i < teaseCount; i++) {
      final isDeepTease = _rng.nextBool();
      // Deep tease gets to 65-75px, shallow tease to 85-95px
      final shrinkTo = isDeepTease
          ? 65.0 + _rng.nextDouble() * 12.0
          : 85.0 + _rng.nextDouble() * 20.0;

      final shrinkMs = (1100 + _rng.nextInt(400)) ~/ diff;
      _phases.add(_PhaseData(
        targetRadius: shrinkTo,
        durationMs: shrinkMs.clamp(900, 1500),
        curve: Curves.easeInOutSine,
        isStrike: false,
      ));

      final expandTo = min(maxOuterRadius, shrinkTo + 35.0 + _rng.nextDouble() * 35.0);
      final expandMs = (1000 + _rng.nextInt(350)) ~/ diff;
      _phases.add(_PhaseData(
        targetRadius: expandTo,
        durationMs: expandMs.clamp(800, 1400),
        curve: Curves.easeInOutSine,
        isStrike: false,
      ));
    }

    // STRIKE CONTRACTION: Moves down to meet inner ring (38px)
    final strikeDuration = (1200 + _rng.nextInt(250)) ~/ diff;
    _phases.add(_PhaseData(
      targetRadius: innerRingRadius,
      durationMs: strikeDuration.clamp(950, 1500),
      curve: Curves.easeInOutQuad,
      isStrike: false,
    ));

    // STRIKE WINDOW: Locked on inner ring, turns fiery ORANGE!
    // Generous 1100ms window for relaxed reaction
    final windowMs = (1100 / diff).clamp(850, 1400).toInt();
    _phases.add(_PhaseData(
      targetRadius: innerRingRadius,
      durationMs: windowMs,
      curve: Curves.linear,
      isStrike: true,
    ));

    // RETREAT: If missed, ring floats back out smoothly
    final retreatRadius = maxOuterRadius - (_rng.nextDouble() * 15.0);
    _phases.add(_PhaseData(
      targetRadius: retreatRadius,
      durationMs: 1100,
      curve: Curves.easeOutSine,
      isStrike: false,
    ));

    _applyPhase(0);
  }

  void _applyPhase(int index) {
    if (index >= _phases.length) {
      _generatePattern();
      return;
    }

    _phaseIndex = index;
    final phase = _phases[index];
    _startRadius = _currentRadius;
    _targetRadius = phase.targetRadius;
    _phaseDurationMs = phase.durationMs;
    _phaseCurve = phase.curve;
    _isStrikeWindow = phase.isStrike;
    _phaseStartTimeMs = DateTime.now().millisecondsSinceEpoch;
  }

  void _onTick() {
    if (_resolved) return;

    final now = DateTime.now().millisecondsSinceEpoch;
    final elapsed = now - _phaseStartTimeMs;
    final progress = (elapsed / _phaseDurationMs).clamp(0.0, 1.0);
    final curvedProgress = _phaseCurve.transform(progress);

    setState(() {
      _currentRadius = _startRadius + (_targetRadius - _startRadius) * curvedProgress;
    });

    if (_isStrikeWindow && !_hapticFired) {
      _hapticFired = true;
      HapticFeedback.selectionClick();
    } else if (!_isStrikeWindow) {
      _hapticFired = false;
    }

    if (progress >= 1.0) {
      _applyPhase(_phaseIndex + 1);
    }
  }

  void _handleTap() {
    if (_resolved) return;
    _resolved = true;
    _animController.stop();

    if (_isStrikeWindow) {
      // GUARANTEED CATCH: Tapped during the orange strike window!
      widget.onResolve(true, 1.0);
    } else {
      // Clicked too early while ring is still wandering/cyan
      widget.onResolve(false, 0.0);
    }
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: _handleTap,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // 1. Atmospheric blur overlay
          BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 9, sigmaY: 9),
            child: Container(
              color: Colors.black.withValues(alpha: 0.60),
            ),
          ),

          // 2. Centered Timing Visuals
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Top Status Badge
                AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  decoration: BoxDecoration(
                    color: _isStrikeWindow
                        ? const Color(0xFFFF9E00).withValues(alpha: 0.3)
                        : Colors.black54,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: _isStrikeWindow ? const Color(0xFFFF9E00) : Colors.white24,
                      width: _isStrikeWindow ? 2.5 : 1.5,
                    ),
                    boxShadow: [
                      if (_isStrikeWindow)
                        BoxShadow(
                          color: const Color(0xFFFF9E00).withValues(alpha: 0.6),
                          blurRadius: 18,
                          spreadRadius: 2,
                        ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        _isStrikeWindow ? Icons.flash_on : Icons.remove_red_eye_outlined,
                        color: _isStrikeWindow ? const Color(0xFFFFD166) : Colors.white70,
                        size: 16,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _isStrikeWindow ? 'BITE! HOOK NOW!' : 'WATCH THE WATER...',
                        style: TextStyle(
                          color: _isStrikeWindow ? const Color(0xFFFFD166) : Colors.white70,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.5,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 36),

                // Canvas showing the hook & outer ring
                SizedBox(
                  width: 300,
                  height: 300,
                  child: CustomPaint(
                    painter: _TorchlightRingPainter(
                      currentOuterRadius: _currentRadius,
                      innerRadius: innerRingRadius,
                      isInStrikeZone: _isStrikeWindow,
                    ),
                  ),
                ),

                const SizedBox(height: 36),

                // Action Prompt
                AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  padding: const EdgeInsets.symmetric(horizontal: 36, vertical: 15),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: _isStrikeWindow
                          ? [const Color(0xFFFF9E00), const Color(0xFFFF5400)]
                          : [const Color(0xFF2B2D42), const Color(0xFF1E1E24)],
                    ),
                    borderRadius: BorderRadius.circular(32),
                    boxShadow: [
                      if (_isStrikeWindow)
                        BoxShadow(
                          color: const Color(0xFFFF5400).withValues(alpha: 0.65),
                          blurRadius: 22,
                          spreadRadius: 3,
                        ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.touch_app,
                        color: _isStrikeWindow ? Colors.white : Colors.white54,
                        size: 24,
                      ),
                      const SizedBox(width: 10),
                      Text(
                        _isStrikeWindow ? 'CLICK ANYWHERE!' : 'WAIT FOR ORANGE...',
                        style: TextStyle(
                          color: _isStrikeWindow ? Colors.white : Colors.white60,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 2,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  'Wait for circle to turn orange — if missed, it will try again!',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.55),
                    fontSize: 12,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PhaseData {
  final double targetRadius;
  final int durationMs;
  final Curve curve;
  final bool isStrike;

  _PhaseData({
    required this.targetRadius,
    required this.durationMs,
    required this.curve,
    required this.isStrike,
  });
}

class _TorchlightRingPainter extends CustomPainter {
  final double currentOuterRadius;
  final double innerRadius;
  final bool isInStrikeZone;

  _TorchlightRingPainter({
    required this.currentOuterRadius,
    required this.innerRadius,
    required this.isInStrikeZone,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);

    // 1. Water ripple background
    final ambientWaterPaint = Paint()
      ..color = const Color(0xFF0077B6).withValues(alpha: 0.12)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, 120, ambientWaterPaint);

    // 2. Inner Ring & Center Bait Target
    final innerBgPaint = Paint()
      ..color = isInStrikeZone
          ? const Color(0xFFFF9E00).withValues(alpha: 0.35)
          : const Color(0xFF0F4C81).withValues(alpha: 0.40)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, innerRadius, innerBgPaint);

    final innerBorderPaint = Paint()
      ..color = isInStrikeZone ? const Color(0xFFFF9E00) : const Color(0xFF00E5FF)
      ..style = PaintingStyle.stroke
      ..strokeWidth = isInStrikeZone ? 3.8 : 2.0;
    canvas.drawCircle(center, innerRadius, innerBorderPaint);

    final innerGlowPaint = Paint()
      ..color = (isInStrikeZone ? const Color(0xFFFF9E00) : const Color(0xFF00E5FF))
          .withValues(alpha: isInStrikeZone ? 0.65 : 0.2)
      ..style = PaintingStyle.stroke
      ..strokeWidth = isInStrikeZone ? 12.0 : 4.0;
    canvas.drawCircle(center, innerRadius, innerGlowPaint);

    // Central Bait / Hook Icon
    _drawBaitHook(canvas, center, isInStrikeZone);

    // 3. Dynamic Outer Ring: ORANGE when in strike, CYAN when teasing
    final outerRingColor =
        isInStrikeZone ? const Color(0xFFFF5400) : const Color(0xFF90E0EF);

    final outerRingPaint = Paint()
      ..color = outerRingColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = isInStrikeZone ? 5.2 : 3.0;
    canvas.drawCircle(center, currentOuterRadius, outerRingPaint);

    final outerGlowPaint = Paint()
      ..color = outerRingColor.withValues(alpha: isInStrikeZone ? 0.75 : 0.35)
      ..style = PaintingStyle.stroke
      ..strokeWidth = isInStrikeZone ? 15.0 : 7.0;
    canvas.drawCircle(center, currentOuterRadius, outerGlowPaint);

    // Orbiting sparkle beads
    final beadPaint = Paint()
      ..color = outerRingColor
      ..style = PaintingStyle.fill;
    for (int i = 0; i < 4; i++) {
      final angle = (i * pi / 2) + (currentOuterRadius * 0.05);
      final bx = center.dx + cos(angle) * currentOuterRadius;
      final by = center.dy + sin(angle) * currentOuterRadius;
      canvas.drawCircle(Offset(bx, by), isInStrikeZone ? 4.5 : 2.5, beadPaint);
    }
  }

  void _drawBaitHook(Canvas canvas, Offset center, bool isStrike) {
    final hookPaint = Paint()
      ..color = isStrike ? Colors.white : const Color(0xFFE0E1DD)
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 3.0;

    // Shank
    canvas.drawLine(
      Offset(center.dx, center.dy - 14),
      Offset(center.dx, center.dy + 4),
      hookPaint,
    );

    // Eyelet
    canvas.drawCircle(
      Offset(center.dx, center.dy - 14),
      3.0,
      Paint()
        ..color = isStrike ? const Color(0xFFFFD166) : const Color(0xFF00E5FF)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0,
    );

    // Curved barb
    final arcRect = Rect.fromCircle(center: Offset(center.dx - 6, center.dy + 4), radius: 6);
    canvas.drawArc(arcRect, 0, pi, false, hookPaint);

    // Upward barb point
    canvas.drawLine(
      Offset(center.dx - 12, center.dy + 4),
      Offset(center.dx - 12, center.dy - 1),
      hookPaint,
    );

    // Bait worm / tidbit
    final baitPaint = Paint()
      ..color = isStrike ? const Color(0xFFFF3366) : const Color(0xFFFF9E00)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(center.dx - 6, center.dy + 10), 3.5, baitPaint);
  }

  @override
  bool shouldRepaint(covariant _TorchlightRingPainter oldDelegate) {
    return oldDelegate.currentOuterRadius != currentOuterRadius ||
        oldDelegate.isInStrikeZone != isInStrikeZone;
  }
}
