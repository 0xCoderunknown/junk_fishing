import 'package:flutter/material.dart';
import '../../models/item.dart';
import '../../models/player_state.dart';
import '../../services/game_data_service.dart';
import '../../utils/item_icon_helper.dart';

class InventorySheet extends StatefulWidget {
  final PlayerState playerState;
  final GameDataService gameService;
  final VoidCallback onStateChanged;

  const InventorySheet({
    super.key,
    required this.playerState,
    required this.gameService,
    required this.onStateChanged,
  });

  @override
  State<InventorySheet> createState() => _InventorySheetState();
}

class _InventorySheetState extends State<InventorySheet> {
  int _selectedFilterRarity = 0; // 0 = all

  @override
  Widget build(BuildContext context) {
    final inventory = widget.gameService.playerState.inventory;
    final filtered = _selectedFilterRarity == 0
        ? inventory
        : inventory.where((item) => item.rarity == _selectedFilterRarity).toList();

    return Container(
      height: MediaQuery.of(context).size.height * 0.82,
      decoration: const BoxDecoration(
        color: Color(0xFF131720),
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          // Drag handle
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                const Icon(Icons.inventory_2, color: Colors.orangeAccent),
                const SizedBox(width: 10),
                Text(
                  'Scrap Inventory (${inventory.length}/${widget.gameService.playerState.storageLimit})',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                if (inventory.isNotEmpty)
                  TextButton.icon(
                    onPressed: () async {
                      int totalGained = 0;
                      for (final item in List<Item>.from(inventory)) {
                        totalGained += await widget.gameService.sellItem(item, fromInventory: true);
                      }
                      widget.onStateChanged();
                      if (context.mounted) {
                        setState(() {});
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Sold all scrap for 🪙 $totalGained coins!'),
                            backgroundColor: Colors.teal,
                          ),
                        );
                      }
                    },
                    icon: const Icon(Icons.sell, size: 16),
                    label: const Text('Sell All'),
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.amberAccent,
                    ),
                  ),
              ],
            ),
          ),

          // Rarity Filter Pills
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                _buildFilterChip('All', 0),
                _buildFilterChip('★ Common', 1),
                _buildFilterChip('★★ Uncommon', 2),
                _buildFilterChip('★★★ Rare', 3),
                _buildFilterChip('★★★★ Epic', 4),
                _buildFilterChip('★★★★★ Legendary', 5),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Grid of Inventory Items
          Expanded(
            child: filtered.isEmpty
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.inventory_2_outlined, size: 56, color: Colors.white.withValues(alpha: 0.2)),
                        const SizedBox(height: 12),
                        Text(
                          inventory.isEmpty ? 'Your junk pouch is empty!\nGo cast a line.' : 'No items match filter.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.white.withValues(alpha: 0.5)),
                        ),
                      ],
                    ),
                  )
                : GridView.builder(
                    padding: const EdgeInsets.all(16),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      childAspectRatio: 0.9,
                    ),
                    itemCount: filtered.length,
                    itemBuilder: (context, index) {
                      final item = filtered[index];
                      final rarityColor = getRarityColor(item.rarity);

                      return Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1E2430),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: rarityColor.withValues(alpha: 0.4), width: 1.5),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  item.rarityStars,
                                  style: TextStyle(color: rarityColor, fontSize: 11),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: Colors.black45,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Row(
                                    children: [
                                      const Icon(Icons.monetization_on, color: Colors.amber, size: 12),
                                      const SizedBox(width: 2),
                                      Text(
                                        '${item.estimatedValue}',
                                        style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
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
                                  final earned = await widget.gameService.sellItem(item, fromInventory: true);
                                  widget.onStateChanged();
                                  if (context.mounted) {
                                    setState(() {});
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text('Sold "${item.name}" for 🪙 $earned!'),
                                        duration: const Duration(seconds: 1),
                                      ),
                                    );
                                  }
                                },
                                style: OutlinedButton.styleFrom(
                                  padding: EdgeInsets.zero,
                                  side: BorderSide(color: Colors.redAccent.withValues(alpha: 0.6)),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                ),
                                child: const Text(
                                  'Sell',
                                  style: TextStyle(color: Colors.redAccent, fontSize: 11),
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
