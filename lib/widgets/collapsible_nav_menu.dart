import 'package:flutter/material.dart';

import '../models/location.dart';
import '../models/player_state.dart';

enum NavAction { fish, inventory, market, collections, map, settings }

class CollapsibleNavMenu extends StatefulWidget {
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
  State<CollapsibleNavMenu> createState() => _CollapsibleNavMenuState();
}

class _CollapsibleNavMenuState extends State<CollapsibleNavMenu>
    with SingleTickerProviderStateMixin {
  late AnimationController _badgeController;
  late Animation<double> _badgeScale;
  late Animation<double> _badgeOpacity;
  late Animation<Offset> _badgeOffset;

  String? _badgeText;
  bool _badgeIsCoins = true;

  @override
  void initState() {
    super.initState();
    _badgeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _badgeScale = Tween<double>(begin: 0.6, end: 1.15).animate(
      CurvedAnimation(
        parent: _badgeController,
        curve: const Interval(0.0, 0.4, curve: Curves.elasticOut),
      ),
    );

    _badgeOpacity = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _badgeController,
        curve: const Interval(0.5, 1.0, curve: Curves.easeOut),
      ),
    );

    _badgeOffset = Tween<Offset>(
      begin: const Offset(0, 0),
      end: const Offset(0, -22),
    ).animate(
      CurvedAnimation(
        parent: _badgeController,
        curve: Curves.easeOutCubic,
      ),
    );
  }

  @override
  void didUpdateWidget(CollapsibleNavMenu oldWidget) {
    super.didUpdateWidget(oldWidget);

    final moneyDelta = widget.playerState.money - oldWidget.playerState.money;
    if (moneyDelta > 0) {
      _badgeText = '+$moneyDelta';
      _badgeIsCoins = true;
      _badgeController.forward(from: 0.0);
    } else {
      final invDelta =
          widget.playerState.inventory.length - oldWidget.playerState.inventory.length;
      if (invDelta > 0) {
        _badgeText = '+$invDelta';
        _badgeIsCoins = false;
        _badgeController.forward(from: 0.0);
      }
    }
  }

  @override
  void dispose() {
    _badgeController.dispose();
    super.dispose();
  }

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
                  Stack(
                    clipBehavior: Clip.none,
                    children: [
                      GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: () => widget.onAction(NavAction.market),
                        child: _buildStatChip(
                          icon: Icons.monetization_on,
                          iconColor: Colors.amber,
                          label: '${widget.playerState.money}',
                        ),
                      ),
                      if (_badgeIsCoins && _badgeText != null)
                        Positioned(
                          top: -20,
                          left: 0,
                          right: 0,
                          child: Center(
                            child: AnimatedBuilder(
                              animation: _badgeController,
                              builder: (context, child) {
                                return Transform.translate(
                                  offset: _badgeOffset.value,
                                  child: Opacity(
                                    opacity: _badgeOpacity.value,
                                    child: Transform.scale(
                                      scale: _badgeScale.value,
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 3,
                                        ),
                                        decoration: BoxDecoration(
                                          color: Colors.amber,
                                          borderRadius: BorderRadius.circular(12),
                                          boxShadow: const [
                                            BoxShadow(
                                              color: Colors.orangeAccent,
                                              blurRadius: 10,
                                              spreadRadius: 1,
                                            ),
                                          ],
                                        ),
                                        child: Text(
                                          _badgeText!,
                                          style: const TextStyle(
                                            color: Colors.black,
                                            fontWeight: FontWeight.w900,
                                            fontSize: 12,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(width: 12),

                  // Inventory -> tap opens Inventory
                  Stack(
                    clipBehavior: Clip.none,
                    children: [
                      GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: () => widget.onAction(NavAction.inventory),
                        child: _buildStatChip(
                          icon: Icons.backpack,
                          iconColor: Colors.orangeAccent,
                          label:
                              '${widget.playerState.inventory.length}/${widget.playerState.storageLimit}',
                        ),
                      ),
                      if (!_badgeIsCoins && _badgeText != null)
                        Positioned(
                          top: -20,
                          left: 0,
                          right: 0,
                          child: Center(
                            child: AnimatedBuilder(
                              animation: _badgeController,
                              builder: (context, child) {
                                return Transform.translate(
                                  offset: _badgeOffset.value,
                                  child: Opacity(
                                    opacity: _badgeOpacity.value,
                                    child: Transform.scale(
                                      scale: _badgeScale.value,
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 3,
                                        ),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFF2A9D8F),
                                          borderRadius: BorderRadius.circular(12),
                                          boxShadow: const [
                                            BoxShadow(
                                              color: Colors.tealAccent,
                                              blurRadius: 10,
                                              spreadRadius: 1,
                                            ),
                                          ],
                                        ),
                                        child: Text(
                                          _badgeText!,
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.w900,
                                            fontSize: 12,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(width: 12),

                  // Bait -> tap opens Market
                  GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () => widget.onAction(NavAction.market),
                    child: _buildStatChip(
                      icon: Icons.bug_report,
                      iconColor: Colors.lightGreenAccent,
                      label: '${widget.playerState.baitCount}',
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
          left: widget.isVisible ? (widget.isCollapsed ? -175 : 12) : -220,
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
                            'Junk Fishing',
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
                      badgeCount: widget.playerState.inventory.length,
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
                onTap: widget.onToggleCollapse,
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
                      widget.isCollapsed ? Icons.chevron_right : Icons.chevron_left,
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
      onTap: () => widget.onAction(action),
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
