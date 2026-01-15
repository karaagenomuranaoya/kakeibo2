import 'package:flutter/material.dart';

class CategoryTag {
  final String id;
  final String label;
  final Color color;
  final bool isCircle;

  // --- クレジットカード設定用 ---
  final int? closingDay; // 締め日 (1-28, 99=末日)
  final int? paymentDay; // 支払日 (1-28, 99=末日)
  final int paymentMonthOffset; // 支払月 (1=翌月, 2=翌々月)

  // --- ▼▼ 追加: アイコン保存用データ ▼▼ ---
  final int? iconCodePoint;
  final String? iconFontFamily;
  final String? iconFontPackage;

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
  }) : id = id ?? DateTime.now().microsecondsSinceEpoch.toString();

  // 保存された情報からIconDataを復元するgetter
  IconData? get icon {
    if (iconCodePoint == null) return null;
    return IconData(
      iconCodePoint!,
      fontFamily: iconFontFamily,
      fontPackage: iconFontPackage,
    );
  }

  factory CategoryTag.fromJson(Map<String, dynamic> json) {
    return CategoryTag(
      id: json['id'],
      label: json['label'],
      color: Color(json['color_value']),
      isCircle: json['is_circle'] ?? false,
      closingDay: json['closing_day'],
      paymentDay: json['payment_day'],
      paymentMonthOffset: json['payment_month_offset'] ?? 1,
      // ▼▼ アイコン情報の読み込み ▼▼
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
      // ▼▼ アイコン情報の保存 ▼▼
      'icon_code_point': iconCodePoint,
      'icon_font_family': iconFontFamily,
      'icon_font_package': iconFontPackage,
    };
  }

  // デフォルトデータ（変更なし）
  static List<CategoryTag> get defaultCards => [
    CategoryTag(
      label: '楽天カード',
      color: Colors.red,
      closingDay: 99,
      paymentDay: 27,
      paymentMonthOffset: 1,
    ),
    CategoryTag(
      label: '三井住友',
      color: Colors.green,
      closingDay: 15,
      paymentDay: 10,
      paymentMonthOffset: 1,
    ),
    CategoryTag(label: 'PayPay', color: Colors.blueGrey),
  ];

  static List<CategoryTag> get defaultExpenses => [
    CategoryTag(label: '食費', color: Colors.orange, isCircle: true),
    CategoryTag(label: '日用品', color: Colors.green, isCircle: true),
    CategoryTag(label: '交通費', color: Colors.blue, isCircle: true),
    CategoryTag(label: '交際費', color: Colors.pink, isCircle: true),
    CategoryTag(label: '趣味', color: Colors.purple, isCircle: true),
    CategoryTag(label: '美容・衣服', color: Colors.teal, isCircle: true),
  ];
}
