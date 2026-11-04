import 'item.dart';

class PlayerState {
  final int money;
  final int baitCount;
  final int storageLimit;
  final List<Item> inventory;
  final String currentLocationId;
  final Set<String> discoveredItemIds;
  final Set<String> claimedCollectionIds;
  final Set<String> unlockedLocationIds;

  const PlayerState({
    required this.money,
    required this.baitCount,
    required this.storageLimit,
    required this.inventory,
    required this.currentLocationId,
    required this.discoveredItemIds,
    required this.claimedCollectionIds,
    this.unlockedLocationIds = const {'loc_rusty_dock', 'loc_neon_canal'},
  });

  factory PlayerState.initial() {
    return const PlayerState(
      money: 150,
      baitCount: 20,
      storageLimit: 20,
      inventory: [],
      currentLocationId: 'loc_rusty_dock',
      discoveredItemIds: {},
      claimedCollectionIds: {},
      unlockedLocationIds: {'loc_rusty_dock', 'loc_neon_canal'},
    );
  }

  bool get hasStorageSpace => inventory.length < storageLimit;
  bool get canFish => baitCount > 0 && hasStorageSpace;

  PlayerState copyWith({
    int? money,
    int? baitCount,
    int? storageLimit,
    List<Item>? inventory,
    String? currentLocationId,
    Set<String>? discoveredItemIds,
    Set<String>? claimedCollectionIds,
    Set<String>? unlockedLocationIds,
  }) {
    return PlayerState(
      money: money ?? this.money,
      baitCount: baitCount ?? this.baitCount,
      storageLimit: storageLimit ?? this.storageLimit,
      inventory: inventory ?? this.inventory,
      currentLocationId: currentLocationId ?? this.currentLocationId,
      discoveredItemIds: discoveredItemIds ?? this.discoveredItemIds,
      claimedCollectionIds: claimedCollectionIds ?? this.claimedCollectionIds,
      unlockedLocationIds: unlockedLocationIds ?? this.unlockedLocationIds,
    );
  }

  factory PlayerState.fromJson(Map<String, dynamic> json) {
    final rawInventory = json['inventory'] as List<dynamic>? ?? [];
    final items = rawInventory
        .map((e) => Item.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();

    final rawDiscovered = json['discoveredItemIds'] as List<dynamic>? ?? [];
    final discovered = rawDiscovered.map((e) => e.toString()).toSet();

    final rawClaimed = json['claimedCollectionIds'] as List<dynamic>? ?? [];
    final claimed = rawClaimed.map((e) => e.toString()).toSet();

    final rawUnlocked = json['unlockedLocationIds'] as List<dynamic>? ?? [];
    final unlocked = rawUnlocked.isNotEmpty
        ? rawUnlocked.map((e) => e.toString()).toSet()
        : const {'loc_rusty_dock', 'loc_neon_canal'};

    return PlayerState(
      money: (json['money'] as num?)?.toInt() ?? 150,
      baitCount: (json['baitCount'] as num?)?.toInt() ?? 20,
      storageLimit: (json['storageLimit'] as num?)?.toInt() ?? 20,
      inventory: items,
      currentLocationId: json['currentLocationId'] as String? ?? 'loc_rusty_dock',
      discoveredItemIds: discovered,
      claimedCollectionIds: claimed,
      unlockedLocationIds: unlocked,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'money': money,
      'baitCount': baitCount,
      'storageLimit': storageLimit,
      'inventory': inventory.map((e) => e.toJson()).toList(),
      'currentLocationId': currentLocationId,
      'discoveredItemIds': discoveredItemIds.toList(),
      'claimedCollectionIds': claimedCollectionIds.toList(),
      'unlockedLocationIds': unlockedLocationIds.toList(),
    };
  }
}
