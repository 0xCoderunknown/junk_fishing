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
  /// [timingBonus] is the raw tap accuracy from [FishingTimingEngine.registerTap()],
  /// in the range [0.65 – 1.0]. It is normalized internally to [0.0 – 1.0] so that
  /// a perfect center tap (1.0) grants maximum bonus, while a barely-made edge tap
  /// (0.65) grants zero bonus. This makes timing precision feel meaningful.
  ///
  /// Bonus shifts probability toward rarity 3, 4, and 5 tiers.
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

    // Normalize accuracy from [0.65 – 1.0] to [0.0 – 1.0].
    // A barely-made edge tap (0.65) gives no bonus; a perfect center tap (1.0) gives full bonus.
    // timingBonus values outside the accuracy range (e.g. 0.0 from a non-orange tap)
    // are clamped to 0.0 so they never grant a negative or surprise bonus.
    const minAccuracy = 0.65;
    final normalizedBonus = timingBonus <= minAccuracy
        ? 0.0
        : ((timingBonus - minAccuracy) / (1.0 - minAccuracy)).clamp(0.0, 1.0);

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
          baseWeight = 14.0 + (normalizedBonus * 4.0);
          break;
        case 4:
          baseWeight = 6.0 + (normalizedBonus * 3.0);
          break;
        case 5:
          baseWeight = 2.0 + (normalizedBonus * 3.0);
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
      if (roll < cumulative) {
        return entry.key;
      }
    }

    // Fallback: return last item (covers floating point edge cases at totalWeight boundary)
    return weightedPool.last.key;
  }
}
