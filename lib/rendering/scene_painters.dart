import 'dart:math';

import 'package:flutter/material.dart';

/// Renders the surrounding woodland clearing: mossy ground, boulders, dirt path, and trees.
class EnvironmentPainter extends CustomPainter {
  final Offset holeCenter;
  final double holeRadiusX;
  final double holeRadiusY;

  EnvironmentPainter({
    required this.holeCenter,
    required this.holeRadiusX,
    required this.holeRadiusY,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // 1. Forest clearing base gradient
    final groundPaint = Paint()
      ..shader = RadialGradient(
        center: const Alignment(0.1, 0.2),
        radius: 1.2,
        colors: const [
          Color(0xFF384333), // Illuminated mossy earth
          Color(0xFF242C20), // Dark soil
          Color(0xFF141912), // Deep woodland shadows
        ],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), groundPaint);

    // 2. Dirt path patch under well & fisherman
    final pathPaint = Paint()
      ..color = const Color(0xFF4A3E31).withValues(alpha: 0.45)
      ..style = PaintingStyle.fill;
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(holeCenter.dx - 20, holeCenter.dy + 15),
        width: holeRadiusX * 2.8,
        height: holeRadiusY * 2.6,
      ),
      pathPaint,
    );

    // 3. Foliage silhouettes in corners
    final leafPaint = Paint()..color = const Color(0xFF1B2A1E);
    canvas.drawCircle(
      Offset(size.width * 0.95, size.height * 0.15),
      110,
      leafPaint,
    );
    canvas.drawCircle(
      Offset(size.width * 0.82, size.height * 0.22),
      70,
      leafPaint,
    );

    // 4. Boulders on top-left
    final rockPaint = Paint()..color = const Color(0xFF2F353B);
    final rockHighlight = Paint()..color = const Color(0xFF474E56);
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(size.width * 0.22, size.height * 0.25),
        width: 95,
        height: 65,
      ),
      rockPaint,
    );
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(size.width * 0.20, size.height * 0.23),
        width: 75,
        height: 45,
      ),
      rockHighlight,
    );

    // Small pebbles
    canvas.drawCircle(
      Offset(holeCenter.dx - holeRadiusX * 1.3, holeCenter.dy + 40),
      9,
      rockPaint,
    );
    canvas.drawCircle(
      Offset(
        holeCenter.dx + holeRadiusX * 0.9,
        holeCenter.dy + holeRadiusY + 18,
      ),
      12,
      rockPaint,
    );
    canvas.drawCircle(
      Offset(holeCenter.dx - 40, holeCenter.dy + holeRadiusY + 25),
      8,
      rockPaint,
    );
  }

  @override
  bool shouldRepaint(covariant EnvironmentPainter oldDelegate) =>
      oldDelegate.holeCenter != holeCenter ||
      oldDelegate.holeRadiusX != holeRadiusX ||
      oldDelegate.holeRadiusY != holeRadiusY;
}

/// Renders the wooden lantern stand and warm glowing lantern.
class LanternLightingPainter extends CustomPainter {
  final Offset lanternPos;

  LanternLightingPainter({required this.lanternPos});

  @override
  void paint(Canvas canvas, Size size) {
    // 1. Crate & Post
    final woodPaint = Paint()..color = const Color(0xFF2E1C11);
    final woodTopPaint = Paint()..color = const Color(0xFF4E3624);

    final crateRect = Rect.fromCenter(
      center: Offset(lanternPos.dx + 12, lanternPos.dy + 45),
      width: 52,
      height: 38,
    );
    canvas.drawRect(crateRect, woodPaint);
    canvas.drawRect(
      Rect.fromLTWH(crateRect.left, crateRect.top, crateRect.width, 10),
      woodTopPaint,
    );

    // 2. Lantern housing & roof
    canvas.drawRect(
      Rect.fromCenter(
        center: Offset(lanternPos.dx, lanternPos.dy + 16),
        width: 22,
        height: 8,
      ),
      woodPaint,
    );
    final roofPath = Path();
    roofPath.moveTo(lanternPos.dx - 16, lanternPos.dy - 6);
    roofPath.lineTo(lanternPos.dx + 16, lanternPos.dy - 6);
    roofPath.lineTo(lanternPos.dx, lanternPos.dy - 20);
    roofPath.close();
    canvas.drawPath(roofPath, woodPaint);

    // 3. Glowing Glass Core
    final glassPaint = Paint()
      ..shader = RadialGradient(
        colors: const [Color(0xFFFFF3B0), Color(0xFFFF9E00), Color(0xFFE85D04)],
      ).createShader(Rect.fromCircle(center: lanternPos, radius: 14));
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: lanternPos, width: 20, height: 22),
        const Radius.circular(4),
      ),
      glassPaint,
    );

    // 4. Atmospheric radial ambient glow over scene
    final glowPaint = Paint()
      ..shader = RadialGradient(
        center: Alignment(
          (lanternPos.dx / size.width) * 2 - 1,
          (lanternPos.dy / size.height) * 2 - 1,
        ),
        radius: 0.75,
        colors: [
          const Color(0xFFFFB703).withValues(alpha: 0.28),
          const Color(0xFFFB8500).withValues(alpha: 0.12),
          Colors.transparent,
        ],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), glowPaint);
  }

  @override
  bool shouldRepaint(covariant LanternLightingPainter oldDelegate) =>
      oldDelegate.lanternPos != lanternPos;
}

/// Renders the stone-lined circular fishing hole, deep pit, and water ripples.
class FishingHolePainter extends CustomPainter {
  final Offset center;
  final double rx;
  final double ry;
  final Color waterColor;
  final double rippleProgress;

  FishingHolePainter({
    required this.center,
    required this.rx,
    required this.ry,
    required this.waterColor,
    required this.rippleProgress,
  });

  @override
  void paint(Canvas canvas, Size size) {
    const stoneCount = 18;
    final stoneRingPaint = Paint()..color = const Color(0xFF43494D);
    final stoneTopPaint = Paint()..color = const Color(0xFF636B70);
    final stoneShadowPaint = Paint()..color = const Color(0xFF23272A);

    // 1. Draw 3D stone lip blocks
    final outerRx = rx + 18.0;
    final outerRy = ry + 14.0;

    for (int i = 0; i < stoneCount; i++) {
      final angle = (i * 2 * pi) / stoneCount;
      final stoneCenter = Offset(
        center.dx + cos(angle) * ((rx + outerRx) / 2),
        center.dy + sin(angle) * ((ry + outerRy) / 2),
      );

      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(stoneCenter.dx, stoneCenter.dy + 3),
          width: 24,
          height: 16,
        ),
        stoneShadowPaint,
      );
      canvas.drawOval(
        Rect.fromCenter(center: stoneCenter, width: 22, height: 14),
        stoneRingPaint,
      );
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(stoneCenter.dx, stoneCenter.dy - 2),
          width: 17,
          height: 10,
        ),
        stoneTopPaint,
      );
    }

    // 2. Interior well depth
    final pitRect = Rect.fromCenter(
      center: center,
      width: rx * 2,
      height: ry * 2,
    );
    canvas.drawOval(pitRect, Paint()..color = const Color(0xFF07131B));

    // 3. Water surface inside stone well
    final waterSurfaceRect = Rect.fromCenter(
      center: Offset(center.dx, center.dy + 2),
      width: rx * 1.88,
      height: ry * 1.82,
    );

    final waterGradient = Paint()
      ..shader = RadialGradient(
        center: const Alignment(-0.2, -0.3),
        radius: 0.9,
        colors: [
          waterColor.withValues(alpha: 0.95),
          const Color(0xFF041522),
          const Color(0xFF01080D),
        ],
      ).createShader(waterSurfaceRect);
    canvas.drawOval(waterSurfaceRect, waterGradient);

    // 4. Animated concentric ripples
    final rippleCenter = Offset(center.dx + 4, center.dy + 4);
    for (int i = 1; i <= 3; i++) {
      final rippleScale = ((rippleProgress * 1.2 + i * 0.33) % 1.0);
      final rW = rx * 0.85 * rippleScale;
      final rH = ry * 0.85 * rippleScale;
      final alpha = (1.0 - rippleScale).clamp(0.0, 0.7);

      final ripplePaint = Paint()
        ..color = const Color(0xFF00E5FF).withValues(alpha: alpha * 0.6)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0;

      canvas.drawOval(
        Rect.fromCenter(center: rippleCenter, width: rW, height: rH),
        ripplePaint,
      );
    }

    // Bobber landing ring
    canvas.drawOval(
      Rect.fromCenter(center: rippleCenter, width: 22, height: 14),
      Paint()
        ..color = const Color(0xFF90E0EF).withValues(alpha: 0.8)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.2,
    );
  }

  @override
  bool shouldRepaint(covariant FishingHolePainter oldDelegate) => true;
}

/// Renders the top-down isometric fisherman, rod flex, and fishing line into the water.
class FishermanPainter extends CustomPainter {
  final Offset pos;
  final Offset holeCenter;
  final double holeRadiusY;
  final bool isPulling;
  final double animProgress;

  FishermanPainter({
    required this.pos,
    required this.holeCenter,
    required this.holeRadiusY,
    required this.isPulling,
    required this.animProgress,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final tensionPull = isPulling ? sin(animProgress * 16 * pi) * 6 : 0.0;

    // Soft drop shadow
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(pos.dx, pos.dy + 38),
        width: 44,
        height: 20,
      ),
      Paint()..color = Colors.black.withValues(alpha: 0.45),
    );

    // Boots
    final bootPaint = Paint()..color = const Color(0xFF1E252B);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: Offset(pos.dx - 8, pos.dy + 28),
          width: 12,
          height: 16,
        ),
        const Radius.circular(4),
      ),
      bootPaint,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: Offset(pos.dx + 8, pos.dy + 28),
          width: 12,
          height: 16,
        ),
        const Radius.circular(4),
      ),
      bootPaint,
    );

    // Vest & Backpack
    final vestPaint = Paint()..color = const Color(0xFFC84B31);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: Offset(pos.dx, pos.dy + 6),
          width: 28,
          height: 32,
        ),
        const Radius.circular(8),
      ),
      vestPaint,
    );
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(pos.dx - 12, pos.dy + 4),
        width: 14,
        height: 24,
      ),
      Paint()..color = const Color(0xFF9D3420),
    );

    // Head, Hair & Beanie
    final skinPaint = Paint()..color = const Color(0xFFFFD166);
    canvas.drawCircle(Offset(pos.dx + 6, pos.dy - 12), 6, skinPaint);
    canvas.drawCircle(
      Offset(pos.dx, pos.dy - 16),
      13,
      Paint()..color = const Color(0xFF222222),
    );
    canvas.drawCircle(
      Offset(pos.dx - 2, pos.dy - 18),
      12,
      Paint()..color = const Color(0xFF343A40),
    );

    // Fishing Rod
    final rodPaint = Paint()
      ..color = const Color(0xFFD4A373)
      ..strokeWidth = 3.2
      ..strokeCap = StrokeCap.round;

    final handPos = Offset(pos.dx + 12, pos.dy);
    final rodTip = Offset(
      holeCenter.dx - 4 + tensionPull,
      holeCenter.dy - holeRadiusY * 0.7 - (isPulling ? 25 : 12),
    );

    canvas.drawLine(handPos, rodTip, rodPaint);

    // Vertical line dropping into well
    final lineTarget = Offset(holeCenter.dx + 4, holeCenter.dy + 4);
    final linePaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.9)
      ..strokeWidth = 1.3;

    canvas.drawLine(rodTip, lineTarget, linePaint);

    // Bobber in water
    final bobberPaint = Paint()
      ..color = isPulling ? const Color(0xFFFF3366) : const Color(0xFFFF9E00);
    canvas.drawCircle(lineTarget, 5.5, bobberPaint);
    canvas.drawCircle(
      lineTarget,
      8.5,
      Paint()
        ..color = Colors.white.withValues(alpha: 0.8)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );
  }

  @override
  bool shouldRepaint(covariant FishermanPainter oldDelegate) => true;
}
