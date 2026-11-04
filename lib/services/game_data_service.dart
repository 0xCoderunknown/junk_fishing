import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../engine/loot_engine.dart';
import '../models/collection.dart';
import '../models/item.dart';
import '../models/location.dart';
import '../models/player_state.dart';

class GameDataService extends ChangeNotifier {
  static final GameDataService _instance = GameDataService._internal();

  factory GameDataService() => _instance;

  GameDataService._internal();

  static const String _playerPrefsKey = 'junk_fishing_player_state_v1';

  final List<Location> _locations = [];
  final List<Item> _items = [];
  final List<Collection> _collections = [];

  final Map<String, Location> _locationMap = {};
  final Map<String, Item> _itemMap = {};
  final Map<String, Collection> _collectionMap = {};

  final LootEngine _lootEngine = LootEngine();

  PlayerState _playerState = PlayerState.initial();
  bool _isLoaded = false;

  List<Location> get locations => List.unmodifiable(_locations);

  List<Item> get items => List.unmodifiable(_items);

  List<Collection> get collections => List.unmodifiable(_collections);

  PlayerState get playerState => _playerState;

  bool get isLoaded => _isLoaded;

  Location? get currentLocation =>
      _locationMap[_playerState.currentLocationId] ??
      (_locations.isNotEmpty ? _locations.first : null);

  /// Load all game data from local JSON assets and player state from SharedPreferences.
  Future<void> init() async {
    if (_isLoaded) return;

    try {
      // 1. Load Locations
      final locationsString = await rootBundle.loadString(
        'assets/data/locations.json',
      );
      final locationsJson = jsonDecode(locationsString) as List<dynamic>;
      _locations.clear();
      _locationMap.clear();
      for (final raw in locationsJson) {
        final loc = Location.fromJson(Map<String, dynamic>.from(raw as Map));
        _locations.add(loc);
        _locationMap[loc.id] = loc;
      }

      // 2. Load Items
      final itemsString = await rootBundle.loadString('assets/data/items.json');
      final itemsJson = jsonDecode(itemsString) as List<dynamic>;
      _items.clear();
      _itemMap.clear();
      for (final raw in itemsJson) {
        final item = Item.fromJson(Map<String, dynamic>.from(raw as Map));
        _items.add(item);
        _itemMap[item.id] = item;
      }

      // 3. Load Collections
      final collectionsString = await rootBundle.loadString(
        'assets/data/collections.json',
      );
      final collectionsJson = jsonDecode(collectionsString) as List<dynamic>;
      _collections.clear();
      _collectionMap.clear();
      for (final raw in collectionsJson) {
        final col = Collection.fromJson(Map<String, dynamic>.from(raw as Map));
        _collections.add(col);
        _collectionMap[col.id] = col;
      }

      // 4. Load or Initialize Player State
      await _loadPlayerState();

      _isLoaded = true;
      notifyListeners();
    } catch (e) {
      // Fallback in case of error
      _isLoaded = true;
      notifyListeners();
    }
  }

  Future<void> _loadPlayerState() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedData = prefs.getString(_playerPrefsKey);
      if (savedData != null && savedData.isNotEmpty) {
        final json = jsonDecode(savedData) as Map<String, dynamic>;
        _playerState = PlayerState.fromJson(json);
      } else {
        _playerState = PlayerState.initial();
        await _savePlayerState();
      }
    } catch (_) {
      _playerState = PlayerState.initial();
    }
  }

  Future<void> _savePlayerState() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final encoded = jsonEncode(_playerState.toJson());
      await prefs.setString(_playerPrefsKey, encoded);
    } catch (_) {
      // Best effort save
    }
    notifyListeners();
  }

  Item? getItemById(String id) => _itemMap[id];

  Location? getLocationById(String id) => _locationMap[id];

  Collection? getCollectionById(String id) => _collectionMap[id];

  /// Checks if a location is unlocked for the player.
  bool isLocationUnlocked(String locationId) {
    if (_playerState.unlockedLocationIds.contains(locationId)) return true;
    return _locationMap[locationId]?.unlocked ?? false;
  }

  /// Unlock a location by paying coins.
  Future<bool> unlockLocation(String locationId, {int cost = 350}) async {
    if (_playerState.money < cost) return false;
    if (isLocationUnlocked(locationId)) return true;

    final updatedUnlocked = Set<String>.from(_playerState.unlockedLocationIds)
      ..add(locationId);

    _playerState = _playerState.copyWith(
      money: _playerState.money - cost,
      unlockedLocationIds: updatedUnlocked,
    );

    await _savePlayerState();
    return true;
  }

  /// Set the active fishing location.
  Future<void> selectLocation(String locationId) async {
    if (_locationMap.containsKey(locationId) &&
        isLocationUnlocked(locationId)) {
      _playerState = _playerState.copyWith(currentLocationId: locationId);
      await _savePlayerState();
    }
  }

  /// Roll a fishing catch using the isolated LootEngine.
  Item? rollCatch({double timingBonus = 0.0}) {
    final location = currentLocation;
    if (location == null) return null;
    return _lootEngine.rollCatch(
      location: location,
      itemMap: _itemMap,
      fallbackItems: _items,
      timingBonus: timingBonus,
    );
  }

  /// Deduct 1 bait when fishing cast begins.
  Future<bool> consumeBait() async {
    if (_playerState.baitCount <= 0) return false;
    _playerState = _playerState.copyWith(baitCount: _playerState.baitCount - 1);
    await _savePlayerState();
    return true;
  }

  /// Keep the caught item: adds to inventory and marks as discovered.
  Future<bool> keepCaughtItem(Item item) async {
    if (!_playerState.hasStorageSpace) return false;

    final updatedInventory = List<Item>.from(_playerState.inventory)..add(item);
    final updatedDiscovered = Set<String>.from(_playerState.discoveredItemIds)
      ..add(item.id);

    _playerState = _playerState.copyWith(
      inventory: updatedInventory,
      discoveredItemIds: updatedDiscovered,
    );
    await _savePlayerState();
    return true;
  }

  /// Sell item immediately: adds sell value to money, marks discovered.
  Future<int> sellItem(Item item, {bool fromInventory = false}) async {
    final value = item.estimatedValue;
    final updatedInventory = List<Item>.from(_playerState.inventory);
    if (fromInventory) {
      updatedInventory.remove(item);
    }
    final updatedDiscovered = Set<String>.from(_playerState.discoveredItemIds)
      ..add(item.id);

    _playerState = _playerState.copyWith(
      money: _playerState.money + value,
      inventory: updatedInventory,
      discoveredItemIds: updatedDiscovered,
    );

    await _savePlayerState();
    return value;
  }

  /// Atomically sells all items in inventory in a single pass with one storage write.
  /// Returns the total coins gained.
  Future<int> sellAllScrap() async {
    final inventory = _playerState.inventory;
    if (inventory.isEmpty) return 0;

    int totalGain = 0;
    final updatedDiscovered = Set<String>.from(_playerState.discoveredItemIds);

    for (final item in inventory) {
      totalGain += item.estimatedValue;
      updatedDiscovered.add(item.id);
    }

    _playerState = _playerState.copyWith(
      money: _playerState.money + totalGain,
      inventory: const [],
      discoveredItemIds: updatedDiscovered,
    );

    await _savePlayerState();
    return totalGain;
  }

  /// Claim completion reward for a collection.
  Future<bool> claimCollectionReward(String collectionId) async {
    final collection = _collectionMap[collectionId];
    if (collection == null) return false;
    if (_playerState.claimedCollectionIds.contains(collectionId)) return false;
    if (!collection.isComplete(_playerState.discoveredItemIds)) return false;

    final updatedClaimed = Set<String>.from(_playerState.claimedCollectionIds)
      ..add(collectionId);

    _playerState = _playerState.copyWith(
      money: _playerState.money + collection.rewardMoney,
      claimedCollectionIds: updatedClaimed,
    );

    await _savePlayerState();
    return true;
  }

  /// Buy bait with money.
  Future<bool> buyBait({int amount = 5, int cost = 50}) async {
    if (_playerState.money < cost) return false;

    _playerState = _playerState.copyWith(
      money: _playerState.money - cost,
      baitCount: _playerState.baitCount + amount,
    );

    await _savePlayerState();
    return true;
  }

  /// Upgrade storage capacity.
  Future<bool> upgradeStorage({int extraSlots = 5, int cost = 150}) async {
    if (_playerState.money < cost) return false;

    _playerState = _playerState.copyWith(
      money: _playerState.money - cost,
      storageLimit: _playerState.storageLimit + extraSlots,
    );

    await _savePlayerState();
    return true;
  }

  /// Reset progress (for testing or debugging).
  Future<void> resetPlayerState() async {
    _playerState = PlayerState.initial();
    await _savePlayerState();
  }
}
