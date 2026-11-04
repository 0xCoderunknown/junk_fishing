import 'package:flutter/material.dart';

import '../models/location.dart';
import '../models/player_state.dart';

enum NavAction { fish, inventory, market, collections, map, settings }

class CollapsibleNavMenu extends StatelessWidget {
  final bool isVisible;
  final bool isCollapsed;
  final PlayerState playerState;
  final Location? currentLocation;
  final ValueChanged<NavAction> onAction;
  final VoidCallback onToggleCollapse;

  const CollapsibleNavMenu({
    super.key,
    required this.isVisible,
    required this.isCollapsed,
    required this.playerState,
    this.currentLocation,
    required this.onAction,
    required this.onToggleCollapse,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // 1. Top HUD Bar (Only Cash, Inventory, Bait)
        Positioned(
          top: MediaQuery.of(context).padding.top + 8,
          left: 16,
          right: 16,
          child: Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.85),
                borderRadius: BorderRadius.circular(28),
                border: Border.all(color: Colors.white24, width: 1.5),
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black54,
                    blurRadius: 14,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Cash -> tap opens Market
                  GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () => onAction(NavAction.market),
                    child: _buildStatChip(
                      icon: Icons.monetization_on,
                      iconColor: Colors.amber,
                      label: '${playerState.money}',
                    ),
                  ),
                  const SizedBox(width: 12),

                  // Inventory -> tap opens Inventory
                  GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () => onAction(NavAction.inventory),
                    child: _buildStatChip(
                      icon: Icons.backpack,
                      iconColor: Colors.orangeAccent,
                      label:
                          '${playerState.inventory.length}/${playerState.storageLimit}',
                    ),
                  ),
                  const SizedBox(width: 12),

                  // Bait -> tap opens Market
                  GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () => onAction(NavAction.market),
                    child: _buildStatChip(
                      icon: Icons.bug_report,
                      iconColor: Colors.lightGreenAccent,
                      label: '${playerState.baitCount}',
                    ),
                  ),
                ],
              ),
            ),
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
                padding: const EdgeInsets.symmetric(
                  vertical: 12,
                  horizontal: 8,
                ),
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
                      padding: const EdgeInsets.symmetric(
                        vertical: 6,
                        horizontal: 8,
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.phishing,
                            color: Colors.cyanAccent,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'JUNK FISHING',
                            style: TextStyle(
                              color: Colors.cyan.shade200,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 1.5,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Divider(color: Colors.white12, thickness: 1),

                    _buildMenuItem(
                      icon: Icons.phishing,
                      label: 'Cast Line',
                      action: NavAction.fish,
                      highlight: true,
                    ),
                    _buildMenuItem(
                      icon: Icons.backpack,
                      label: 'Inventory',
                      action: NavAction.inventory,
                      badgeCount: playerState.inventory.length,
                    ),
                    _buildMenuItem(
                      icon: Icons.storefront,
                      label: 'Market',
                      action: NavAction.market,
                    ),
                    _buildMenuItem(
                      icon: Icons.collections_bookmark,
                      label: 'Collections',
                      action: NavAction.collections,
                    ),
                    _buildMenuItem(
                      icon: Icons.map,
                      label: 'Locations',
                      action: NavAction.map,
                    ),
                    _buildMenuItem(
                      icon: Icons.settings,
                      label: 'Settings',
                      action: NavAction.settings,
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 4),

              // Drawer Toggle Handle Button
              GestureDetector(
                onTap: onToggleCollapse,
                child: Container(
                  width: 32,
                  height: 48,
                  decoration: BoxDecoration(
                    color: const Color(0xEE161B22),
                    borderRadius: const BorderRadius.only(
                      topRight: Radius.circular(12),
                      bottomRight: Radius.circular(12),
                    ),
                    border: Border.all(color: Colors.white12, width: 1.5),
                  ),
                  child: Center(
                    child: Icon(
                      isCollapsed ? Icons.chevron_right : Icons.chevron_left,
                      color: Colors.cyanAccent,
                      size: 20,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMenuItem({
    required IconData icon,
    required String label,
    required NavAction action,
    bool highlight = false,
    int? badgeCount,
  }) {
    return ListTile(
      dense: true,
      visualDensity: VisualDensity.compact,
      contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 0),
      leading: Icon(
        icon,
        color: highlight ? Colors.amberAccent : Colors.white70,
        size: 18,
      ),
      title: Text(
        label,
        style: TextStyle(
          color: highlight ? Colors.amberAccent : Colors.white,
          fontWeight: highlight ? FontWeight.bold : FontWeight.normal,
          fontSize: 12,
        ),
      ),
      trailing: badgeCount != null && badgeCount > 0
          ? Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.cyanAccent.shade700,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '$badgeCount',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            )
          : null,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      onTap: () => onAction(action),
    );
  }

  Widget _buildStatChip({
    required IconData icon,
    required Color iconColor,
    required String label,
    IconData? actionIcon,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: iconColor, size: 18),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w800,
              fontSize: 13,
              letterSpacing: 0.5,
            ),
          ),
          if (actionIcon != null) ...[
            const SizedBox(width: 4),
            Icon(actionIcon, color: iconColor, size: 14),
          ],
        ],
      ),
    );
  }
}
