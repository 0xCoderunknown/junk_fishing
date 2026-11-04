import 'dart:math';
import 'package:flutter_test/flutter_test.dart';
import 'package:junk_fishing/engine/fishing_timing_engine.dart';
import 'package:junk_fishing/engine/loot_engine.dart';
import 'package:junk_fishing/models/item.dart';
import 'package:junk_fishing/models/location.dart';

void main() {
  group('FishingTimingEngine Tests', () {
    test('Engine initializes with correct tolerance and default radius', () {
      final engine = FishingTimingEngine(difficultyMultiplier: 1.0);
      expect(engine.currentRadius, FishingTimingEngine.maxOuterRadius);
      expect(engine.isFinished, false);
      expect(engine.strikeTolerance, 22.0);
    });

    test('Premature tap outside orange window fails with 0 accuracy', () {
      final engine = FishingTimingEngine();
      expect(engine.isInOrangeStrikeWindow, false);

      final result = engine.registerTap();
      expect(result.success, false);
      expect(result.accuracy, 0.0);
      expect(engine.isFinished, true);
    });

    test('Engine updates radius over time and recycles cycle without finish', () {
      final engine = FishingTimingEngine();
      final now = DateTime.now().millisecondsSinceEpoch;

      engine.update(now + 2000);
      expect(engine.isFinished, false);

      engine.update(now + 10000);
      expect(engine.isFinished, false);
    });
  });

  group('LootEngine Tests', () {
    const testLocation = Location(
      id: 'loc_test',
      name: 'Test Spot',
      description: 'Testing location',
      difficulty: 1.0,
      unlocked: true,
      themeColor: '0xFF000000',
      waterColor: '0xFF0000FF',
      availableItemIds: ['item_common', 'item_rare'],
    );

    const commonItem = Item(
      id: 'item_common',
      name: 'Rusty Tin Can',
      flavorText: 'An ordinary can',
      rarity: 1,
      weightKg: 0.1,
      estimatedValue: 5,
      collectionTag: 'Kitchen',
      locationId: 'loc_test',
    );

    const rareItem = Item(
      id: 'item_rare',
      name: 'Golden Watch',
      flavorText: 'Still ticking',
      rarity: 4,
      weightKg: 0.2,
      estimatedValue: 120,
      collectionTag: 'Relics',
      locationId: 'loc_test',
    );

    final itemMap = {
      commonItem.id: commonItem,
      rareItem.id: rareItem,
    };

    final allItems = [commonItem, rareItem];

    test('LootEngine rolls valid item from location pool', () {
      final engine = LootEngine(rng: Random(42));
      final caught = engine.rollCatch(
        location: testLocation,
        itemMap: itemMap,
        fallbackItems: allItems,
        timingBonus: 0.5,
      );

      expect(caught, isNotNull);
      expect(testLocation.availableItemIds.contains(caught!.id), true);
    });
  });
}
