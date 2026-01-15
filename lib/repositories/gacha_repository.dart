import 'dart:convert';
import 'dart:math';
import 'package:flutter/foundation.dart'; // kDebugModeを使うために必要
import 'package:shared_preferences/shared_preferences.dart';
import '../models/gacha_item.dart';
import '../data/gacha_data.dart';

class GachaRepository {
  static const String _creditKey = 'gacha_credits';
  static const String _countsKey = 'gacha_counts_v2';

  Map<String, int> _counts = {};

  Future<List<GachaItem>> getItems() async {
    return GachaData.monsters;
  }

  Future<Map<String, int>> getItemCounts() async {
    if (_counts.isEmpty) await _loadCounts();
    return _counts;
  }

  Future<void> _loadCounts() async {
    final prefs = await SharedPreferences.getInstance();
    final String? jsonString = prefs.getString(_countsKey);
    if (jsonString != null) {
      final Map<String, dynamic> decoded = json.decode(jsonString);
      _counts = decoded.map((key, value) => MapEntry(key, value as int));
    }
  }

  Future<void> _saveCounts() async {
    final prefs = await SharedPreferences.getInstance();
    final String jsonString = json.encode(_counts);
    await prefs.setString(_countsKey, jsonString);
  }

  Future<int> unlockItem(String id) async {
    await getItemCounts();
    int current = _counts[id] ?? 0;
    current++;
    _counts[id] = current;
    await _saveCounts();
    return current;
  }

  Future<GachaItem> drawItem() async {
    final List<GachaItem> items = GachaData.monsters;
    int totalWeight = items.fold(0, (int sum, item) => sum + item.weight);
    int randomValue = Random().nextInt(totalWeight);

    for (final item in items) {
      randomValue -= item.weight;
      if (randomValue < 0) return item;
    }
    return items.last;
  }

  // --- クレジット管理 ---
  Future<int> getCredits() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_creditKey) ?? 0;
  }

  // 入力時の加算（デバッグモードなら+10000）
  Future<int> addCredit() async {
    final prefs = await SharedPreferences.getInstance();
    int current = prefs.getInt(_creditKey) ?? 0;

    if (kDebugMode) {
      current += 10000;
    } else {
      current++;
    }

    await prefs.setInt(_creditKey, current);
    return current;
  }

  // ▼▼ 追加: 任意のポイントを加算する（被り救済用など） ▼▼
  Future<int> addCredits(int amount) async {
    final prefs = await SharedPreferences.getInstance();
    int current = prefs.getInt(_creditKey) ?? 0;
    current += amount;
    await prefs.setInt(_creditKey, current);
    return current;
  }

  Future<bool> consumeCredits(int amount) async {
    final prefs = await SharedPreferences.getInstance();
    int current = prefs.getInt(_creditKey) ?? 0;
    if (current >= amount) {
      await prefs.setInt(_creditKey, current - amount);
      return true;
    }
    return false;
  }
}
