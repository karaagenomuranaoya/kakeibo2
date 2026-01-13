import 'package:flutter/material.dart';

class CategoryTag {
  final String label;
  final Color color;
  final bool isCircle;

  const CategoryTag(this.label, this.color, {this.isCircle = false});
}

// 費目タグ
final List<CategoryTag> expenseTags = [
  CategoryTag('食費', Colors.orange, isCircle: true),
  CategoryTag('日用品', Colors.green, isCircle: true),
  CategoryTag('交通費', Colors.blue, isCircle: true),
  CategoryTag('交際費', Colors.pink, isCircle: true),
  CategoryTag('趣味', Colors.purple, isCircle: true),
];

// ▼▼ 1. クレジットカード一覧（入力画面のカード選択用） ▼▼
final List<CategoryTag> creditCardTags = [
  CategoryTag('楽天カード', Colors.red),
  CategoryTag('三井住友', Colors.green),
  CategoryTag('PayPayカード', Colors.blueGrey),
  CategoryTag('Amex', Colors.blueAccent),
];

// ▼▼ 2. 支払い方法全リスト（履歴、ドロワー、設定画面用） ▼▼
// エラーの原因：ここが消えていたため復活させます。
// 「現金」と「上記のカードリスト」を結合したものです。
final List<CategoryTag> paymentTags = [
  const CategoryTag('現金', Colors.grey),
  ...creditCardTags, // カードリストを展開して追加
];
