import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../services/game_data_service.dart';
import 'game_bottom_sheet.dart';

class MapSheet extends StatefulWidget {
  final GameDataService gameService;
  final VoidCallback onLocationSelected;

  const MapSheet({
    super.key,
    required this.gameService,
    required this.onLocationSelected,
  });

  @override
  State<MapSheet> createState() => _MapSheetState();
}

class _MapSheetState extends State<MapSheet> {
  static const int _unlockCost = 350;

  @override
  Widget build(BuildContext context) {
    final locations = widget.gameService.locations;
    final currentLocId = widget.gameService.playerState.currentLocationId;
    final playerMoney = widget.gameService.playerState.money;

    return GameBottomSheet(
      heightFactor: 0.70,
      titleIcon: Icons.map,
      titleIconColor: Colors.tealAccent,
      title: 'Fishing Spots',
      trailing: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.black45,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.amber.withValues(alpha: 0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('🪙 ', style: TextStyle(fontSize: 12)),
            Text(
              '$playerMoney',
              style: const TextStyle(
                color: Colors.amberAccent,
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
      child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: locations.length,
              itemBuilder: (context, index) {
                final loc = locations[index];
                final isCurrent = loc.id == currentLocId;
                final isUnlocked = widget.gameService.isLocationUnlocked(
                  loc.id,
                );

                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: isCurrent
                        ? const Color(0xFF20323F)
                        : const Color(0xFF1E2430),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isCurrent ? Colors.tealAccent : Colors.white12,
                      width: isCurrent ? 1.5 : 1.0,
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 46,
                        height: 46,
                        decoration: BoxDecoration(
                          color: Colors.teal.withValues(alpha: 0.2),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          isUnlocked ? Icons.waves : Icons.lock,
                          color: isUnlocked
                              ? Colors.tealAccent
                              : Colors.white38,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              loc.name,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              loc.description,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.6),
                                fontSize: 11,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'Difficulty: ${loc.difficulty.toStringAsFixed(1)}x • ${loc.availableItemIds.length} items',
                              style: TextStyle(
                                color: Colors.teal.shade200,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      if (isCurrent)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.tealAccent,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Text(
                            'HERE',
                            style: TextStyle(
                              color: Colors.black87,
                              fontWeight: FontWeight.bold,
                              fontSize: 11,
                            ),
                          ),
                        )
                      else if (isUnlocked)
                        ElevatedButton(
                          onPressed: () async {
                            await widget.gameService.selectLocation(loc.id);
                            widget.onLocationSelected();
                            if (context.mounted) Navigator.pop(context);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF2A9D8F),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 8,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text(
                            'TRAVEL',
                            style: TextStyle(fontSize: 11),
                          ),
                        )
                      else
                        ElevatedButton(
                          onPressed: playerMoney >= _unlockCost
                              ? () async {
                                  final success = await widget.gameService
                                      .unlockLocation(
                                        loc.id,
                                        cost: _unlockCost,
                                      );
                                  if (success) {
                                    HapticFeedback.mediumImpact();
                                    setState(() {});
                                    widget.onLocationSelected();
                                  }
                                }
                              : null,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.amber.shade700,
                            foregroundColor: Colors.black,
                            disabledBackgroundColor: Colors.white10,
                            disabledForegroundColor: Colors.white38,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: Text(
                            '🪙 $_unlockCost',
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                    ],
                  ),
                );
              },
            ),
    );
  }
}
