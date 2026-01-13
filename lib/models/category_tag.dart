import 'package:flutter/material.dart';

class CategoryTag {
  final String id;
  final String label;
  final Color color;
  final bool isCircle;

  CategoryTag({
    String? id,
    required this.label,
    required this.color,
    this.isCircle = false,
  }) : id = id ?? DateTime.now().microsecondsSinceEpoch.toString();

  // JSONから生成
  factory CategoryTag.fromJson(Map<String, dynamic> json) {
    return CategoryTag(
      id: json['id'],
      label: json['label'],
      color: Color(json['color_value']),
      isCircle: json['is_circle'] ?? false,
    );
  }

  // JSONへ変換
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'label': label,
      'color_value': color.toARGB32(), // 修正: value -> toARGB32() 推奨
      'is_circle': isCircle,
    };
  }

  // デフォルトの費目データ
  static List<CategoryTag> get defaultExpenses => [
        CategoryTag(label: '食費', color: Colors.orange, isCircle: true),
        CategoryTag(label: '日用品', color: Colors.green, isCircle: true),
        CategoryTag(label: '交通費', color: Colors.blue, isCircle: true),
        CategoryTag(label: '交際費', color: Colors.pink, isCircle: true),
        CategoryTag(label: '趣味', color: Colors.purple, isCircle: true),
        CategoryTag(label: '美容・衣服', color: Colors.teal, isCircle: true),
      ];

  // デフォルトのカードデータ
  static List<CategoryTag> get defaultCards => [
        CategoryTag(label: '楽天カード', color: Colors.red),
        CategoryTag(label: '三井住友', color: Colors.green),
        CategoryTag(label: 'PayPay', color: Colors.blueGrey),
        CategoryTag(label: 'Amex', color: Colors.blueAccent),
      ];
}
