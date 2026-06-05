import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:atsumeru_kakeibo/repositories/gacha_repository.dart';
import 'package:atsumeru_kakeibo/data/gacha_data.dart';

void main() {
  group('GachaRepository Tests', () {
    late GachaRepository repository;

    setUp(() {
      SharedPreferences.setMockInitialValues({});
      repository = GachaRepository();
    });

    test('Initial credits should be 0', () async {
      expect(await repository.getCredits(), 0);
    });

    test('Initial Bonus adds 3 credits only once', () async {
      await repository.checkInitialBonus();
      expect(await repository.getCredits(), 3);

      await repository.checkInitialBonus();
      expect(await repository.getCredits(), 3); // Still 3
    });

    test('addCredit respects daily limit', () async {
      // 1st time
      var result = await repository.addCredit();
      expect(result.$2, true);
      expect(result.$1, 1);

      // 2, 3, 4, 5
      await repository.addCredit();
      await repository.addCredit();
      await repository.addCredit();
      await repository.addCredit();
      expect(await repository.getCredits(), 5);

      // 6th time (should fail)
      result = await repository.addCredit();
      expect(result.$2, false); // Not added
      expect(result.$1, 5); // Total remains 5
    });

    test('consumeCredits works correctly', () async {
      // Add some credits first
      await repository.checkInitialBonus(); // +3

      expect(await repository.consumeCredits(1), true);
      expect(await repository.getCredits(), 2);

      expect(await repository.consumeCredits(3), false); // Not enough
      expect(await repository.getCredits(), 2); // Unchanged
    });

    test('unlockItem increments count', () async {
      final itemId = GachaData.monsters.first.id;

      int count = await repository.unlockItem(itemId);
      expect(count, 1);

      count = await repository.unlockItem(itemId);
      expect(count, 2);

      final counts = await repository.getItemCounts();
      expect(counts[itemId], 2);
    });

    test('drawItem returns unmaxed item if available', () async {
      // Create a scenario where only one item is NOT maxed (Lv 10)
      final allItems = await repository.getItems();
      final targetItem = allItems.last;

      // Prepare counts: everyone else is 10
      Map<String, int> counts = {};
      for (var item in allItems) {
        if (item.id != targetItem.id) {
          counts[item.id] = 10;
        } else {
          counts[item.id] = 0;
        }
      }

      // Inject into SP
      SharedPreferences.setMockInitialValues({
        'gacha_counts_v2': json.encode(counts),
      });

      // Re-initialize repository or just call method (it loads counts)
      final drawnItem = await repository.drawItem();

      expect(drawnItem, isNotNull);
      expect(drawnItem!.id, targetItem.id); // Must be the only unmaxed one
    });

    test('drawItem works in Hall of Fame mode (all maxed)', () async {
      // Create a scenario where ALL items are maxed (Lv 10)
      final allItems = await repository.getItems();

      Map<String, int> counts = {};
      for (var item in allItems) {
        counts[item.id] = 10;
      }

      SharedPreferences.setMockInitialValues({
        'gacha_counts_v2': json.encode(counts),
      });

      final drawnItem = await repository.drawItem();
      expect(drawnItem, isNotNull); // Should still return something, not null
      // It will pick one randomly from all items
    });
  });
}
