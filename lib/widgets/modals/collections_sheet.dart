import 'package:material_ui/material_ui.dart';

import '../../services/game_data_service.dart';
import '../../utils/item_icon_helper.dart';
import 'game_bottom_sheet.dart';

class CollectionsSheet extends StatelessWidget {
  final GameDataService gameService;
  final VoidCallback onStateChanged;

  const CollectionsSheet({
    super.key,
    required this.gameService,
    required this.onStateChanged,
  });

  @override
  Widget build(BuildContext context) {
    final collections = gameService.collections;
    final playerState = gameService.playerState;

    return GameBottomSheet(
      heightFactor: 0.85,
      titleIcon: Icons.auto_stories,
      titleIconColor: Colors.cyanAccent,
      title: 'Absurd Collections',
      trailing: Text(
        '${playerState.claimedCollectionIds.length}/${collections.length} Claimed',
        style: const TextStyle(color: Colors.white60, fontSize: 12),
      ),
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: collections.length,
        itemBuilder: (context, index) {
          final col = collections[index];
          final isClaimed = playerState.claimedCollectionIds.contains(col.id);
          final status = col.getStatus(playerState.discoveredItemIds);
          final isComplete = status.isComplete;
          final progress = status.progress;
          final discoveredCount = status.found;

          return Container(
            margin: const EdgeInsets.only(bottom: 16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF1E2430),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isComplete
                    ? Colors.amberAccent.withValues(alpha: 0.5)
                    : Colors.white12,
                width: 1.5,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        col.name,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: isClaimed
                            ? Colors.green.withValues(alpha: 0.2)
                            : (isComplete
                                  ? Colors.amber.withValues(alpha: 0.2)
                                  : Colors.black38),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.monetization_on,
                            color: Colors.amber,
                            size: 14,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            isClaimed ? 'CLAIMED' : '+${col.rewardMoney}',
                            style: TextStyle(
                              color: isClaimed
                                  ? Colors.greenAccent
                                  : Colors.amberAccent,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  col.description,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.6),
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 12),

                // Progress Bar
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: progress,
                    backgroundColor: Colors.white12,
                    color: isComplete ? Colors.amberAccent : Colors.cyanAccent,
                    minHeight: 6,
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '$discoveredCount of ${col.itemIds.length} found',
                      style: const TextStyle(
                        color: Colors.white54,
                        fontSize: 11,
                      ),
                    ),
                    Text(
                      '${(progress * 100).toInt()}%',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Item Badges Grid
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: col.itemIds.map((itemId) {
                    final item = gameService.getItemById(itemId);
                    final isFound = playerState.discoveredItemIds.contains(
                      itemId,
                    );
                    final rarityColor = item != null
                        ? getRarityColor(item.rarity)
                        : Colors.grey;

                    return Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        color: isFound
                            ? const Color(0xFF263040)
                            : Colors.black38,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: isFound ? rarityColor : Colors.white10,
                          width: 1.5,
                        ),
                      ),
                      child: Center(
                        child: isFound
                            ? Icon(
                                getItemIconData(item?.icon ?? 'category'),
                                size: 26,
                                color: rarityColor,
                              )
                            : const Icon(
                                Icons.help_outline,
                                size: 20,
                                color: Colors.white24,
                              ),
                      ),
                    );
                  }).toList(),
                ),

                if (isComplete && !isClaimed) ...[
                  const SizedBox(height: 14),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () async {
                        await gameService.claimCollectionReward(col.id);
                        onStateChanged();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.amberAccent,
                        foregroundColor: Colors.black,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: Text(
                        'CLAIM ðŸª™ ${col.rewardMoney} REWARD',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }
}
