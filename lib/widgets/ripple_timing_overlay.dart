import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../engine/fishing_timing_engine.dart';

typedef RippleResolveCallback = void Function(bool success, double accuracy);

/// Torchlight-style fishing timing overlay.
///
/// Pure presentation widget connected to the headless [FishingTimingEngine].
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
  late final FishingTimingEngine _engine;
  late final AnimationController _animController;
  bool _hapticFired = false;

  @override
  void initState() {
    super.initState();
    _engine = FishingTimingEngine(
      difficultyMultiplier: widget.difficultyMultiplier,
    );

    _animController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..addListener(_onFrameTick);

    _animController.repeat();
  }

  void _onFrameTick() {
    if (_engine.isFinished) return;

    _engine.update(DateTime.now().millisecondsSinceEpoch);

    setState(() {});

    final inOrange = _engine.isInOrangeStrikeWindow;
    if (inOrange && !_hapticFired) {
      _hapticFired = true;
      HapticFeedback.selectionClick();
    } else if (!inOrange) {
      _hapticFired = false;
    }
  }

  void _handleTap() {
    if (_engine.isFinished) return;

    final result = _engine.registerTap();
    _animController.stop();
    widget.onResolve(result.success, result.accuracy);
  }

  @override
  void dispose() {
    _animController.dispose();
    _engine.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final inStrikeZone = _engine.isInOrangeStrikeWindow;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: _handleTap,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // 1. Atmospheric blurred backdrop
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
                    color: inStrikeZone
                        ? const Color(0xFFFF9E00).withValues(alpha: 0.3)
                        : Colors.black54,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: inStrikeZone ? const Color(0xFFFF9E00) : Colors.white24,
                      width: inStrikeZone ? 2.5 : 1.5,
                    ),
                    boxShadow: [
                      if (inStrikeZone)
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
                        inStrikeZone ? Icons.flash_on : Icons.remove_red_eye_outlined,
                        color: inStrikeZone ? const Color(0xFFFFD166) : Colors.white70,
                        size: 16,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        inStrikeZone ? 'BITE! HOOK NOW!' : 'WATCH THE WATER...',
                        style: TextStyle(
                          color: inStrikeZone ? const Color(0xFFFFD166) : Colors.white70,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.5,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 36),

                // Dynamic Ring Canvas
                SizedBox(
                  width: 300,
                  height: 300,
                  child: CustomPaint(
                    painter: _TorchlightRingPainter(
                      currentOuterRadius: _engine.currentRadius,
                      innerRadius: FishingTimingEngine.innerRingRadius,
                      isInStrikeZone: inStrikeZone,
                    ),
                  ),
                ),

                const SizedBox(height: 36),

                // Tap Action Prompt Button
                AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  padding: const EdgeInsets.symmetric(horizontal: 36, vertical: 15),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: inStrikeZone
                          ? [const Color(0xFFFF9E00), const Color(0xFFFF5400)]
                          : [const Color(0xFF2B2D42), const Color(0xFF1E1E24)],
                    ),
                    borderRadius: BorderRadius.circular(32),
                    boxShadow: [
                      if (inStrikeZone)
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
                        color: inStrikeZone ? Colors.white : Colors.white54,
                        size: 24,
                      ),
                      const SizedBox(width: 10),
                      Text(
                        inStrikeZone ? 'CLICK ANYWHERE!' : 'WAIT FOR ORANGE...',
                        style: TextStyle(
                          color: inStrikeZone ? Colors.white : Colors.white60,
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

    // 1. Water ripple background behind hook
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

    // 3. Dynamic Shrinking/Expanding Outer Ring
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
      final angle = (i * 3.141592653589793 / 2) + (currentOuterRadius * 0.05);
      final bx = center.dx + (currentOuterRadius * (angle == 0 ? 1 : (angle > 3 ? -1 : 0))); // simplified angle offsets
      final by = center.dy + (currentOuterRadius * (angle > 1 && angle < 4 ? 1 : -1));
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
    canvas.drawArc(arcRect, 0, 3.141592653589793, false, hookPaint);

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
