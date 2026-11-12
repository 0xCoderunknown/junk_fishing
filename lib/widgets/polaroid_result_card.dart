import 'dart:io';

import 'package:material_ui/material_ui.dart';
import 'package:flutter/services.dart';
import 'package:screenshot/screenshot.dart';
import 'package:share_plus/share_plus.dart';

import '../models/item.dart';
import '../models/location.dart';
import '../utils/item_icon_helper.dart';

class PolaroidResultCard extends StatefulWidget {
  final Item item;
  final Location? location;
  final bool isFirstDiscovery;
  final VoidCallback onKeep;
  final VoidCallback onSell;

  const PolaroidResultCard({
    super.key,
    required this.item,
    required this.location,
    this.isFirstDiscovery = true,
    required this.onKeep,
    required this.onSell,
  });

  @override
  State<PolaroidResultCard> createState() => _PolaroidResultCardState();
}

class _PolaroidResultCardState extends State<PolaroidResultCard>
    with TickerProviderStateMixin {
  final ScreenshotController _screenshotController = ScreenshotController();
  late AnimationController _animController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _tiltAnimation;

  late AnimationController _exitController;
  late Animation<double> _exitScale;
  late Animation<double> _exitRotation;
  late Animation<double> _exitOpacity;

  bool _isSharing = false;
  bool _isExiting = false;
  bool _isSelling = false;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    _scaleAnimation = CurvedAnimation(
      parent: _animController,
      curve: Curves.elasticOut,
    );

    _tiltAnimation = Tween<double>(
      begin: -0.06,
      end: -0.02,
    ).animate(CurvedAnimation(parent: _animController, curve: Curves.easeOut));

    _exitController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 450),
    );

    _exitScale = Tween<double>(begin: 1.0, end: 0.02).animate(
      CurvedAnimation(parent: _exitController, curve: Curves.easeInBack),
    );

    _exitOpacity = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _exitController,
        curve: const Interval(0.5, 1.0, curve: Curves.easeOut),
      ),
    );

    _exitRotation = Tween<double>(begin: 0.0, end: 0.50).animate(
      CurvedAnimation(parent: _exitController, curve: Curves.easeInOut),
    );

    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    _exitController.dispose();
    super.dispose();
  }

  void _triggerKeep() {
    if (_isExiting) return;
    HapticFeedback.mediumImpact();

    setState(() {
      _isExiting = true;
      _isSelling = false;
    });

    _exitController.forward().then((_) {
      widget.onKeep();
    });
  }

  void _triggerSell() {
    if (_isExiting) return;
    HapticFeedback.mediumImpact();

    setState(() {
      _isExiting = true;
      _isSelling = true;
    });

    _exitController.forward().then((_) {
      widget.onSell();
    });
  }

  Future<void> _sharePolaroid() async {
    if (_isSharing) return;
    setState(() => _isSharing = true);

    try {
      final imageBytes = await _screenshotController.capture(pixelRatio: 2.0);

      if (imageBytes != null) {
        final tempDir = Directory.systemTemp;
        final file = File('${tempDir.path}/junk_fishing_${widget.item.id}.png');
        await file.writeAsBytes(imageBytes);

        await SharePlus.instance.share(
          ShareParams(
            files: [XFile(file.path)],
            text:
                'I just dredged up "${widget.item.name}" (${widget.item.rarityStars}) in Junk Fishing! ðŸŽ£ðŸ¤–',
          ),
        );
      }
    } catch (_) {
      // Sharing cancelled or unavailable
    } finally {
      if (mounted) setState(() => _isSharing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final item = widget.item;
    final rarityColor = getRarityColor(item.rarity);

    final media = MediaQuery.of(context);
    final screenHeight = media.size.height;
    final paddingTop = media.padding.top;

    // Calculate pixel flight destination: screen center -> top bar HUD chip
    final targetY = -(screenHeight * 0.5 - paddingTop - 28);
    final targetX = _isSelling ? -55.0 : 0.0;

    return AnimatedBuilder(
      animation: Listenable.merge([_animController, _exitController]),
      builder: (context, child) {
        double currentScale = _scaleAnimation.value;
        double currentRotation = _tiltAnimation.value;
        double opacity = 1.0;
        Offset translation = Offset.zero;

        if (_isExiting) {
          final t = _exitController.value;
          currentScale *= _exitScale.value;
          currentRotation += _exitRotation.value * (_isSelling ? 1.0 : -1.0);
          opacity = _exitOpacity.value;
          translation = Offset(targetX * t, targetY * t);
        }

        return Opacity(
          opacity: opacity,
          child: Transform.translate(
            offset: translation,
            child: Transform.scale(
              scale: currentScale,
              child: Transform.rotate(
                angle: currentRotation,
                child: Center(
                  child: SingleChildScrollView(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 16,
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Discovery Banner Tag (First Find vs Duplicate)
                          if (widget.isFirstDiscovery)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.amberAccent,
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: const [
                                  BoxShadow(
                                    color: Colors.black45,
                                    blurRadius: 8,
                                    offset: Offset(0, 3),
                                  ),
                                ],
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.auto_awesome,
                                    color: Colors.black87,
                                    size: 16,
                                  ),
                                  SizedBox(width: 6),
                                  Text(
                                    'NEW DISCOVERY!',
                                    style: TextStyle(
                                      color: Colors.black87,
                                      fontWeight: FontWeight.w900,
                                      fontSize: 13,
                                      letterSpacing: 1.5,
                                    ),
                                  ),
                                ],
                              ),
                            )
                          else
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 5,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white12,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: Colors.white24),
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.inventory_2_outlined,
                                    color: Colors.white70,
                                    size: 14,
                                  ),
                                  SizedBox(width: 6),
                                  Text(
                                    'LOGGED JUNK (DUPLICATE)',
                                    style: TextStyle(
                                      color: Colors.white70,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 11,
                                      letterSpacing: 1.2,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          const SizedBox(height: 12),

                          // Printable / Shareable Polaroid Frame
                          Screenshot(
                            controller: _screenshotController,
                            child: Container(
                              width: 320,
                              padding: const EdgeInsets.fromLTRB(
                                16,
                                16,
                                16,
                                24,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFAF7F2),
                                // Vintage photographic paper
                                borderRadius: BorderRadius.circular(6),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.65),
                                    blurRadius: 28,
                                    spreadRadius: 4,
                                    offset: const Offset(4, 12),
                                  ),
                                ],
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  // Inner Photo Aperture
                                  Container(
                                    height: 210,
                                    decoration: BoxDecoration(
                                      gradient: RadialGradient(
                                        center: Alignment.center,
                                        radius: 0.85,
                                        colors: [
                                          rarityColor.withValues(alpha: 0.35),
                                          const Color(0xFF161922),
                                          const Color(0xFF0F1117),
                                        ],
                                      ),
                                      borderRadius: BorderRadius.circular(4),
                                      border: Border.all(
                                        color: rarityColor.withValues(
                                          alpha: 0.5,
                                        ),
                                        width: 1.5,
                                      ),
                                    ),
                                    child: Stack(
                                      children: [
                                        // Ambient Rarity Glow
                                        Center(
                                          child: Container(
                                            width: 120,
                                            height: 120,
                                            decoration: BoxDecoration(
                                              shape: BoxShape.circle,
                                              boxShadow: [
                                                BoxShadow(
                                                  color: rarityColor.withValues(
                                                    alpha: 0.5,
                                                  ),
                                                  blurRadius: 40,
                                                  spreadRadius: 10,
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),

                                        // Item Graphic Icon
                                        Center(
                                          child: Hero(
                                            tag: 'item_${item.id}',
                                            child: Icon(
                                              getItemIconData(item.icon),
                                              size: 88,
                                              color: rarityColor,
                                            ),
                                          ),
                                        ),

                                        // Top right collection badge
                                        Positioned(
                                          top: 8,
                                          right: 8,
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 8,
                                              vertical: 4,
                                            ),
                                            decoration: BoxDecoration(
                                              color: Colors.black87,
                                              borderRadius:
                                                  BorderRadius.circular(10),
                                              border: Border.all(
                                                color: Colors.white24,
                                              ),
                                            ),
                                            child: Text(
                                              item.collectionTag,
                                              style: const TextStyle(
                                                color: Colors.white70,
                                                fontSize: 10,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ),
                                        ),

                                        // Bottom left location badge
                                        Positioned(
                                          bottom: 8,
                                          left: 8,
                                          child: Row(
                                            children: [
                                              const Icon(
                                                Icons.place,
                                                size: 12,
                                                color: Colors.white70,
                                              ),
                                              const SizedBox(width: 3),
                                              Text(
                                                widget.location?.name ??
                                                    'Rusty Scrapyard',
                                                style: const TextStyle(
                                                  color: Colors.white70,
                                                  fontSize: 10,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),

                                  const SizedBox(height: 14),

                                  // Polaroid handwritten-style Title & Stars
                                  Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Expanded(
                                        child: Text(
                                          item.name,
                                          style: const TextStyle(
                                            fontFamily: 'serif',
                                            fontSize: 19,
                                            fontWeight: FontWeight.bold,
                                            color: Color(0xFF1E2024),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        item.rarityStars,
                                        style: TextStyle(
                                          color: rarityColor,
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),

                                  const SizedBox(height: 8),

                                  // Flavor Text
                                  Text(
                                    'â€œ${item.flavorText}â€',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontStyle: FontStyle.italic,
                                      color: Color(0xFF555555),
                                      height: 1.35,
                                    ),
                                  ),

                                  const SizedBox(height: 12),

                                  // Estimated Sell Value Stamp
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Row(
                                        children: [
                                          const Icon(
                                            Icons.monetization_on,
                                            color: Colors.amber,
                                            size: 18,
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            'Est. Value: ${item.estimatedValue}',
                                            style: const TextStyle(
                                              fontSize: 13,
                                              fontWeight: FontWeight.bold,
                                              color: Color(0xFF2C3E50),
                                            ),
                                          ),
                                        ],
                                      ),
                                      Text(
                                        '${item.weightKg.toStringAsFixed(2)} kg',
                                        style: const TextStyle(
                                          fontSize: 12,
                                          color: Color(0xFF888888),
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),

                          const SizedBox(height: 20),

                          // Action Buttons Row: Keep, Sell, Share
                          if (!_isExiting)
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                // KEEP BUTTON
                                ElevatedButton.icon(
                                  onPressed: _triggerKeep,
                                  icon: const Icon(Icons.inventory_2, size: 18),
                                  label: const Text('KEEP'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF2A9D8F),
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 18,
                                      vertical: 12,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    elevation: 4,
                                  ),
                                ),
                                const SizedBox(width: 10),

                                // SELL BUTTON
                                ElevatedButton.icon(
                                  onPressed: _triggerSell,
                                  icon: const Icon(
                                    Icons.currency_exchange,
                                    size: 18,
                                  ),
                                  label: Text('SELL (+${item.estimatedValue})'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFFE76F51),
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 12,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    elevation: 4,
                                  ),
                                ),
                                const SizedBox(width: 10),

                                // SHARE BUTTON
                                IconButton.filled(
                                  onPressed: _sharePolaroid,
                                  icon: _isSharing
                                      ? const SizedBox(
                                          width: 18,
                                          height: 18,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            color: Colors.white,
                                          ),
                                        )
                                      : const Icon(Icons.share, size: 20),
                                  style: IconButton.styleFrom(
                                    backgroundColor: const Color(0xFF264653),
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.all(12),
                                  ),
                                ),
                              ],
                            )
                          else
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 20,
                                vertical: 10,
                              ),
                              decoration: BoxDecoration(
                                color: _isSelling
                                    ? Colors.amber
                                    : const Color(0xFF2A9D8F),
                                borderRadius: BorderRadius.circular(20),
                                boxShadow: [
                                  BoxShadow(
                                    color: _isSelling
                                        ? Colors.orangeAccent
                                        : Colors.tealAccent,
                                    blurRadius: 18,
                                    spreadRadius: 3,
                                  ),
                                ],
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    _isSelling
                                        ? Icons.monetization_on
                                        : Icons.inventory_2,
                                    color: _isSelling
                                        ? Colors.black87
                                        : Colors.white,
                                    size: 22,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    _isSelling
                                        ? '+${item.estimatedValue} COINS!'
                                        : 'SAVED TO INVENTORY!',
                                    style: TextStyle(
                                      color: _isSelling
                                          ? Colors.black87
                                          : Colors.white,
                                      fontWeight: FontWeight.w900,
                                      fontSize: 14,
                                      letterSpacing: 1.2,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
