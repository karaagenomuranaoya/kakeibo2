import 'package:flutter/material.dart';
import '../models/bonus_item.dart';

/// ボーナスのマスターデータ定義
class BonusData {
  static const List<BonusItem> list = [
    BonusItem(
      targetDays: 3,
      icon: Icons.save,
      color: Colors.green,
      title: "芽生えの精霊",
      description: "家計簿生活の第一歩。\n小さな芽が出てきました。データ使えてるかい？",
    ),
    BonusItem(
      targetDays: 7,
      icon: Icons.directions_walk,
      color: Colors.orange,
      title: "ウォーキングマン",
      description: "継続は力なり。\n毎日コツコツ歩き続けよう。",
    ),
    BonusItem(
      targetDays: 14,
      icon: Icons.rowing,
      color: Colors.blue,
      title: "ボート漕ぎの達人",
      description: "荒波もなんのその。\n流れに乗って進め。",
    ),
    BonusItem(
      targetDays: 21,
      icon: Icons.flight_takeoff,
      color: Colors.indigo,
      title: "ジェットパイロット",
      description: "習慣が板についてきた。\n空高く舞い上がれ。",
    ),
    BonusItem(
      targetDays: 30,
      icon: Icons.diamond,
      color: Colors.cyan,
      title: "クリスタルガーディアン",
      description: "1ヶ月の継続の証。\n硬い意志は宝石の輝き。",
    ),
    BonusItem(
      targetDays: 50,
      icon: Icons.rocket_launch,
      color: Colors.redAccent,
      title: "マーズボイジャー",
      description: "とどまることを知らない。\n目指すは遥か彼方。",
    ),
    BonusItem(
      targetDays: 100,
      icon: Icons.auto_awesome,
      color: Colors.amber,
      title: "伝説の記録者",
      description: "百日の記録を刻みし者。\nその背中には後光が差す。",
    ),
    BonusItem(
      targetDays: 365,
      icon: Icons.castle,
      color: Colors.purple,
      title: "一年城の王",
      description: "四季を巡り辿り着いた。\nここはあなたの城。",
    ),
  ];
}
