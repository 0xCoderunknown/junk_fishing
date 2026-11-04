import 'dart:math';
import '../models/item.dart';
import '../models/location.dart';

/// Pure Dart Loot & Gacha Engine.
///
/// Determines catch outcomes based on location drop pools,
/// base rarity odds, and precision bonuses from timing accuracy.
class LootEngine {
  final Random _rng;

  LootEngine({Random? rng}) : _rng = rng ?? Random();

  /// Rolls a weighted catch from the current location and global items list.
  ///
  /// Base Rarity weights:
  /// ★: 50%
  /// ★★: 28%
  /// ★★★: 14%
  /// ★★★★: 6%
  /// ★★★★★: 2%
  ///
  /// Accuracy [0.0 - 1.0] shifts probability toward higher rarity tiers.
  Item? rollCatch({
    required Location location,
    required Map<String, Item> itemMap,
    required List<Item> fallbackItems,
    double timingBonus = 0.0,
  }) {
    final pool = location.availableItemIds
        .map((id) => itemMap[id])
        .whereType<Item>()
        .toList();

    if (pool.isEmpty) {
      if (fallbackItems.isEmpty) return null;
      return fallbackItems[_rng.nextInt(fallbackItems.length)];
    }

    final weightedPool = pool.map((item) {
      double baseWeight;
      switch (item.rarity) {
        case 1:
          baseWeight = 50.0;
          break;
        case 2:
          baseWeight = 28.0;
          break;
        case 3:
          baseWeight = 14.0 + (timingBonus * 4.0);
          break;
        case 4:
          baseWeight = 6.0 + (timingBonus * 3.0);
          break;
        case 5:
          baseWeight = 2.0 + (timingBonus * 3.0);
          break;
        default:
          baseWeight = 10.0;
      }
      return MapEntry(item, baseWeight);
    }).toList();

    final totalWeight =
        weightedPool.fold<double>(0.0, (sum, entry) => sum + entry.value);
    final roll = _rng.nextDouble() * totalWeight;

    double cumulative = 0.0;
    for (final entry in weightedPool) {
      cumulative += entry.value;
      if (roll <= cumulative) {
        return entry.key;
      }
    }

    return weightedPool.last.key;
  }
}
