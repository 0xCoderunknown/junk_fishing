import 'dart:math';
import 'dart:ui';
import 'package:flutter/material.dart';

typedef RippleResolveCallback = void Function(bool success, double accuracy);

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
  late AnimationController _oscillationController;
  bool _resolved = false;

  // The sweet spot range in normalized oscillation [0.0, 1.0]
  // Base sweet spot: [0.65, 0.88]
  late double _targetMin;
  late double _targetMax;

  @override
  void initState() {
    super.initState();

    // Adjust timing window by location difficulty
    final windowWidth = (0.24 / widget.difficultyMultiplier).clamp(0.12, 0.30);
    _targetMin = 0.70 - (windowWidth / 2);
    _targetMax = 0.70 + (windowWidth / 2);

    final durationMs = (1400 / widget.difficultyMultiplier).clamp(900, 1800).toInt();

    _oscillationController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: durationMs),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _oscillationController.dispose();
    super.dispose();
  }

  void _handleTap() {
    if (_resolved) return;
    _resolved = true;

    final currentVal = _oscillationController.value;
    final inWindow = currentVal >= _targetMin && currentVal <= _targetMax;

    // Calculate accuracy (1.0 = right in the center of sweet spot)
    final targetCenter = (_targetMin + _targetMax) / 2;
    final dist = (currentVal - targetCenter).abs();
    final halfWidth = (_targetMax - _targetMin) / 2;
    final accuracy = (1.0 - (dist / halfWidth)).clamp(0.0, 1.0);

    widget.onResolve(inWindow, accuracy);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: _handleTap,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // 1. Blurred background
          BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 9, sigmaY: 9),
            child: Container(
              color: Colors.black.withValues(alpha: 0.55),
            ),
          ),

          // 2. Centered Timing CustomPainter
          AnimatedBuilder(
            animation: _oscillationController,
            builder: (context, child) {
              final val = _oscillationController.value;
              final isInZone = val >= _targetMin && val <= _targetMax;

              return Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Status Badge
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 6),
                      decoration: BoxDecoration(
                        color: isInZone ? Colors.tealAccent.withValues(alpha: 0.25) : Colors.black54,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: isInZone ? Colors.tealAccent : Colors.white24,
                          width: 1.5,
                        ),
                      ),
                      child: Text(
                        isInZone ? 'STRIKE WINDOW ACTIVE!' : 'WAIT FOR TARGET RING...',
                        style: TextStyle(
                          color: isInZone ? Colors.tealAccent : Colors.white70,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.4,
                          fontSize: 12,
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Concentric Ripple Ring Canvas
                    SizedBox(
                      width: 280,
                      height: 280,
                      child: CustomPaint(
                        painter: _RippleWavePainter(
                          waveValue: val,
                          targetMin: _targetMin,
                          targetMax: _targetMax,
                        ),
                      ),
                    ),

                    const SizedBox(height: 28),

                    // Tactile tap prompt button
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: isInZone
                              ? [const Color(0xFF00B4D8), const Color(0xFF0077B6)]
                              : [const Color(0xFF333333), const Color(0xFF222222)],
                        ),
                        borderRadius: BorderRadius.circular(30),
                        boxShadow: [
                          if (isInZone)
                            BoxShadow(
                              color: const Color(0xFF00B4D8).withValues(alpha: 0.6),
                              blurRadius: 18,
                              spreadRadius: 2,
                            ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.ads_click,
                            color: isInZone ? Colors.white : Colors.white54,
                            size: 22,
                          ),
                          const SizedBox(width: 10),
                          Text(
                            'TAP TO HOOK!',
                            style: TextStyle(
                              color: isInZone ? Colors.white : Colors.white70,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 2,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Tap anywhere when ripple aligns with boundary ring',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.5),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _RippleWavePainter extends CustomPainter {
  final double waveValue;
  final double targetMin;
  final double targetMax;

  _RippleWavePainter({
    required this.waveValue,
    required this.targetMin,
    required this.targetMax,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    const maxRadius = 125.0;
    const minRadius = 25.0;

    // 1. Center Bobber / Water Disturbance
    final centerPaint = Paint()..color = const Color(0xFF00B4D8);
    canvas.drawCircle(center, 9, centerPaint);
    canvas.drawCircle(
      center,
      14,
      Paint()
        ..color = const Color(0xFF00B4D8).withValues(alpha: 0.3)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );

    // 2. Target Boundary Ring Zone (Target rings)
    final targetInnerRadius = minRadius + (maxRadius - minRadius) * targetMin;
    final targetOuterRadius = minRadius + (maxRadius - minRadius) * targetMax;
    final targetMidRadius = (targetInnerRadius + targetOuterRadius) / 2;

    // Target Zone fill band
    final zoneBandPaint = Paint()
      ..color = const Color(0xFF2A9D8F).withValues(alpha: 0.25)
      ..style = PaintingStyle.stroke
      ..strokeWidth = targetOuterRadius - targetInnerRadius;
    canvas.drawCircle(center, targetMidRadius, zoneBandPaint);

    // Target Inner boundary line
    final boundaryPaint = Paint()
      ..color = const Color(0xFF2A9D8F).withValues(alpha: 0.8)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;
    canvas.drawCircle(center, targetInnerRadius, boundaryPaint);

    // Target Outer boundary line
    canvas.drawCircle(center, targetOuterRadius, boundaryPaint);

    // Tick marks on the boundary ring
    final tickPaint = Paint()
      ..color = const Color(0xFF2A9D8F)
      ..strokeWidth = 2.0;
    for (int i = 0; i < 12; i++) {
      final angle = (i * 2 * pi) / 12;
      final p1 = Offset(
        center.dx + cos(angle) * (targetInnerRadius - 4),
        center.dy + sin(angle) * (targetInnerRadius - 4),
      );
      final p2 = Offset(
        center.dx + cos(angle) * (targetOuterRadius + 4),
        center.dy + sin(angle) * (targetOuterRadius + 4),
      );
      canvas.drawLine(p1, p2, tickPaint);
    }

    // 3. Dynamic Oscillating Ripple Wave
    final currentRippleRadius = minRadius + (maxRadius - minRadius) * waveValue;
    final isInsideSweetSpot = waveValue >= targetMin && waveValue <= targetMax;

    // Oscillating primary ripple ring
    final ripplePaint = Paint()
      ..color = isInsideSweetSpot ? const Color(0xFFFFD166) : const Color(0xFF00E5FF)
      ..style = PaintingStyle.stroke
      ..strokeWidth = isInsideSweetSpot ? 5.5 : 3.5;

    canvas.drawCircle(center, currentRippleRadius, ripplePaint);

    // Glow halo on the ripple
    final rippleGlow = Paint()
      ..color = (isInsideSweetSpot ? const Color(0xFFFFD166) : const Color(0xFF00E5FF))
          .withValues(alpha: 0.45)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 12.0;
    canvas.drawCircle(center, currentRippleRadius, rippleGlow);

    // Secondary trailing harmonic ripple
    final secondaryRadius = (currentRippleRadius * 0.75).clamp(minRadius, maxRadius);
    final secondaryPaint = Paint()
      ..color = const Color(0xFF00E5FF).withValues(alpha: 0.25)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;
    canvas.drawCircle(center, secondaryRadius, secondaryPaint);
  }

  @override
  bool shouldRepaint(covariant _RippleWavePainter oldDelegate) {
    return oldDelegate.waveValue != waveValue ||
        oldDelegate.targetMin != targetMin ||
        oldDelegate.targetMax != targetMax;
  }
}
