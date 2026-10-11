import 'package:flutter/material.dart';
import '../models/player_state.dart';
import '../models/location.dart';

enum NavAction {
  fish,
  inventory,
  collections,
  map,
  settings,
}

class CollapsibleNavMenu extends StatelessWidget {
  final bool isVisible;
  final bool isCollapsed;
  final PlayerState playerState;
  final Location? currentLocation;
  final ValueChanged<NavAction> onAction;
  final VoidCallback onToggleCollapse;
  final VoidCallback onBuyBait;
  final VoidCallback onUpgradeStorage;

  const CollapsibleNavMenu({
    super.key,
    required this.isVisible,
    required this.isCollapsed,
    required this.playerState,
    required this.currentLocation,
    required this.onAction,
    required this.onToggleCollapse,
    required this.onBuyBait,
    required this.onUpgradeStorage,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // 1. Top HUD Bar (Money, Bait, Storage, Location)
        Positioned(
          top: MediaQuery.of(context).padding.top + 8,
          left: 12,
          right: 12,
          child: Row(
            children: [
              // Current Location Badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.75),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.white24),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.place, color: Colors.tealAccent, size: 16),
                    const SizedBox(width: 6),
                    Text(
                      currentLocation?.name ?? 'Unknown Pier',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),

              const Spacer(),

              // Player Stats HUD (Money, Bait, Bag)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.8),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: Colors.white24),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Money
                    _buildStatChip(
                      icon: Icons.monetization_on,
                      iconColor: Colors.amber,
                      label: '${playerState.money}',
                    ),
                    const SizedBox(width: 8),

                    // Bait
                    GestureDetector(
                      onTap: onBuyBait,
                      child: _buildStatChip(
                        icon: Icons.bug_report,
                        iconColor: Colors.lightGreenAccent,
                        label: '${playerState.baitCount}',
                        actionIcon: Icons.add_circle,
                      ),
                    ),
                    const SizedBox(width: 8),

                    // Storage
                    GestureDetector(
                      onTap: onUpgradeStorage,
                      child: _buildStatChip(
                        icon: Icons.backpack,
                        iconColor: Colors.orangeAccent,
                        label: '${playerState.inventory.length}/${playerState.storageLimit}',
                        actionIcon: Icons.upgrade,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        // 2. Sliding Left Navigation Menu
        AnimatedPositioned(
          duration: const Duration(milliseconds: 350),
          curve: Curves.easeInOutCubic,
          top: MediaQuery.of(context).size.height * 0.18,
          left: isVisible ? (isCollapsed ? -175 : 12) : -220,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Menu Card
              Container(
                width: 175,
                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                decoration: BoxDecoration(
                  color: const Color(0xEE161B22),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.white12, width: 1.5),
                  boxShadow: const [
                    BoxShadow(
                      color: Colors.black54,
                      blurRadius: 16,
                      offset: Offset(4, 6),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Brand / Title Header
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
                      child: Row(
                        children: [
                          const Icon(Icons.phishing, color: Colors.cyanAccent, size: 20),
                          const SizedBox(width: 8),
                          Text(
                            'JUNK FISHING',
                            style: TextStyle(
                              color: Colors.cyan.shade200,
                              fontWeight: FontWeight.w900,
                              fontSize: 12,
                              letterSpacing: 1.2,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Divider(color: Colors.white12, height: 16),

                    // 1. FISH ACTION (Primary)
                    _buildMenuItem(
                      icon: Icons.sports_esports,
                      label: 'Cast Line',
                      badge: 'PLAY',
                      isHighlight: true,
                      onTap: () => onAction(NavAction.fish),
                    ),
                    const SizedBox(height: 6),

                    // 2. INVENTORY
                    _buildMenuItem(
                      icon: Icons.inventory_2_outlined,
                      label: 'Inventory',
                      badge: '${playerState.inventory.length}',
                      onTap: () => onAction(NavAction.inventory),
                    ),
                    const SizedBox(height: 6),

                    // 3. COLLECTIONS
                    _buildMenuItem(
                      icon: Icons.auto_stories_outlined,
                      label: 'Collections',
                      onTap: () => onAction(NavAction.collections),
                    ),
                    const SizedBox(height: 6),

                    // 4. MAP
                    _buildMenuItem(
                      icon: Icons.map_outlined,
                      label: 'Map / Locations',
                      onTap: () => onAction(NavAction.map),
                    ),
                    const SizedBox(height: 6),

                    // 5. SETTINGS
                    _buildMenuItem(
                      icon: Icons.tune,
                      label: 'Settings',
                      onTap: () => onAction(NavAction.settings),
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 4),

              // Collapse Toggle Handle
              if (isVisible)
                GestureDetector(
                  onTap: onToggleCollapse,
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xEE161B22),
                      borderRadius: const BorderRadius.only(
                        topRight: Radius.circular(12),
                        bottomRight: Radius.circular(12),
                      ),
                      border: Border.all(color: Colors.white12),
                    ),
                    child: Icon(
                      isCollapsed ? Icons.chevron_right : Icons.chevron_left,
                      color: Colors.white70,
                      size: 20,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStatChip({
    required IconData icon,
    required Color iconColor,
    required String label,
    IconData? actionIcon,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: iconColor, size: 16),
          const SizedBox(width: 4),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
          if (actionIcon != null) ...[
            const SizedBox(width: 4),
            Icon(actionIcon, color: Colors.white54, size: 14),
          ],
        ],
      ),
    );
  }

  Widget _buildMenuItem({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    String? badge,
    bool isHighlight = false,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
          decoration: BoxDecoration(
            color: isHighlight ? const Color(0xFF2A9D8F) : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Icon(
                icon,
                color: isHighlight ? Colors.white : Colors.white70,
                size: 18,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    color: isHighlight ? Colors.white : Colors.white,
                    fontWeight: isHighlight ? FontWeight.bold : FontWeight.w500,
                    fontSize: 13,
                  ),
                ),
              ),
              if (badge != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: isHighlight
                        ? Colors.black26
                        : Colors.white.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    badge,
                    style: TextStyle(
                      color: isHighlight ? Colors.amberAccent : Colors.white70,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
