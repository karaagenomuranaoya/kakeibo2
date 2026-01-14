import 'package:flutter/material.dart';

class CategoryTag {
  final String id;
  final String label;
  final Color color;
  final bool isCircle;

  // --- クレジットカード設定用 ---
  // null なら「通常モード（即時払い扱い）」、値があれば「締め日モード」
  final int? closingDay; // 締め日 (1-28, 99=末日)
  final int? paymentDay; // 支払日 (1-28, 99=末日)
  final int paymentMonthOffset; // 支払月 (1=翌月, 2=翌々月)

  CategoryTag({
    String? id,
    required this.label,
    required this.color,
    this.isCircle = false,
    this.closingDay,
    this.paymentDay,
    this.paymentMonthOffset = 1, // デフォルトは翌月払い
  }) : id = id ?? DateTime.now().microsecondsSinceEpoch.toString();

  // JSONから生成
  factory CategoryTag.fromJson(Map<String, dynamic> json) {
    return CategoryTag(
      id: json['id'],
      label: json['label'],
      color: Color(json['color_value']),
      isCircle: json['is_circle'] ?? false,
      closingDay: json['closing_day'],
      paymentDay: json['payment_day'],
      paymentMonthOffset: json['payment_month_offset'] ?? 1,
    );
  }

  // JSONへ変換
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'label': label,
      'color_value': color.value, // toARGB32()が使えない環境への互換性のためvalue推奨
      'is_circle': isCircle,
      'closing_day': closingDay,
      'payment_day': paymentDay,
      'payment_month_offset': paymentMonthOffset,
    };
  }

  // デフォルトのカードデータ（例として楽天カードを末締め翌27日払いに設定）
  static List<CategoryTag> get defaultCards => [
        CategoryTag(
          label: '楽天カード',
          color: Colors.red,
          closingDay: 99, // 末日
          paymentDay: 27, // 27日払い
          paymentMonthOffset: 1, // 翌月
        ),
        CategoryTag(
          label: '三井住友',
          color: Colors.green,
          closingDay: 15, // 15日締め
          paymentDay: 10, // 10日払い
          paymentMonthOffset: 1, // 翌月
        ),
        CategoryTag(label: 'PayPay', color: Colors.blueGrey), // 設定なし（即時）
      ];

  // デフォルトの費目データ（変更なし）
  static List<CategoryTag> get defaultExpenses => [
        CategoryTag(label: '食費', color: Colors.orange, isCircle: true),
        CategoryTag(label: '日用品', color: Colors.green, isCircle: true),
        CategoryTag(label: '交通費', color: Colors.blue, isCircle: true),
        CategoryTag(label: '交際費', color: Colors.pink, isCircle: true),
        CategoryTag(label: '趣味', color: Colors.purple, isCircle: true),
        CategoryTag(label: '美容・衣服', color: Colors.teal, isCircle: true),
      ];
}
