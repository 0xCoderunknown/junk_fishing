import 'package:flutter_test/flutter_test.dart';
import 'package:junk_fishing/models/collection.dart';
import 'package:junk_fishing/models/fishing_state.dart';
import 'package:junk_fishing/models/item.dart';
import 'package:junk_fishing/models/location.dart';
import 'package:junk_fishing/models/player_state.dart';
import 'package:junk_fishing/utils/item_icon_helper.dart';

void main() {
  group('Models & State Tests', () {
    test('Item serialization and rarity stars', () {
      final item = Item(
        id: 'test_item',
        name: 'Quantum Rubber Duck',
        flavorText: 'It quacks in binary.',
        rarity: 4,
        estimatedValue: 420,
        collectionTag: 'Cryptic Curios',
        locationId: 'loc_rusty_dock',
        icon: 'smart_toy',
        weightKg: 1.2,
      );

      expect(item.rarityStars, '★★★★');
      final json = item.toJson();
      final fromJson = Item.fromJson(json);

      expect(fromJson.id, item.id);
      expect(fromJson.name, item.name);
      expect(fromJson.rarity, 4);
      expect(fromJson.estimatedValue, 420);
      expect(fromJson.weightKg, 1.2);
    });

    test('Location model parsing', () {
      final raw = {
        'id': 'loc_test',
        'name': 'Radioactive Creek',
        'description': 'A cheerful green glow.',
        'difficulty': 1.5,
        'unlocked': true,
        'themeColor': '0xFF112233',
        'waterColor': '0xFF445566',
        'availableItemIds': ['item1', 'item2'],
      };

      final location = Location.fromJson(raw);
      expect(location.id, 'loc_test');
      expect(location.difficulty, 1.5);
      expect(location.availableItemIds.length, 2);
    });

    test('Collection progress calculation', () {
      const collection = Collection(
        id: 'col_test',
        name: 'Odd Gadgets',
        description: 'Rare junk.',
        rewardMoney: 1000,
        itemIds: ['item_a', 'item_b', 'item_c', 'item_d'],
      );

      final discovered = {'item_a', 'item_b'};
      expect(collection.progress(discovered), 0.5);
      expect(collection.isComplete(discovered), false);

      final full = {'item_a', 'item_b', 'item_c', 'item_d', 'extra_item'};
      expect(collection.progress(full), 1.0);
      expect(collection.isComplete(full), true);
    });

    test('PlayerState storage, bait, and copyWith', () {
      final player = PlayerState.initial();
      expect(player.money, 100);
      expect(player.baitCount, 15);
      expect(player.storageLimit, 20);
      expect(player.canFish, true);
      expect(player.hasStorageSpace, true);

      // Inventory full condition
      final fullInventory = List.generate(
        20,
        (i) => Item(
          id: 'item_$i',
          name: 'Scrap $i',
          flavorText: '',
          rarity: 1,
          estimatedValue: 10,
          collectionTag: '',
          locationId: '',
        ),
      );

      final fullPlayer = player.copyWith(inventory: fullInventory);
      expect(fullPlayer.hasStorageSpace, false);
      expect(fullPlayer.canFish, false);

      // Out of bait condition
      final noBaitPlayer = player.copyWith(baitCount: 0);
      expect(noBaitPlayer.canFish, false);
    });

    test('FishingState enum sequence matches state machine charter', () {
      expect(FishingState.values, [
        FishingState.idleMenu,
        FishingState.readyToCast,
        FishingState.rippleActive,
        FishingState.pullingRod,
        FishingState.resultModal,
      ]);
    });

    test('Item icon and rarity color helpers return valid assets', () {
      expect(getItemIconData('memory'), isNotNull);
      expect(getItemIconData('unknown_icon'), isNotNull);
      expect(getRarityColor(1), isNotNull);
      expect(getRarityColor(5), isNotNull);
    });
  });
}
