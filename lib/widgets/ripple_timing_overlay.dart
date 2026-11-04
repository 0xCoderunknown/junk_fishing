import 'dart:math';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../engine/fishing_timing_engine.dart';

typedef RippleResolveCallback = void Function(bool success, double accuracy);

/// Single self-contained Torchlight-style fishing timing overlay.
///
/// Driven directly by [FishingTimingEngine]:
/// - Fixed inner ring (radius: 38px) with hook and bait.
/// - Dynamic outer ring moves with organic easing curves (easeInOut / decelerate /
///   easeIn / easeOut) depending on phase type for a living, creature-like feel.
/// - When in strike window:
///   - Ring contacts inner circle and turns fiery ORANGE for ~500ms.
///   - Haptic feedback fires on the exact transition frame.
///   - Any tap while orange GUARANTEES a successful catch.
///   - If missed, ring snaps away fast then drifts (easeOut retreat).
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
  late final FishingTimingEngine _engine;

  static const double _innerRingRadius = FishingTimingEngine.innerRingRadius;

  double _currentRadius = FishingTimingEngine.maxOuterRadius;
  bool _isStrikeWindow = false;
  bool _resolved = false;
  bool _hapticFired = false;

  // Time tracking for visual effects (breathing glow, bead rotation)
  int _animStartMs = -1;
  int _animElapsedMs = 0;

  @override
  void initState() {
    super.initState();
    _engine = FishingTimingEngine(
      difficultyMultiplier: widget.difficultyMultiplier,
    );

    _animController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..addListener(_onTick);

    _animController.repeat();
  }

  void _onTick() {
    if (_resolved) return;

    final now = DateTime.now().millisecondsSinceEpoch;
    if (_animStartMs < 0) _animStartMs = now;

    // update() returns true exactly when the orange state flips this frame.
    final orangeStateChanged = _engine.update(now);
    final isOrange = _engine.isInOrangeStrikeWindow;

    setState(() {
      _currentRadius = _engine.currentRadius;
      _isStrikeWindow = isOrange;
      _animElapsedMs = now - _animStartMs;
    });

    // Haptic fires exactly once per orange window entry (on the transition frame).
    if (orangeStateChanged && isOrange && !_hapticFired) {
      _hapticFired = true;
      HapticFeedback.selectionClick();
    } else if (!isOrange) {
      _hapticFired = false;
    }
  }

  void _handleTap() {
    if (_resolved) return;
    _resolved = true;
    _animController.stop();

    final result = _engine.registerTap();
    widget.onResolve(result.success, result.accuracy);
  }

  @override
  void dispose() {
    _engine.stop();
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
          // ── 1. Atmospheric blur overlay ───────────────────────────────────
          BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 9, sigmaY: 9),
            child: Container(color: Colors.black.withValues(alpha: 0.60)),
          ),

          // ── 2. Centered Timing Visuals ────────────────────────────────────
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Top Status Badge
                AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: _isStrikeWindow
                        ? const Color(0xFFFF9E00).withValues(alpha: 0.3)
                        : Colors.black54,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: _isStrikeWindow
                          ? const Color(0xFFFF9E00)
                          : Colors.white24,
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
                        _isStrikeWindow
                            ? Icons.flash_on
                            : Icons.remove_red_eye_outlined,
                        color: _isStrikeWindow
                            ? const Color(0xFFFFD166)
                            : Colors.white70,
                        size: 16,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _isStrikeWindow
                            ? 'BITE! HOOK NOW!'
                            : 'WATCH THE WATER...',
                        style: TextStyle(
                          color: _isStrikeWindow
                              ? const Color(0xFFFFD166)
                              : Colors.white70,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.5,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 36),

                // Ring canvas — 300×300px. All effects driven by animElapsedMs.
                SizedBox(
                  width: 300,
                  height: 300,
                  child: CustomPaint(
                    painter: _TorchlightRingPainter(
                      currentOuterRadius: _currentRadius,
                      innerRadius: _innerRingRadius,
                      isInStrikeZone: _isStrikeWindow,
                      animElapsedMs: _animElapsedMs,
                    ),
                  ),
                ),

                const SizedBox(height: 36),

                // Action Prompt
                AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 36,
                    vertical: 15,
                  ),
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
                          color: const Color(0xFFFF5400)
                              .withValues(alpha: 0.65),
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
                        _isStrikeWindow
                            ? 'CLICK ANYWHERE!'
                            : 'WAIT FOR ORANGE...',
                        style: TextStyle(
                          color: _isStrikeWindow
                              ? Colors.white
                              : Colors.white60,
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

/// Painter for the Torchlight ring mechanic with organic visual effects.
///
/// Effects driven by [animElapsedMs]:
/// - Breathing glow: outer ring glow width pulses with a slow sine wave.
/// - Bead rotation: 4 sparkle beads orbit at constant angular velocity.
/// - Proximity tint: outer ring warms from cyan → amber as it nears the inner ring.
/// - Strike strobe: fast sine pulse on inner ring during orange window.
/// - Fishing line: thin line from canvas top → hook center.
/// - Water depth: 2 faint concentric ambient rings for spatial depth.
class _TorchlightRingPainter extends CustomPainter {
  final double currentOuterRadius;
  final double innerRadius;
  final bool isInStrikeZone;
  final int animElapsedMs;

  _TorchlightRingPainter({
    required this.currentOuterRadius,
    required this.innerRadius,
    required this.isInStrikeZone,
    required this.animElapsedMs,
  });

  // Proximity factor: 0.0 when outer ring is at max, 1.0 when at inner ring.
  double get _proximityFactor {
    const travel =
        FishingTimingEngine.maxOuterRadius -
        FishingTimingEngine.innerRingRadius;
    final dist = currentOuterRadius - FishingTimingEngine.innerRingRadius;
    return (1.0 - (dist / travel)).clamp(0.0, 1.0);
  }

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final tMs = animElapsedMs.toDouble();

    // ── Pre-compute time-based animation values ───────────────────────────
    // Slow breathing pulse: period ~1.8s. Output: -1 → +1.
    final breathSin = sin(tMs / 1800.0 * 2 * pi);
    // Bead rotation: full revolution every 3.5s.
    final beadAngle = (tMs / 3500.0) * 2 * pi;
    // Strike strobe: fast pulse ~5Hz during orange window.
    final strobeSin = isInStrikeZone ? sin(tMs / 200.0 * 2 * pi) : 0.0;

    // ── 1. Fishing line (from top of canvas down to hook eyelet) ──────────
    final lineTopY = 0.0;
    final lineEndY = center.dy - 14; // hook eyelet
    final linePaint = Paint()
      ..color = Colors.white.withValues(alpha: isInStrikeZone ? 0.55 : 0.28)
      ..style = PaintingStyle.stroke
      ..strokeWidth = isInStrikeZone ? 1.8 : 1.2
      ..strokeCap = StrokeCap.round;
    // Slight sag — draw as a gentle curve (quadratic bezier)
    final linePath = Path()
      ..moveTo(center.dx, lineTopY)
      ..quadraticBezierTo(
        center.dx + (isInStrikeZone ? 4 : 2), // subtle sag
        (lineEndY + lineTopY) / 2,
        center.dx,
        lineEndY,
      );
    canvas.drawPath(linePath, linePaint);

    // ── 2. Water depth — ambient concentric rings ─────────────────────────
    final depthPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;
    for (final r in [75.0, 110.0]) {
      depthPaint.color = const Color(0xFF0077B6).withValues(alpha: 0.08);
      canvas.drawCircle(center, r, depthPaint);
    }

    // ── 3. Water fill background ──────────────────────────────────────────
    final waterPaint = Paint()
      ..color = const Color(0xFF0077B6).withValues(alpha: 0.10)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, 118, waterPaint);

    // ── 4. Inner ring ─────────────────────────────────────────────────────
    // During strike: glow strobe pulses the fill opacity.
    final innerFillAlpha = isInStrikeZone
        ? (0.30 + strobeSin * 0.12).clamp(0.18, 0.45)
        : 0.35;
    final innerBgPaint = Paint()
      ..color = isInStrikeZone
          ? const Color(0xFFFF9E00).withValues(alpha: innerFillAlpha)
          : const Color(0xFF0F4C81).withValues(alpha: 0.38)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, innerRadius, innerBgPaint);

    final innerBorderPaint = Paint()
      ..color = isInStrikeZone
          ? const Color(0xFFFF9E00)
          : const Color(0xFF00E5FF)
      ..style = PaintingStyle.stroke
      ..strokeWidth = isInStrikeZone ? 3.8 : 2.0;
    canvas.drawCircle(center, innerRadius, innerBorderPaint);

    // Inner glow — strobe during strike
    final innerGlowWidth = isInStrikeZone
        ? (12.0 + strobeSin * 4.0).clamp(8.0, 16.0)
        : 4.0;
    final innerGlowAlpha = isInStrikeZone
        ? (0.60 + strobeSin * 0.15).clamp(0.45, 0.80)
        : 0.18;
    final innerGlowPaint = Paint()
      ..color =
          (isInStrikeZone ? const Color(0xFFFF9E00) : const Color(0xFF00E5FF))
              .withValues(alpha: innerGlowAlpha)
      ..style = PaintingStyle.stroke
      ..strokeWidth = innerGlowWidth;
    canvas.drawCircle(center, innerRadius, innerGlowPaint);

    // Central hook & bait
    _drawBaitHook(canvas, center, isInStrikeZone);

    // ── 5. Dynamic outer ring ─────────────────────────────────────────────
    // Proximity tint: lerp outer ring color cyan → amber as ring closes in.
    // At max distance: pure cyan. At inner ring: full amber (like strike color).
    final p = _proximityFactor;
    final Color outerRingColor;
    if (isInStrikeZone) {
      outerRingColor = const Color(0xFFFF5400);
    } else {
      // Lerp cyan (0xFF90E0EF) → amber (0xFFFFB347) based on proximity
      outerRingColor = Color.lerp(
        const Color(0xFF90E0EF),
        const Color(0xFFFFB347),
        p,
      )!;
    }

    // Breathing glow: width oscillates with slow sine wave
    final breathingGlowWidth = isInStrikeZone
        ? (15.0 + strobeSin * 4.0).clamp(10.0, 20.0)
        : (7.0 + breathSin * 2.5).clamp(4.5, 9.5);
    final breathingGlowAlpha = isInStrikeZone
        ? (0.72 + strobeSin * 0.12).clamp(0.55, 0.88)
        : (0.28 + breathSin * 0.08 + p * 0.15).clamp(0.18, 0.55);

    // Outer glow (drawn first, behind solid ring)
    final outerGlowPaint = Paint()
      ..color = outerRingColor.withValues(alpha: breathingGlowAlpha)
      ..style = PaintingStyle.stroke
      ..strokeWidth = breathingGlowWidth;
    canvas.drawCircle(center, currentOuterRadius, outerGlowPaint);

    // Outer solid ring
    final outerStrokeWidth = isInStrikeZone
        ? 5.2
        : (3.0 + p * 1.5); // slightly thicker when near inner ring
    final outerRingPaint = Paint()
      ..color = outerRingColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = outerStrokeWidth;
    canvas.drawCircle(center, currentOuterRadius, outerRingPaint);

    // ── 6. Orbiting sparkle beads ─────────────────────────────────────────
    // 4 beads at 90° intervals, rotating at constant angular velocity.
    // Size and color inherit from outer ring (proximity-tinted).
    final beadPaint = Paint()
      ..color = outerRingColor
      ..style = PaintingStyle.fill;
    final beadSize = isInStrikeZone
        ? (4.5 + strobeSin * 0.8).clamp(3.5, 5.5)
        : 2.5;
    for (int i = 0; i < 4; i++) {
      final angle = beadAngle + (i * pi / 2);
      final bx = center.dx + cos(angle) * currentOuterRadius;
      final by = center.dy + sin(angle) * currentOuterRadius;
      canvas.drawCircle(Offset(bx, by), beadSize, beadPaint);
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
    final arcRect = Rect.fromCircle(
      center: Offset(center.dx - 6, center.dy + 4),
      radius: 6,
    );
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
    // Always repaint: animElapsedMs advances every frame for breathing/rotation.
    return true;
  }
}
