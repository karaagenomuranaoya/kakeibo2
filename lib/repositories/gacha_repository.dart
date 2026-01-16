import 'dart:convert';
import 'dart:math';
import 'package:flutter/foundation.dart'; // kDebugModeを使うために必要
import 'package:shared_preferences/shared_preferences.dart';
import '../models/gacha_item.dart';
import '../data/gacha_data.dart';

class GachaRepository {
  static const String _creditKey = 'gacha_credits';
  static const String _countsKey = 'gacha_counts_v2';

  // 日次制限用のキー
  static const String _dailyCountKey = 'gacha_daily_count';
  static const String _lastDateKey = 'gacha_last_input_date';
  static const int _dailyLimit = 15; // 1日15回（ガチャ5回分）

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

  /// ガチャを引く
  Future<GachaItem?> drawItem() async {
    await getItemCounts();
    final List<GachaItem> allItems = GachaData.monsters;

    final List<GachaItem> candidates = allItems.where((item) {
      final count = _counts[item.id] ?? 0;
      return count < 10;
    }).toList();

    if (candidates.isEmpty) {
      return null;
    }

    int totalWeight = candidates.fold(0, (int sum, item) => sum + item.weight);
    int randomValue = Random().nextInt(totalWeight);

    for (final item in candidates) {
      randomValue -= item.weight;
      if (randomValue < 0) return item;
    }
    return candidates.last;
  }

  // --- クレジット管理 ---
  Future<int> getCredits() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_creditKey) ?? 0;
  }

  // 入力時の加算（戻り値を (現在の合計, 加算されたか) に変更）
  Future<(int total, bool added)> addCredit() async {
    final prefs = await SharedPreferences.getInstance();
    int currentTotal = prefs.getInt(_creditKey) ?? 0;

    // --- 日次制限チェック ---
    if (!kDebugMode) {
      final now = DateTime.now();
      final todayStr = "${now.year}-${now.month}-${now.day}";
      final lastDate = prefs.getString(_lastDateKey);

      // 日付が変わっていればリセット
      if (lastDate != todayStr) {
        await prefs.setString(_lastDateKey, todayStr);
        await prefs.setInt(_dailyCountKey, 0);
      }

      final int dailyCount = prefs.getInt(_dailyCountKey) ?? 0;

      // 上限チェック (15回以上なら加算せずリターン)
      if (dailyCount >= _dailyLimit) {
        return (currentTotal, false);
      }

      // 回数をインクリメント
      await prefs.setInt(_dailyCountKey, dailyCount + 1);
    }
    // -----------------------

    // 加算処理
    if (kDebugMode) {
      currentTotal += 10000;
    } else {
      currentTotal++;
    }

    await prefs.setInt(_creditKey, currentTotal);
    return (currentTotal, true);
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
