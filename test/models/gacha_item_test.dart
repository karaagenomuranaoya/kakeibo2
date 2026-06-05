import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:atsumeru_kakeibo/models/gacha_item.dart';

void main() {
  group('GachaItem Tests', () {
    const testItem = GachaItem(
      id: 'test_id',
      rarity: 1,
      weight: 1,
      iconData: Icons.star,
      baseName: 'アイテム',
      descriptions: [
        'Desc 1',
        'Desc 2',
        'Desc 3',
        'Desc 4',
        'Desc 5',
        'Desc 6',
        'Desc 7',
        'Desc 8',
        'Desc 9',
        'Desc 10',
      ],
    );

    test('getStage caps value correctly', () {
      expect(testItem.getStage(0), 0);
      expect(testItem.getStage(-1), 0);
      expect(testItem.getStage(1), 1);
      expect(testItem.getStage(5), 5);
      expect(testItem.getStage(10), 10);
      expect(testItem.getStage(11), 10);
      expect(testItem.getStage(100), 10);
    });

    test('getName returns correct name with prefix', () {
      expect(testItem.getName(0), '???');

      // Index 0 in _stagePrefixes is "迷子の"
      expect(testItem.getName(1), '迷子のアイテム');

      // Index 9 in _stagePrefixes is "伝説の"
      expect(testItem.getName(10), '伝説のアイテム');

      // Should stick to max stage prefix
      expect(testItem.getName(100), '伝説のアイテム');
    });

    test('getColor returns correct colors', () {
      // Unowned
      expect(testItem.getColor(0), Colors.grey);

      // Stage 1 (Index 0) -> Colors.grey
      expect(testItem.getColor(1), Colors.grey);

      // Stage 10 (Index 9) -> Colors.amber
      expect(testItem.getColor(10), Colors.amber);

      // Stage 11 -> Dynamic HSV color
      // Just check it's not null and returns a color
      final color11 = testItem.getColor(11);
      expect(color11, isA<Color>());
      expect(color11, isNot(Colors.amber)); // Should be different
    });

    test('getDescription returns correct text', () {
      expect(testItem.getDescription(0), '');
      expect(testItem.getDescription(1), 'Desc 1');
      expect(testItem.getDescription(10), 'Desc 10');

      // Even if count > 10, it uses stage 10 which maps to index 9
      expect(testItem.getDescription(11), 'Desc 10');
    });

    test('getDescription handles missing descriptions gracefully', () {
      const shortItem = GachaItem(
        id: 'short',
        rarity: 1,
        weight: 1,
        iconData: Icons.star,
        baseName: 'Short',
        descriptions: ['Only One'],
      );

      expect(shortItem.getDescription(1), 'Only One');
      // Stage 2 (Index 1) does not exist in descriptions
      expect(shortItem.getDescription(2), '（説明文データがありません）');
    });
  });
}
