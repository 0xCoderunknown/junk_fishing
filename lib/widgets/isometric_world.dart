import 'dart:math';
import 'package:flutter/material.dart';
import '../models/fishing_state.dart';
import '../models/location.dart';

class IsometricWorld extends StatefulWidget {
  final FishingState state;
  final Location? location;
  final VoidCallback? onPondTap;

  const IsometricWorld({
    super.key,
    required this.state,
    required this.location,
    this.onPondTap,
  });

  @override
  State<IsometricWorld> createState() => _IsometricWorldState();
}

class _IsometricWorldState extends State<IsometricWorld>
    with SingleTickerProviderStateMixin {
  late AnimationController _ambientController;

  @override
  void initState() {
    super.initState();
    _ambientController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat();
  }

  @override
  void dispose() {
    _ambientController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ambientController,
      builder: (context, child) {
        return Stack(
          fit: StackFit.expand,
          children: [
            // Custom drawn Isometric Pier, Water pond, and Fisherman
            CustomPaint(
              painter: _WorldPainter(
                progress: _ambientController.value,
                state: widget.state,
                waterHexColor: widget.location?.waterColor ?? '0xFF2A9D8F',
                themeHexColor: widget.location?.themeColor ?? '0xFF264653',
              ),
              child: const SizedBox.expand(),
            ),

            // Tap detector target for water pond in readyToCast state
            if (widget.state == FishingState.readyToCast)
              Positioned(
                bottom: MediaQuery.of(context).size.height * 0.12,
                right: MediaQuery.of(context).size.width * 0.08,
                width: MediaQuery.of(context).size.width * 0.65,
                height: MediaQuery.of(context).size.height * 0.45,
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: widget.onPondTap,
                  child: Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.amberAccent.withValues(
                          alpha: 0.3 + 0.3 * sin(_ambientController.value * 2 * pi).abs(),
                        ),
                        width: 2.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.cyanAccent.withValues(alpha: 0.15),
                          blurRadius: 20,
                          spreadRadius: 5,
                        ),
                      ],
                    ),
                    child: Center(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.7),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: Colors.amberAccent, width: 1.5),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.touch_app, color: Colors.amberAccent, size: 20),
                            const SizedBox(width: 8),
                            Text(
                              'TAP POND TO CAST',
                              style: TextStyle(
                                color: Colors.amber.shade200,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1.2,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}

class _WorldPainter extends CustomPainter {
  final double progress;
  final FishingState state;
  final String waterHexColor;
  final String themeHexColor;

  _WorldPainter({
    required this.progress,
    required this.state,
    required this.waterHexColor,
    required this.themeHexColor,
  });

  Color _parseColor(String hex, {Color fallback = const Color(0xFF264653)}) {
    try {
      return Color(int.parse(hex));
    } catch (_) {
      return fallback;
    }
  }

  @override
  void paint(Canvas canvas, Size size) {
    final waterBase = _parseColor(waterHexColor);
    final themeBase = _parseColor(themeHexColor);

    // 1. Sky & Horizon Gradient
    final skyPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          themeBase.withValues(alpha: 0.95),
          themeBase.withValues(alpha: 0.6),
          waterBase.withValues(alpha: 0.8),
        ],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), skyPaint);

    // 2. Distant scrap silhouettes / industrial smog
    _drawScrapSkyline(canvas, size, themeBase);

    // 3. Water Pond Area
    _drawWater(canvas, size, waterBase);

    // 4. Isometric Pier & Planks
    _drawIsometricPier(canvas, size);

    // 5. Fisherman Character & Fishing Rod
    _drawFisherman(canvas, size);
  }

  void _drawScrapSkyline(Canvas canvas, Size size, Color themeColor) {
    final paint = Paint()
      ..color = themeColor.withValues(alpha: 0.4)
      ..style = PaintingStyle.fill;

    final path = Path();
    path.moveTo(0, size.height * 0.45);
    // Draw quirky cranes, pylons, and junk silhouettes in the background
    path.lineTo(size.width * 0.15, size.height * 0.40);
    path.lineTo(size.width * 0.20, size.height * 0.43);
    path.lineTo(size.width * 0.35, size.height * 0.35); // crane arm
    path.lineTo(size.width * 0.45, size.height * 0.44);
    path.lineTo(size.width * 0.65, size.height * 0.38);
    path.lineTo(size.width * 0.80, size.height * 0.42);
    path.lineTo(size.width, size.height * 0.37);
    path.lineTo(size.width, size.height * 0.55);
    path.lineTo(0, size.height * 0.55);
    path.close();

    canvas.drawPath(path, paint);
  }

  void _drawWater(Canvas canvas, Size size, Color waterBase) {
    final waterRect = Rect.fromLTWH(0, size.height * 0.48, size.width, size.height * 0.52);

    final waterGradient = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          waterBase.withValues(alpha: 0.85),
          waterBase.withValues(alpha: 0.95),
          Colors.black87,
        ],
      ).createShader(waterRect);

    canvas.drawRect(waterRect, waterGradient);

    // Animated water wave bands & ripples
    final wavePaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.15)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    for (int i = 0; i < 6; i++) {
      final yOffset = size.height * 0.52 + (i * size.height * 0.08);
      final phase = progress * 2 * pi + (i * 0.8);
      final wavePath = Path();

      wavePath.moveTo(0, yOffset + sin(phase) * 6);
      for (double x = 0; x <= size.width; x += 30) {
        final y = yOffset + sin(phase + (x / 70)) * 6;
        wavePath.lineTo(x, y);
      }
      canvas.drawPath(wavePath, wavePaint);
    }

    // Floating absurd debris (plastic bottle / rubber ring) bobbing in water
    final debrisBob = sin(progress * 2 * pi) * 5;
    final debrisPaint = Paint()..color = Colors.tealAccent.withValues(alpha: 0.4);
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(size.width * 0.75, size.height * 0.65 + debrisBob),
        width: 26,
        height: 10,
      ),
      debrisPaint,
    );
  }

  void _drawIsometricPier(Canvas canvas, Size size) {
    // Wooden pier extending diagonally from bottom-left towards center-right
    final pierPath = Path();
    pierPath.moveTo(0, size.height * 0.75);
    pierPath.lineTo(size.width * 0.48, size.height * 0.60);
    pierPath.lineTo(size.width * 0.48, size.height * 0.72);
    pierPath.lineTo(0, size.height * 0.95);
    pierPath.close();

    final pierFrontPaint = Paint()..color = const Color(0xFF2C1E16);
    canvas.drawPath(pierPath, pierFrontPaint);

    // Pier Top Deck (Isometric surface)
    final deckPath = Path();
    deckPath.moveTo(0, size.height * 0.70);
    deckPath.lineTo(size.width * 0.48, size.height * 0.55);
    deckPath.lineTo(size.width * 0.48, size.height * 0.60);
    deckPath.lineTo(0, size.height * 0.75);
    deckPath.close();

    final deckPaint = Paint()..color = const Color(0xFF4A3525);
    canvas.drawPath(deckPath, deckPaint);

    // Wood plank separation lines
    final plankPaint = Paint()
      ..color = const Color(0xFF1E140E)
      ..strokeWidth = 2.0;

    for (double i = 0.1; i < 0.48; i += 0.08) {
      final start = Offset(size.width * i, size.height * (0.70 - (i * 0.31)));
      final end = Offset(size.width * i, size.height * (0.75 - (i * 0.31)));
      canvas.drawLine(start, end, plankPaint);
    }

    // Pier Pylons in water
    final pylonPaint = Paint()..color = const Color(0xFF1B130E);
    canvas.drawRect(
      Rect.fromLTWH(size.width * 0.43, size.height * 0.60, 14, size.height * 0.25),
      pylonPaint,
    );
  }

  void _drawFisherman(Canvas canvas, Size size) {
    // Fisherman standing near the edge of the pier
    final pierEdgeX = size.width * 0.38;
    final pierEdgeY = size.height * 0.57;

    final isPulling = state == FishingState.pullingRod;
    final rodTension = isPulling ? sin(progress * 16 * pi) * 12 : 0.0;

    // Fisherman Body (Yellow Raincoat)
    final coatPaint = Paint()..color = const Color(0xFFF4A261);
    final coatRect = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: Offset(pierEdgeX - 10, pierEdgeY - 35),
        width: 32,
        height: 48,
      ),
      const Radius.circular(8),
    );
    canvas.drawRRect(coatRect, coatPaint);

    // Boots
    final bootPaint = Paint()..color = const Color(0xFF1E140E);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(pierEdgeX - 22, pierEdgeY - 14, 12, 14),
        const Radius.circular(3),
      ),
      bootPaint,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(pierEdgeX - 8, pierEdgeY - 14, 12, 14),
        const Radius.circular(3),
      ),
      bootPaint,
    );

    // Fisherman Head & Fisherman Bucket Hat
    final facePaint = Paint()..color = const Color(0xFFFFD166);
    canvas.drawCircle(Offset(pierEdgeX - 10, pierEdgeY - 65), 12, facePaint);

    final hatPaint = Paint()..color = const Color(0xFFE76F51);
    final hatPath = Path();
    hatPath.moveTo(pierEdgeX - 28, pierEdgeY - 70);
    hatPath.lineTo(pierEdgeX + 8, pierEdgeY - 70);
    hatPath.lineTo(pierEdgeX + 3, pierEdgeY - 82);
    hatPath.lineTo(pierEdgeX - 23, pierEdgeY - 82);
    hatPath.close();
    canvas.drawPath(hatPath, hatPaint);

    // Fishing Rod
    final rodPaint = Paint()
      ..color = const Color(0xFFE9C46A)
      ..strokeWidth = 3.5
      ..strokeCap = StrokeCap.round;

    final rodHand = Offset(pierEdgeX, pierEdgeY - 40);

    // Rod Tip bends dramatically when pulling
    final rodTipX = pierEdgeX + (isPulling ? 55 : 75);
    final rodTipY = pierEdgeY - (isPulling ? 95 + rodTension : 110);
    final rodTip = Offset(rodTipX, rodTipY);

    canvas.drawLine(rodHand, rodTip, rodPaint);

    // Fishing Line into water
    final bobberX = size.width * 0.72;
    final bobberY = size.height * 0.72 + sin(progress * 2 * pi) * 4;
    final bobber = Offset(bobberX, bobberY);

    final linePaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.8)
      ..strokeWidth = 1.2;

    if (isPulling) {
      // Taut, vibrating curved line
      final linePath = Path();
      linePath.moveTo(rodTip.dx, rodTip.dy);
      linePath.quadraticBezierTo(
        (rodTip.dx + bobber.dx) / 2 + rodTension,
        (rodTip.dy + bobber.dy) / 2 - 20,
        bobber.dx,
        bobber.dy,
      );
      canvas.drawPath(linePath, linePaint);

      // Splash foam circles around bobber when pulling
      final splashPaint = Paint()
        ..color = Colors.white.withValues(alpha: 0.7)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5;
      final splashRadius = 15.0 + (sin(progress * 12 * pi).abs() * 20);
      canvas.drawCircle(bobber, splashRadius, splashPaint);
      canvas.drawCircle(bobber, splashRadius * 0.5, splashPaint);
    } else {
      // Normal dangling line with natural catenary sag
      final linePath = Path();
      linePath.moveTo(rodTip.dx, rodTip.dy);
      linePath.quadraticBezierTo(
        (rodTip.dx + bobber.dx) / 2,
        bobber.dy + 15,
        bobber.dx,
        bobber.dy,
      );
      canvas.drawPath(linePath, linePaint);

      // Red & white bobber floating on water
      canvas.drawCircle(bobber, 7, Paint()..color = Colors.redAccent);
      canvas.drawCircle(bobber.translate(0, 3), 7, Paint()..color = Colors.white);
      // Gentle bobber ripples
      final ripplePaint = Paint()
        ..color = Colors.white.withValues(alpha: 0.4)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5;
      final rippleSize = 8.0 + (sin(progress * 2 * pi).abs() * 10);
      canvas.drawOval(
        Rect.fromCenter(center: bobber.translate(0, 5), width: rippleSize * 2, height: rippleSize),
        ripplePaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _WorldPainter oldDelegate) => true;
}
