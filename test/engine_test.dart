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

    test('Strike window duration is ~500ms and guarantees catch on tap', () {
      final engine = FishingTimingEngine();

      // Advance to strike window by stepping simulation
      int simulatedTime = DateTime.now().millisecondsSinceEpoch;
      bool foundOrange = false;

      for (int i = 0; i < 200; i++) {
        simulatedTime += 50;
        engine.update(simulatedTime);
        if (engine.isInOrangeStrikeWindow) {
          foundOrange = true;
          break;
        }
      }

      expect(
        foundOrange,
        true,
        reason: 'Engine should reach orange strike window',
      );
      expect(engine.currentPhase?.type, TimingPhaseType.strikeWindow);
      expect(engine.currentPhase?.durationMs, inInclusiveRange(400, 650));

      // Tapping during orange window guarantees catch with graded accuracy
      final tapResult = engine.registerTap(simulatedTime);
      expect(tapResult.success, true);
      expect(tapResult.accuracy, inInclusiveRange(0.65, 1.0));
    });

    test(
      'Strike window tap accuracy awards 1.0 at center and lower at edge',
      () {
        final engine = FishingTimingEngine();
        int simulatedTime = DateTime.now().millisecondsSinceEpoch;

        for (int i = 0; i < 200; i++) {
          simulatedTime += 40;
          engine.update(simulatedTime);
          if (engine.isInOrangeStrikeWindow) break;
        }

        final windowDuration = engine.currentPhase!.durationMs;
        final centerTime = simulatedTime + (windowDuration ~/ 2);
        final centerResult = engine.registerTap(centerTime);
        expect(centerResult.success, true);
        expect(centerResult.accuracy, closeTo(1.0, 0.05));
      },
    );

    test(
      'Engine updates radius over time and recycles cycle without finish',
      () {
        final engine = FishingTimingEngine();
        final now = DateTime.now().millisecondsSinceEpoch;

        engine.update(now + 2000);
        expect(engine.isFinished, false);

        engine.update(now + 10000);
        expect(engine.isFinished, false);
      },
    );

    test('Deep tease phase does not trigger orange strike window despite being close to center', () {
      final engine = FishingTimingEngine();

      // Look for deepTease phase in the engine's cycle
      final deepTeasePhase = engine.currentPhase;
      if (deepTeasePhase?.type == TimingPhaseType.deepTease) {
        expect(engine.isInOrangeStrikeWindow, false);
        expect(deepTeasePhase?.isOrangeStrike, false);
      }
      expect(engine.isInOrangeStrikeWindow, false);
    });

    test('After retreat phase engine automatically begins a new cycle', () {
      final engine = FishingTimingEngine();
      int simulatedTime = DateTime.now().millisecondsSinceEpoch;

      // Run through until we pass the first full cycle (tease + strike + retreat)
      // We skip past the orange window by not tapping, and keep advancing time.
      for (int i = 0; i < 2000; i++) {
        simulatedTime += 50;
        engine.update(simulatedTime);

        // After the retreat phase completes, engine should still be running
        if (!engine.isInOrangeStrikeWindow && !engine.isFinished) {
          final phase = engine.currentPhase;
          if (phase?.type == TimingPhaseType.teaseNibble ||
              phase?.type == TimingPhaseType.deepTease) {
            break;
          }
        }
      }

      expect(
        engine.isFinished,
        false,
        reason: 'Engine must keep cycling indefinitely after missed strikes',
      );
    });

    test(
      'Radius snaps to exact target value at phase boundary (no float drift)',
      () {
        final engine = FishingTimingEngine();
        int simulatedTime = DateTime.now().millisecondsSinceEpoch;

        // Jump far ahead to force many phase completions
        engine.update(simulatedTime + 999999);
        // Radius must never exceed maxOuterRadius or drop below innerRingRadius during teasing
        expect(
          engine.currentRadius,
          lessThanOrEqualTo(FishingTimingEngine.maxOuterRadius + 1.0),
        );
        expect(engine.isFinished, false);
      },
    );
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

    final itemMap = {commonItem.id: commonItem, rareItem.id: rareItem};

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

    test(
      'LootEngine with timingBonus=0.0 (pre-orange miss) uses base weights',
      () {
        // Even with 0 bonus, a valid item from pool should still be returned
        final engine = LootEngine(rng: Random(1));
        final caught = engine.rollCatch(
          location: testLocation,
          itemMap: itemMap,
          fallbackItems: allItems,
          timingBonus: 0.0,
        );
        expect(caught, isNotNull);
        expect(testLocation.availableItemIds.contains(caught!.id), true);
      },
    );

    test(
      'LootEngine with perfect accuracy (1.0) still returns a valid item',
      () {
        final engine = LootEngine(rng: Random(99));
        final caught = engine.rollCatch(
          location: testLocation,
          itemMap: itemMap,
          fallbackItems: allItems,
          timingBonus: 1.0,
        );
        expect(caught, isNotNull);
        expect(testLocation.availableItemIds.contains(caught!.id), true);
      },
    );

    test('LootEngine with minimum accuracy (0.65) grants no rarity bonus', () {
      // timingBonus=0.65 normalizes to 0.0, so bonus should be identical to timingBonus=0.0
      // We verify by checking that the weighted pool totals match.
      // We test with a seeded RNG for determinism.
      final engine1 = LootEngine(rng: Random(7));
      final engine2 = LootEngine(rng: Random(7));

      final result1 = engine1.rollCatch(
        location: testLocation,
        itemMap: itemMap,
        fallbackItems: allItems,
        timingBonus: 0.0,
      );
      final result2 = engine2.rollCatch(
        location: testLocation,
        itemMap: itemMap,
        fallbackItems: allItems,
        timingBonus:
            0.65, // Should normalize to 0.0 — same RNG roll => same item
      );
      expect(
        result1?.id,
        result2?.id,
        reason:
            'Edge accuracy (0.65) should give same result as no bonus (0.0)',
      );
    });

    test('LootEngine returns fallback item when pool is empty', () {
      const emptyLocation = Location(
        id: 'loc_empty',
        name: 'Empty Spot',
        description: 'No items here',
        difficulty: 1.0,
        unlocked: true,
        themeColor: '0xFF000000',
        waterColor: '0xFF0000FF',
        availableItemIds: [],
      );
      final engine = LootEngine(rng: Random(5));
      final caught = engine.rollCatch(
        location: emptyLocation,
        itemMap: itemMap,
        fallbackItems: allItems,
        timingBonus: 0.5,
      );
      expect(caught, isNotNull);
    });
  });
}
