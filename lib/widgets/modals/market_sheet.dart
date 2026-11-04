import 'package:flutter/material.dart';
import '../../models/item.dart';
import '../../services/game_data_service.dart';

class MarketSheet extends StatefulWidget {
  final GameDataService gameService;
  final VoidCallback onStateChanged;

  const MarketSheet({
    super.key,
    required this.gameService,
    required this.onStateChanged,
  });

  @override
  State<MarketSheet> createState() => _MarketSheetState();
}

class _MarketSheetState extends State<MarketSheet> {
  Future<void> _handleBuyBait(int amount, int cost) async {
    final success = await widget.gameService.buyBait(amount: amount, cost: cost);
    if (!mounted) return;

    if (success) {
      widget.onStateChanged();
      setState(() {});
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Purchased $amount bait for 🪙 $cost!'),
          backgroundColor: const Color(0xFF2A9D8F),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Need 🪙 $cost coins to purchase $amount bait.'),
          backgroundColor: Colors.redAccent.shade700,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _handleUpgradeStorage(int extraSlots, int cost) async {
    final success = await widget.gameService.upgradeStorage(
      extraSlots: extraSlots,
      cost: cost,
    );
    if (!mounted) return;

    if (success) {
      widget.onStateChanged();
      setState(() {});
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Backpack upgraded to ${widget.gameService.playerState.storageLimit} slots!',
          ),
          backgroundColor: const Color(0xFF2A9D8F),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Need 🪙 $cost coins to expand storage.'),
          backgroundColor: Colors.redAccent.shade700,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _handleSellAllScrap() async {
    final inventory = List<Item>.from(widget.gameService.playerState.inventory);
    if (inventory.isEmpty) return;

    int totalGained = 0;
    for (final item in inventory) {
      totalGained += await widget.gameService.sellItem(item, fromInventory: true);
    }

    if (!mounted) return;
    widget.onStateChanged();
    setState(() {});
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Sold all scrap for 🪙 $totalGained coins!'),
        backgroundColor: Colors.teal,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final playerState = widget.gameService.playerState;
    final inventory = playerState.inventory;
    final scrapTotalValue =
        inventory.fold<int>(0, (sum, item) => sum + item.estimatedValue);

    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
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
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                const Icon(Icons.storefront, color: Colors.amberAccent, size: 24),
                const SizedBox(width: 10),
                const Text(
                  'Harbor Market',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.white54),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
          ),

          // Player Balances Capsule
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0xFF1B2230),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildBalanceChip(
                  icon: Icons.monetization_on,
                  color: Colors.amber,
                  label: 'Coins',
                  value: '${playerState.money}',
                ),
                Container(width: 1, height: 28, color: Colors.white12),
                _buildBalanceChip(
                  icon: Icons.backpack,
                  color: Colors.orangeAccent,
                  label: 'Storage',
                  value: '${inventory.length}/${playerState.storageLimit}',
                ),
                Container(width: 1, height: 28, color: Colors.white12),
                _buildBalanceChip(
                  icon: Icons.bug_report,
                  color: Colors.lightGreenAccent,
                  label: 'Bait',
                  value: '${playerState.baitCount}',
                ),
              ],
            ),
          ),

          const SizedBox(height: 8),

          // Main Market Scrollable Items
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              children: [
                // SECTION 1: BAIT SUPPLIES
                _buildSectionHeader(
                  title: 'Bait Supplies',
                  icon: Icons.bug_report,
                  color: Colors.lightGreenAccent,
                ),
                _buildMarketTile(
                  title: 'Starter Worms',
                  subtitle: '+5 fishing bait for quick catches',
                  badgeText: null,
                  cost: 50,
                  canAfford: playerState.money >= 50,
                  onBuy: () => _handleBuyBait(5, 50),
                ),
                _buildMarketTile(
                  title: 'Angler Bundle',
                  subtitle: '+20 fishing bait (10% discount)',
                  badgeText: 'POPULAR',
                  badgeColor: Colors.amber,
                  cost: 180,
                  canAfford: playerState.money >= 180,
                  onBuy: () => _handleBuyBait(20, 180),
                ),
                _buildMarketTile(
                  title: 'Commercial Cask',
                  subtitle: '+50 fishing bait (20% bulk savings)',
                  badgeText: 'BEST VALUE',
                  badgeColor: Colors.tealAccent,
                  cost: 400,
                  canAfford: playerState.money >= 400,
                  onBuy: () => _handleBuyBait(50, 400),
                ),

                const SizedBox(height: 18),

                // SECTION 2: STORAGE EXPANSION
                _buildSectionHeader(
                  title: 'Backpack Upgrades',
                  icon: Icons.backpack,
                  color: Colors.orangeAccent,
                ),
                _buildMarketTile(
                  title: 'Expand Tackle Bag',
                  subtitle: '+5 inventory capacity (Now: ${playerState.storageLimit})',
                  badgeText: null,
                  cost: 150,
                  canAfford: playerState.money >= 150,
                  onBuy: () => _handleUpgradeStorage(5, 150),
                ),
                _buildMarketTile(
                  title: 'Hauler Rucksack',
                  subtitle: '+15 inventory capacity',
                  badgeText: 'EXPANSION',
                  badgeColor: Colors.deepOrangeAccent,
                  cost: 400,
                  canAfford: playerState.money >= 400,
                  onBuy: () => _handleUpgradeStorage(15, 400),
                ),

                const SizedBox(height: 18),

                // SECTION 3: SCRAP DEALER
                _buildSectionHeader(
                  title: 'Scrap Pawn Dealer',
                  icon: Icons.sell,
                  color: Colors.cyanAccent,
                ),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1B2230),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.white12),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.cyan.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.recycling, color: Colors.cyanAccent, size: 24),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Quick Sell All Scrap',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              inventory.isEmpty
                                  ? 'Bag is currently empty'
                                  : '${inventory.length} items worth 🪙 $scrapTotalValue coins',
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.6),
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                      ElevatedButton(
                        onPressed: inventory.isEmpty ? null : _handleSellAllScrap,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.tealAccent.shade700,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text('Sell All', style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBalanceChip({
    required IconData icon,
    required Color color,
    required String label,
    required String value,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 14),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.6),
                fontSize: 11,
              ),
            ),
          ],
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
      ],
    );
  }

  Widget _buildSectionHeader({
    required String title,
    required IconData icon,
    required Color color,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, top: 4),
      child: Row(
        children: [
          Icon(icon, color: color, size: 16),
          const SizedBox(width: 6),
          Text(
            title.toUpperCase(),
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.0,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMarketTile({
    required String title,
    required String subtitle,
    required String? badgeText,
    Color badgeColor = Colors.amber,
    required int cost,
    required bool canAfford,
    required VoidCallback onBuy,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF1B2230),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white10),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    if (badgeText != null) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: badgeColor.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: badgeColor, width: 0.8),
                        ),
                        child: Text(
                          badgeText,
                          style: TextStyle(
                            color: badgeColor,
                            fontSize: 9,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.6),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          ElevatedButton(
            onPressed: canAfford ? onBuy : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: canAfford ? const Color(0xFF2A9D8F) : Colors.white10,
              foregroundColor: canAfford ? Colors.white : Colors.white38,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.monetization_on, size: 14, color: Colors.amber),
                const SizedBox(width: 4),
                Text(
                  '$cost',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
