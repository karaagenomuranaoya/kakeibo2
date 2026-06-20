import 'package:flutter/material.dart';
import 'dart:math'; // ▼ 追加

class CategoryTag {
  final String id;
  final String label;
  final Color color;
  final bool isCircle;

  // --- クレジットカード設定用 ---
  final int? closingDay;
  final int? paymentDay;
  final int paymentMonthOffset;

  // --- アイコン保存用データ ---
  final int? iconCodePoint;
  final String? iconFontFamily;
  final String? iconFontPackage;

  static const String systemNoRecordId = 'system_no_record'; // 記録しない

  CategoryTag({
    String? id,
    required this.label,
    required this.color,
    this.isCircle = false,
    this.closingDay,
    this.paymentDay,
    this.paymentMonthOffset = 1,
    this.iconCodePoint,
    this.iconFontFamily,
    this.iconFontPackage,
  }) : id =
           id ??
           "${DateTime.now().microsecondsSinceEpoch}_${Random().nextInt(1000000)}";

  // 保存された情報からIconDataを復元するgetter
  IconData? get icon {
    if (iconCodePoint == null) return null;
    return IconData(
      iconCodePoint!,
      fontFamily: iconFontFamily,
      fontPackage: iconFontPackage,
    );
  }

  // ▼▼ 変更箇所：推定ロジックを削除し、なければデフォルトを返すだけに単純化 ▼▼
  // ▼▼ 修正 #8: コメント整理（推定ロジック削除完了） ▼▼
  IconData get displayIcon {
    // 設定されているアイコンがあればそれを返す
    if (icon != null) return icon!;

    // アイコン未設定時のデフォルト値
    return isCircle ? Icons.category : Icons.payment;
  }
  // ▲▲ 修正ここまで ▲▲

  factory CategoryTag.fromJson(Map<String, dynamic> json) {
    return CategoryTag(
      id: json['id'],
      label: json['label'],
      color: Color(json['color_value']),
      isCircle: json['is_circle'] ?? false,
      closingDay: json['closing_day'],
      paymentDay: json['payment_day'],
      paymentMonthOffset: json['payment_month_offset'] ?? 1,
      iconCodePoint: json['icon_code_point'],
      iconFontFamily: json['icon_font_family'],
      iconFontPackage: json['icon_font_package'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'label': label,
      'color_value': color.value,
      'is_circle': isCircle,
      'closing_day': closingDay,
      'payment_day': paymentDay,
      'payment_month_offset': paymentMonthOffset,
      'icon_code_point': iconCodePoint,
      'icon_font_family': iconFontFamily,
      'icon_font_package': iconFontPackage,
    };
  }

  // --- ヘルパー: アイコンデータ付きでCategoryTagを作るのを楽にする関数 ---
  static CategoryTag _create(
    String label,
    Color color,
    IconData iconData, {
    bool isCircle = true,
  }) {
    return CategoryTag(
      label: label,
      color: color,
      isCircle: isCircle,
      iconCodePoint: iconData.codePoint,
      iconFontFamily: iconData.fontFamily,
      iconFontPackage: iconData.fontPackage,
    );
  }

  static List<CategoryTag> get defaultCards => [
    CategoryTag(
      label: 'クレジット',
      color: Colors.redAccent,
      closingDay: 99,
      paymentDay: 27,
      paymentMonthOffset: 1,
      // カードもアイコン指定（任意）
      iconCodePoint: Icons.credit_card.codePoint,
      iconFontFamily: Icons.credit_card.fontFamily,
    ),
    CategoryTag(
      label: '交通系',
      color: Colors.green,
      iconCodePoint: Icons.directions_transit.codePoint,
      iconFontFamily: Icons.directions_transit.fontFamily,
    ),
  ];

  bool get isManageablePayment {
    // 固定ID（現金・記録しない）なら false
    if (id == systemNoRecordId) return false;
    return true;
  }

  // ▼▼ 変更箇所：ここでアイコンを明示的に指定することで、推定機能を不要にする ▼▼
  static List<CategoryTag> get defaultExpenses => [
    _create('食費', Colors.orange, Icons.restaurant),
    _create('日用品', Colors.lightGreen, Icons.shopping_bag),
    _create('交通費', Colors.blue, Icons.train),
    _create('交際費', Colors.pinkAccent, Icons.wine_bar),
    _create('趣味・娯楽', Colors.purple, Icons.sports_esports),
    _create('衣服・美容', Colors.teal, Icons.checkroom),
    _create('健康・医療', Colors.blueGrey, Icons.medical_services),
    _create('通信費', Colors.cyan, Icons.wifi),
    _create('住まい', Colors.brown, Icons.home),
  ];
}
