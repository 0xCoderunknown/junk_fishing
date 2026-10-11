import 'item.dart';

class PlayerState {
  final int money;
  final int baitCount;
  final int storageLimit;
  final List<Item> inventory;
  final String currentLocationId;
  final Set<String> discoveredItemIds;
  final Set<String> claimedCollectionIds;

  const PlayerState({
    required this.money,
    required this.baitCount,
    required this.storageLimit,
    required this.inventory,
    required this.currentLocationId,
    required this.discoveredItemIds,
    required this.claimedCollectionIds,
  });

  factory PlayerState.initial() {
    return const PlayerState(
      money: 100,
      baitCount: 15,
      storageLimit: 20,
      inventory: [],
      currentLocationId: 'loc_rusty_dock',
      discoveredItemIds: {},
      claimedCollectionIds: {},
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
  }) {
    return PlayerState(
      money: money ?? this.money,
      baitCount: baitCount ?? this.baitCount,
      storageLimit: storageLimit ?? this.storageLimit,
      inventory: inventory ?? this.inventory,
      currentLocationId: currentLocationId ?? this.currentLocationId,
      discoveredItemIds: discoveredItemIds ?? this.discoveredItemIds,
      claimedCollectionIds: claimedCollectionIds ?? this.claimedCollectionIds,
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

    return PlayerState(
      money: (json['money'] as num?)?.toInt() ?? 100,
      baitCount: (json['baitCount'] as num?)?.toInt() ?? 15,
      storageLimit: (json['storageLimit'] as num?)?.toInt() ?? 20,
      inventory: items,
      currentLocationId: json['currentLocationId'] as String? ?? 'loc_rusty_dock',
      discoveredItemIds: discovered,
      claimedCollectionIds: claimed,
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
    };
  }
}
