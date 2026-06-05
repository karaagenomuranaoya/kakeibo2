import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:atsumeru_kakeibo/models/category_tag.dart';
import 'package:atsumeru_kakeibo/repositories/settings_repository.dart';

void main() {
  group('SettingsRepository Tests', () {
    late SettingsRepository repository;

    setUp(() {
      SharedPreferences.setMockInitialValues({}); // Reset SP
      repository = SettingsRepository();
    });

    test('loadExpenseTags returns defaults when storage is empty', () async {
      final tags = await repository.loadExpenseTags();
      expect(tags, isNotEmpty);
      expect(tags.first.label, '食費'); // Check Default
    });

    test('saveExpenseTags and loadExpenseTags work correctly', () async {
      final newTag = CategoryTag(label: 'NewTag', color: Colors.red);
      await repository.saveExpenseTags([newTag]);

      final loadedTags = await repository.loadExpenseTags();
      expect(loadedTags.length, 1);
      expect(loadedTags.first.label, 'NewTag');
      expect(loadedTags.first.id, newTag.id);
    });

    test('loadExpenseTags sanitizes duplicate IDs', () async {
      // Manually inject bad JSON with duplicate IDs
      const dupId = 'duplicate-id';
      const jsonString =
          '[{"id":"$dupId","label":"A","color_value":0},'
          '{"id":"$dupId","label":"B","color_value":0}]';

      SharedPreferences.setMockInitialValues({'expense_tags_list': jsonString});

      final loadedTags = await repository.loadExpenseTags();
      expect(loadedTags.length, 2);
      expect(loadedTags[0].id, dupId);
      expect(loadedTags[1].id, isNot(dupId)); // Should be regenerated
      expect(loadedTags[1].label, 'B');
    });

    test('loadCardTags returns defaults when storage is empty', () async {
      final tags = await repository.loadCardTags();
      expect(tags, isNotEmpty);
      expect(tags.first.label, 'クレジット');
    });

    test('Boolean settings work correctly', () async {
      // Defaults
      expect(await repository.loadGachaEnabled(), true);
      expect(await repository.loadVibrationEnabled(), true);

      // Save & Load
      await repository.saveGachaEnabled(false);
      expect(await repository.loadGachaEnabled(), false);

      await repository.saveVibrationEnabled(false);
      expect(await repository.loadVibrationEnabled(), false);
    });
  });
}
