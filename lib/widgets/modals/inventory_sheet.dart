import 'package:material_ui/material_ui.dart';
import 'package:flutter/services.dart';

import '../../services/game_data_service.dart';
import '../../utils/item_icon_helper.dart';
import 'game_bottom_sheet.dart';

class InventorySheet extends StatefulWidget {
  final GameDataService gameService;
  final VoidCallback onStateChanged;

  const InventorySheet({
    super.key,
    required this.gameService,
    required this.onStateChanged,
  });

  @override
  State<InventorySheet> createState() => _InventorySheetState();
}

class _InventorySheetState extends State<InventorySheet> {
  int _selectedFilterRarity = 0; // 0 = all

  Future<void> _handleSellAll() async {
    final gained = await widget.gameService.sellAllScrap();
    if (!mounted) return;
    if (gained > 0) {
      HapticFeedback.mediumImpact();
      widget.onStateChanged();
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final inventory = widget.gameService.playerState.inventory;
    final storageLimit = widget.gameService.playerState.storageLimit;
    final filtered = _selectedFilterRarity == 0
        ? inventory
        : inventory
              .where((item) => item.rarity == _selectedFilterRarity)
              .toList();

    return GameBottomSheet(
      heightFactor: 0.82,
      titleIcon: Icons.inventory_2,
      titleIconColor: Colors.orangeAccent,
      title: 'Scrap Inventory (${inventory.length}/$storageLimit)',
      trailing: inventory.isNotEmpty
          ? TextButton.icon(
              onPressed: _handleSellAll,
              icon: const Icon(Icons.sell, size: 16),
              label: const Text('Sell All'),
              style: TextButton.styleFrom(foregroundColor: Colors.amberAccent),
            )
          : null,
      child: Column(
        children: [
          // Rarity Filter Pills
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                _buildFilterChip('All', 0),
                _buildFilterChip('â˜… Common', 1),
                _buildFilterChip('â˜…â˜… Uncommon', 2),
                _buildFilterChip('â˜…â˜…â˜… Rare', 3),
                _buildFilterChip('â˜…â˜…â˜…â˜… Epic', 4),
                _buildFilterChip('â˜…â˜…â˜…â˜…â˜… Legendary', 5),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Inventory Grid
          Expanded(
            child: filtered.isEmpty
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.inbox,
                          size: 48,
                          color: Colors.white.withValues(alpha: 0.3),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          inventory.isEmpty
                              ? 'Your tackle bag is empty.'
                              : 'No scrap matching this filter.',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.5),
                          ),
                        ),
                      ],
                    ),
                  )
                : GridView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 3,
                          childAspectRatio: 0.72,
                          crossAxisSpacing: 10,
                          mainAxisSpacing: 10,
                        ),
                    itemCount: filtered.length,
                    itemBuilder: (context, index) {
                      final item = filtered[index];
                      final rarityColor = getRarityColor(item.rarity);

                      return Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1E2430),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: rarityColor.withValues(alpha: 0.5),
                            width: 1.2,
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  item.rarityStars,
                                  style: TextStyle(
                                    color: rarityColor,
                                    fontSize: 9,
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 4,
                                    vertical: 1,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.black45,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Text(
                                        'ðŸª™',
                                        style: TextStyle(fontSize: 8),
                                      ),
                                      const SizedBox(width: 2),
                                      Text(
                                        '${item.estimatedValue}',
                                        style: const TextStyle(
                                          color: Colors.amberAccent,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 9,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            Expanded(
                              child: Center(
                                child: Icon(
                                  getItemIconData(item.icon),
                                  size: 40,
                                  color: rarityColor,
                                ),
                              ),
                            ),
                            Text(
                              item.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                            const SizedBox(height: 6),
                            SizedBox(
                              width: double.infinity,
                              height: 28,
                              child: OutlinedButton(
                                onPressed: () async {
                                  await widget.gameService.sellItem(
                                    item,
                                    fromInventory: true,
                                  );
                                  if (!context.mounted) return;
                                  HapticFeedback.lightImpact();
                                  widget.onStateChanged();
                                  setState(() {});
                                },
                                style: OutlinedButton.styleFrom(
                                  padding: EdgeInsets.zero,
                                  side: BorderSide(
                                    color: Colors.redAccent.withValues(
                                      alpha: 0.6,
                                    ),
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                                child: const Text(
                                  'Sell',
                                  style: TextStyle(
                                    color: Colors.redAccent,
                                    fontSize: 11,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, int rarity) {
    final isSelected = _selectedFilterRarity == rarity;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (selected) {
          if (selected) setState(() => _selectedFilterRarity = rarity);
        },
        selectedColor: const Color(0xFF2A9D8F),
        backgroundColor: const Color(0xFF1E2430),
        labelStyle: TextStyle(
          color: isSelected ? Colors.white : Colors.white70,
          fontSize: 12,
        ),
      ),
    );
  }
}
