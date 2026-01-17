import 'package:flutter/material.dart';

/// ボーナスアイテムのモデル定義
class BonusItem {
  final int targetDays;
  final IconData icon;
  final Color color;
  final String title;
  final String description;

  const BonusItem({
    required this.targetDays,
    required this.icon,
    required this.color,
    required this.title,
    required this.description,
  });
}
