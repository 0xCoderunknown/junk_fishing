import 'package:flutter/material.dart';

import '../models/fishing_state.dart';
import '../models/location.dart';
import '../rendering/scene_painters.dart';

/// Top-down isometric world view composed of modular rendering layers:
/// - [EnvironmentPainter] (ground, rocks, trees, dirt path - static)
/// - [LanternLightingPainter] (lamp post & warm ambient shader - static)
/// - [FishingHolePainter] (stone well masonry, water depth, and animated ripples)
/// - [FishermanPainter] (character, rod flex, and line physics)
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

  Color _parseColor(String hex, {Color fallback = const Color(0xFF1B4965)}) {
    try {
      return Color(int.parse(hex));
    } catch (_) {
      return fallback;
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final screenWidth = constraints.maxWidth;
        final screenHeight = constraints.maxHeight;

        final holeCenter = Offset(screenWidth * 0.56, screenHeight * 0.62);
        final holeRadiusX = screenWidth * 0.32;
        final holeRadiusY = screenWidth * 0.22;

        final lanternPos = Offset(
          holeCenter.dx + holeRadiusX * 0.75,
          holeCenter.dy - holeRadiusY * 1.55,
        );

        final fishermanPos = Offset(
          holeCenter.dx - holeRadiusX * 0.95,
          holeCenter.dy - holeRadiusY * 0.35,
        );

        final waterColor = _parseColor(
          widget.location?.waterColor ?? '0xFF1B4965',
        );

        return Stack(
          fit: StackFit.expand,
          children: [
            // 1. Environment: Ground & Foliage (Static - cached in RepaintBoundary)
            RepaintBoundary(
              child: CustomPaint(
                painter: EnvironmentPainter(
                  holeCenter: holeCenter,
                  holeRadiusX: holeRadiusX,
                  holeRadiusY: holeRadiusY,
                ),
              ),
            ),

            // 2. Wooden Stand & Glowing Lantern (Static - cached in RepaintBoundary)
            RepaintBoundary(
              child: CustomPaint(
                painter: LanternLightingPainter(lanternPos: lanternPos),
              ),
            ),

            // 3 & 4. Animated Water & Fisherman
            AnimatedBuilder(
              animation: _ambientController,
              builder: (context, child) {
                return Stack(
                  fit: StackFit.expand,
                  children: [
                    // 3. Stone Fishing Hole & Animated Water
                    CustomPaint(
                      painter: FishingHolePainter(
                        center: holeCenter,
                        rx: holeRadiusX,
                        ry: holeRadiusY,
                        waterColor: waterColor,
                        rippleProgress: _ambientController.value,
                      ),
                    ),

                    // 4. Fisherman Character & Rod
                    CustomPaint(
                      painter: FishermanPainter(
                        pos: fishermanPos,
                        holeCenter: holeCenter,
                        holeRadiusY: holeRadiusY,
                        isPulling: widget.state == FishingState.pullingRod,
                        animProgress: _ambientController.value,
                      ),
                    ),
                  ],
                );
              },
            ),

            // 5. Interactive "TAP THE HOLE" Target Prompt
            if (widget.state == FishingState.readyToCast)
              Positioned(
                left: holeCenter.dx - holeRadiusX,
                top: holeCenter.dy - holeRadiusY,
                width: holeRadiusX * 2,
                height: holeRadiusY * 2,
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: widget.onPondTap,
                  child: Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.75),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: Colors.amberAccent,
                          width: 1.5,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.touch_app,
                            color: Colors.amberAccent,
                            size: 18,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'TAP THE HOLE',
                            style: TextStyle(
                              color: Colors.amber.shade200,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 1.4,
                              fontSize: 12,
                            ),
                          ),
                        ],
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
