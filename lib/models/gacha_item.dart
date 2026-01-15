import 'package:flutter/material.dart';

class GachaItem {
  final String id;
  final int rarity;
  final int weight;
  final IconData iconData;
  final String baseName;
  // 変更: 説明文を1つではなく、レベルごとのリストに変更
  final List<String> descriptions;

  const GachaItem({
    required this.id,
    required this.rarity,
    required this.weight,
    required this.iconData,
    required this.baseName,
    required this.descriptions,
  });

  // 現在のステージを判定 (1〜10)
  int getStage(int count) {
    if (count <= 0) return 0; // 未所持
    if (count > 10) return 10; // カンスト
    return count;
  }

  // ステージごとの色定義
  static const List<Color> _stageColors = [
    Colors.grey, // Lv1
    Colors.brown, // Lv2
    Colors.blueGrey, // Lv3
    Colors.green, // Lv4
    Colors.cyan, // Lv5
    Colors.blue, // Lv6
    Colors.indigo, // Lv7
    Colors.purple, // Lv8
    Colors.red, // Lv9
    Colors.amber, // Lv10
  ];

  // ステージごとの称号（Prefix）
  static const List<String> _stagePrefixes = [
    "迷子の", // Lv1
    "見習い", // Lv2
    "駆け出し", // Lv3
    "一人前の", // Lv4
    "熟練の", // Lv5
    "達人の", // Lv6
    "師範代", // Lv7
    "将軍", // Lv8
    "英雄", // Lv9
    "伝説の", // Lv10
  ];

  // ステージに応じた色を取得
  Color getColor(int count) {
    final stage = getStage(count);
    // countがレベルとして渡される場合と、1~10のindexとして渡される場合の両方に対応
    // ここでは count が 1以上前提のロジックで安全策をとる
    int safeIndex = stage - 1;
    if (safeIndex < 0) safeIndex = 0;
    if (safeIndex >= _stageColors.length) safeIndex = _stageColors.length - 1;

    return _stageColors[safeIndex];
  }

  // ステージに応じた名前を取得
  String getName(int count) {
    final stage = getStage(count);
    if (stage == 0) return "???";

    int safeIndex = stage - 1;
    if (safeIndex >= _stagePrefixes.length)
      safeIndex = _stagePrefixes.length - 1;

    return "${_stagePrefixes[safeIndex]}$baseName";
  }

  // 変更: ステージに応じた説明文をリストから取得
  String getDescription(int count) {
    final stage = getStage(count);
    if (stage == 0) return "";

    int safeIndex = stage - 1;
    // データ不足エラー回避
    if (safeIndex >= descriptions.length) {
      return "（説明文データがありません）";
    }
    return descriptions[safeIndex];
  }

  factory GachaItem.fromJson(Map<String, dynamic> json) {
    return GachaItem(
      id: json['id'] as String,
      rarity: json['rarity'] as int? ?? 1,
      weight: json['weight'] as int? ?? 10,
      iconData: Icons.help_outline,
      baseName: '不明なデータ',
      descriptions: ['データ読み込みエラー'],
    );
  }
}
