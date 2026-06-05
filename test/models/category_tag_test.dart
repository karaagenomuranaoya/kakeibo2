import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:atsumeru_kakeibo/models/category_tag.dart';

void main() {
  group('CategoryTag Tests', () {
    test('Constructor generates random ID if null', () {
      final tag1 = CategoryTag(label: 'Tag1', color: Colors.red);
      final tag2 = CategoryTag(label: 'Tag2', color: Colors.blue);

      expect(tag1.id, isNotEmpty);
      expect(tag2.id, isNotEmpty);
      expect(tag1.id, isNot(tag2.id));
    });

    test('toJson converts object to map correctly', () {
      final tag = CategoryTag(
        id: 'test-id',
        label: 'Test Label',
        color: Colors.red,
        isCircle: true,
        closingDay: 20,
        paymentDay: 10,
        paymentMonthOffset: 2,
        iconCodePoint: 12345,
        iconFontFamily: 'MaterialIcons',
        iconFontPackage: 'flutter_icons',
      );

      final json = tag.toJson();

      expect(json['id'], 'test-id');
      expect(json['label'], 'Test Label');
      expect(json['color_value'], Colors.red.value);
      expect(json['is_circle'], true);
      expect(json['closing_day'], 20);
      expect(json['payment_day'], 10);
      expect(json['payment_month_offset'], 2);
      expect(json['icon_code_point'], 12345);
      expect(json['icon_font_family'], 'MaterialIcons');
      expect(json['icon_font_package'], 'flutter_icons');
    });

    test('fromJson creates object from map correctly', () {
      final json = {
        'id': 'json-id',
        'label': 'Json Label',
        'color_value': Colors.blue.value,
        'is_circle': false,
        'closing_day': 15,
        'payment_day': 5,
        'payment_month_offset': 1,
        'icon_code_point': 67890,
        'icon_font_family': 'CupertinoIcons',
        'icon_font_package': 'cupertino_icons',
      };

      final tag = CategoryTag.fromJson(json);

      expect(tag.id, 'json-id');
      expect(tag.label, 'Json Label');
      expect(tag.color.value, Colors.blue.value);
      expect(tag.isCircle, false);
      expect(tag.closingDay, 15);
      expect(tag.paymentDay, 5);
      expect(tag.paymentMonthOffset, 1);
      expect(tag.iconCodePoint, 67890);
      expect(tag.iconFontFamily, 'CupertinoIcons');
      expect(tag.iconFontPackage, 'cupertino_icons');
    });

    test('icon and displayIcon work correctly', () {
      // With icon data
      final tagWithIcon = CategoryTag(
        label: 'Icon',
        color: Colors.white,
        iconCodePoint: Icons.home.codePoint,
        iconFontFamily: Icons.home.fontFamily,
      );
      expect(tagWithIcon.icon, isNotNull);
      expect(tagWithIcon.icon!.codePoint, Icons.home.codePoint);
      expect(tagWithIcon.displayIcon.codePoint, Icons.home.codePoint);

      // Without icon data (Fallback)
      final tagNoIcon = CategoryTag(
        label: 'No Icon',
        color: Colors.white,
        isCircle: true,
      );
      expect(tagNoIcon.icon, isNull);
      expect(
        tagNoIcon.displayIcon,
        Icons.category,
      ); // Fallback for isCircle=true

      final tagNoIconPayment = CategoryTag(
        label: 'Payment',
        color: Colors.white,
        isCircle: false,
      );
      expect(
        tagNoIconPayment.displayIcon,
        Icons.payment,
      ); // Fallback for isCircle=false
    });

    test('isManageablePayment returns correct boolean', () {
      final normalTag = CategoryTag(label: 'Normal', color: Colors.white);
      expect(normalTag.isManageablePayment, true);

      final systemTag = CategoryTag(
        id: CategoryTag.systemNoRecordId,
        label: 'System',
        color: Colors.white,
      );
      expect(systemTag.isManageablePayment, false);
    });

    test('defaultExpenses returns non-empty list', () {
      final defaults = CategoryTag.defaultExpenses;
      expect(defaults, isNotEmpty);
      expect(defaults.first.label, '食費');
    });

    test('defaultCards returns non-empty list', () {
      final defaults = CategoryTag.defaultCards;
      expect(defaults, isNotEmpty);
      expect(defaults.first.label, 'クレジット');
    });
  });
}
