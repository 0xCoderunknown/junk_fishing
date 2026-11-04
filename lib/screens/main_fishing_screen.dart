import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/fishing_state.dart';
import '../models/item.dart';
import '../services/game_data_service.dart';
import '../widgets/collapsible_nav_menu.dart';
import '../widgets/comic_speech_bubble.dart';
import '../widgets/isometric_world.dart';
import '../widgets/modals/collections_sheet.dart';
import '../widgets/modals/inventory_sheet.dart';
import '../widgets/modals/market_sheet.dart';
import '../widgets/modals/map_sheet.dart';
import '../widgets/modals/settings_sheet.dart';
import '../widgets/polaroid_result_card.dart';
import '../widgets/ripple_timing_overlay.dart';

class MainFishingScreen extends StatefulWidget {
  const MainFishingScreen({super.key});

  @override
  State<MainFishingScreen> createState() => _MainFishingScreenState();
}

class _MainFishingScreenState extends State<MainFishingScreen> {
  final GameDataService _gameService = GameDataService();

  // State Machine: Start directly at readyToCast so player immediately taps the hole!
  FishingState _fishingState = FishingState.readyToCast;
  bool _menuCollapsed = false;

  // Resolve outcome data
  bool _lastAttemptSucceeded = false;
  double _lastTimingAccuracy = 0.0;
  Item? _caughtItem;

  @override
  void initState() {
    super.initState();
    _loadGame();
  }

  Future<void> _loadGame() async {
    await _gameService.init();
    if (mounted) setState(() {});
  }

  void _onNavAction(NavAction action) {
    switch (action) {
      case NavAction.fish:
        _startFishingPreparation();
        break;
      case NavAction.inventory:
        _showInventoryModal();
        break;
      case NavAction.market:
        _showMarketModal();
        break;
      case NavAction.collections:
        _showCollectionsModal();
        break;
      case NavAction.map:
        _showMapModal();
        break;
      case NavAction.settings:
        _showSettingsModal();
        break;
    }
  }

  // --- State Transitions ---

  /// 1 -> 2: IDLE_MENU -> FISHING_READY
  void _startFishingPreparation() {
    if (!_gameService.playerState.hasStorageSpace) {
      _showWarningSnackBar('Inventory is full! Sell some scrap first.');
      return;
    }
    if (_gameService.playerState.baitCount <= 0) {
      _showWarningSnackBar('Out of bait! Purchase more bait in the HUD.');
      return;
    }

    setState(() {
      _fishingState = FishingState.readyToCast;
    });
  }

  /// 2 -> 3: FISHING_READY -> RIPPLE_TIMING
  Future<void> _initiateCast() async {
    if (_fishingState != FishingState.readyToCast) return;

    final consumed = await _gameService.consumeBait();
    if (!consumed) {
      _showWarningSnackBar('No bait available!');
      setState(() => _fishingState = FishingState.idleMenu);
      return;
    }

    HapticFeedback.lightImpact();

    setState(() {
      _fishingState = FishingState.rippleActive;
    });
  }

  /// 3 -> 4: RIPPLE_TIMING -> PULL_RESOLVE (1.5 seconds pull action)
  void _handleRippleResolved(bool success, double accuracy) {
    _lastAttemptSucceeded = success;
    _lastTimingAccuracy = accuracy;

    if (success) {
      HapticFeedback.mediumImpact();
      _caughtItem = _gameService.rollCatch(timingBonus: accuracy);
    } else {
      HapticFeedback.heavyImpact();
      _caughtItem = null;
    }

    // Unblur and trigger 1.5s rod pull animation
    setState(() {
      _fishingState = FishingState.pullingRod;
    });

    // Character pulls rod for exactly 1.5 seconds, then enters RESULT_POPUP
    Timer(const Duration(milliseconds: 1500), () {
      if (!mounted) return;
      setState(() {
        _fishingState = FishingState.resultModal;
      });
    });
  }

  /// When fishing ends: Return directly to [readyToCast] (Tap the Hole)
  void _returnToReadyToCast() {
    setState(() {
      _caughtItem = null;
      _lastAttemptSucceeded = false;
      _fishingState = FishingState.readyToCast;
    });
  }

  Future<void> _handleKeepItem() async {
    if (_caughtItem != null) {
      final success = await _gameService.keepCaughtItem(_caughtItem!);
      if (!success) {
        _showWarningSnackBar('Bag is full! Item discarded.');
      } else {
        _showSuccessSnackBar('Stored "${_caughtItem!.name}" in inventory!');
      }
    }
    _returnToReadyToCast();
  }

  Future<void> _handleSellItem() async {
    if (_caughtItem != null) {
      final earned = await _gameService.sellItem(_caughtItem!);
      _showSuccessSnackBar('Sold "${_caughtItem!.name}" for 🪙 $earned scrap coins!');
    }
    _returnToReadyToCast();
  }

  // --- Modals & Actions ---

  void _showInventoryModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => InventorySheet(
        playerState: _gameService.playerState,
        gameService: _gameService,
        onStateChanged: () => setState(() {}),
      ),
    );
  }

  void _showMarketModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => MarketSheet(
        gameService: _gameService,
        onStateChanged: () => setState(() {}),
      ),
    );
  }

  void _showCollectionsModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => CollectionsSheet(
        gameService: _gameService,
        onStateChanged: () => setState(() {}),
      ),
    );
  }

  void _showMapModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => MapSheet(
        gameService: _gameService,
        onLocationSelected: () => setState(() {}),
      ),
    );
  }

  void _showSettingsModal() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => SettingsSheet(
        gameService: _gameService,
        onReset: () => setState(() {}),
      ),
    );
  }

  Future<void> _buyBait() async {
    final success = await _gameService.buyBait(amount: 5, cost: 50);
    if (success) {
      _showSuccessSnackBar('Purchased 5 bait for 🪙 50!');
      setState(() {});
    } else {
      _showWarningSnackBar('Need 🪙 50 coins to buy bait.');
    }
  }

  Future<void> _upgradeStorage() async {
    final success = await _gameService.upgradeStorage(extraSlots: 5, cost: 150);
    if (success) {
      _showSuccessSnackBar('Storage expanded to ${_gameService.playerState.storageLimit} slots!');
      setState(() {});
    } else {
      _showWarningSnackBar('Need 🪙 150 coins to expand storage.');
    }
  }

  void _showWarningSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.redAccent.shade700,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showSuccessSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: const Color(0xFF2A9D8F),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!_gameService.isLoaded) {
      return const Scaffold(
        backgroundColor: Color(0xFF0D1117),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(color: Colors.tealAccent),
              SizedBox(height: 16),
              Text(
                'Dredging lake bed...',
                style: TextStyle(color: Colors.white70, letterSpacing: 1.2),
              ),
            ],
          ),
        ),
      );
    }

    final location = _gameService.currentLocation;
    final isMenuVisible = _fishingState == FishingState.idleMenu ||
        _fishingState == FishingState.readyToCast;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // -------------------------------------------------------------
          // LAYER 1: Isometric World (Pond, Dock, Fisherman & Rod)
          // -------------------------------------------------------------
          IsometricWorld(
            state: _fishingState,
            location: location,
            onPondTap: _initiateCast,
          ),

          // -------------------------------------------------------------
          // LAYER 3: Collapsible Left Navigation Menu & Player HUD
          // -------------------------------------------------------------
          CollapsibleNavMenu(
            isVisible: isMenuVisible,
            isCollapsed: _menuCollapsed,
            playerState: _gameService.playerState,
            currentLocation: location,
            onAction: _onNavAction,
            onToggleCollapse: () {
              setState(() => _menuCollapsed = !_menuCollapsed);
            },
            onBuyBait: _buyBait,
            onUpgradeStorage: _upgradeStorage,
          ),

          // -------------------------------------------------------------
          // LAYER 4: Centered Ripple Wave Timing Overlay
          // (Only active in rippleActive state)
          // -------------------------------------------------------------
          if (_fishingState == FishingState.rippleActive)
            RippleTimingOverlay(
              difficultyMultiplier: location?.difficulty ?? 1.0,
              onResolve: _handleRippleResolved,
            ),

          // -------------------------------------------------------------
          // LAYER 5: Pull Resolve 1.5s indicator HUD badge
          // -------------------------------------------------------------
          if (_fishingState == FishingState.pullingRod)
            Positioned(
              top: MediaQuery.of(context).size.height * 0.22,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.8),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: _lastAttemptSucceeded ? Colors.tealAccent : Colors.redAccent,
                      width: 1.5,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        _lastAttemptSucceeded ? Icons.check_circle : Icons.cancel,
                        color: _lastAttemptSucceeded ? Colors.tealAccent : Colors.redAccent,
                        size: 18,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _lastAttemptSucceeded
                            ? 'REELING IN JUNK... (${(_lastTimingAccuracy * 100).toInt()}% ACCURACY)'
                            : 'LINE SNAPPED! REELING IN EMPTY...',
                        style: TextStyle(
                          color: _lastAttemptSucceeded ? Colors.tealAccent : Colors.redAccent,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

          // -------------------------------------------------------------
          // LAYER 6: RESULT POPUPS (Success Polaroid vs Fail Comic Bubble)
          // -------------------------------------------------------------
          if (_fishingState == FishingState.resultModal) ...[
            if (_lastAttemptSucceeded && _caughtItem != null)
              PolaroidResultCard(
                item: _caughtItem!,
                location: location,
                onKeep: _handleKeepItem,
                onSell: _handleSellItem,
              )
            else
              ComicSpeechBubble(
                onDismiss: _returnToReadyToCast,
              ),
          ],
        ],
      ),
    );
  }
}
