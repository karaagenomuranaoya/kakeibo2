import 'package:flutter/material.dart';

class GachaItem {
  final String id;
  final int rarity;
  final int weight;
  final IconData iconData;
  final String baseName;
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
  // ※バッジ表示や説明文用には最大10で止める
  int getStage(int count) {
    if (count <= 0) return 0; // 未所持
    if (count > 10) return 10; // カンスト
    return count;
  }

  // ステージごとの色定義 (Lv1〜Lv10)
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
    // 未所持
    if (count <= 0) return Colors.grey;

    // Lv1〜Lv10: 固定色
    if (count <= 10) {
      int index = count - 1;
      return _stageColors[index];
    }

    // Lv11以降: 殿堂入り（無限色変化）
    // カウントをシードにして色相(Hue)を回転させる
    // 黄金角 (約137.5度) を使うと色が綺麗に分散する
    final double hue = (count * 137.508) % 360;

    // HSVからColorに変換 (彩度と明度は見やすい値に固定)
    return HSVColor.fromAHSV(1.0, hue, 0.7, 0.95).toColor();
  }

  // ステージに応じた名前を取得
  String getName(int count) {
    final stage = getStage(count);
    if (stage == 0) return "???";

    int safeIndex = stage - 1;
    if (safeIndex >= _stagePrefixes.length) {
      safeIndex = _stagePrefixes.length - 1;
    }

    // Lv11以上の場合、名前の後ろにエクストラ表示をつけるなどの工夫も可能ですが
    // 今回は名前はそのままで色が変化する仕様とします
    return "${_stagePrefixes[safeIndex]}$baseName";
  }

  // ステージに応じた説明文をリストから取得
  String getDescription(int count) {
    final stage = getStage(count);
    if (stage == 0) return "";

    int safeIndex = stage - 1;
    if (safeIndex >= descriptions.length) {
      return "（説明文データがありません）";
    }
    return descriptions[safeIndex];
  }
}
