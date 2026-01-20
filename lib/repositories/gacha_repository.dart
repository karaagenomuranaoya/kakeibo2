import 'dart:convert';
import 'dart:math';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/gacha_item.dart';
import '../data/gacha_data.dart';

class GachaRepository {
  static const String _creditKey = 'gacha_credits';
  static const String _countsKey = 'gacha_counts_v2';
  static const String _initialBonusKey = 'gacha_initial_bonus_done';
  static const String _dailyCountKey = 'gacha_daily_count';
  static const String _lastDateKey = 'gacha_last_input_date';
  static const int _dailyLimit = 5;

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

  // ▼▼▼ 変更箇所: 殿堂入り対応の抽選ロジック ▼▼▼
  Future<GachaItem?> drawItem() async {
    await getItemCounts();
    final List<GachaItem> allItems = GachaData.monsters;

    // まず、Lv10未満のアイテム（育成中のキャラ）を探す
    List<GachaItem> candidates = allItems.where((item) {
      final count = _counts[item.id] ?? 0;
      return count < 10;
    }).toList();

    // もし育成中のキャラがいない（＝全員Lv10以上）なら、
    // 「殿堂入りモード」として全員を候補にする
    if (candidates.isEmpty) {
      candidates = allItems;
    }

    if (candidates.isEmpty) return null; // データ自体が空の場合

    // 重み付け抽選
    int totalWeight = candidates.fold(0, (int sum, item) => sum + item.weight);
    int randomValue = Random().nextInt(totalWeight);

    for (final item in candidates) {
      randomValue -= item.weight;
      if (randomValue < 0) return item;
    }
    return candidates.last;
  }
  // ▲▲▲ 変更ここまで ▲▲▲

  Future<int> getCredits() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_creditKey) ?? 0;
  }

  Future<void> checkInitialBonus() async {
    final prefs = await SharedPreferences.getInstance();
    final bool isDone = prefs.getBool(_initialBonusKey) ?? false;
    if (!isDone) {
      int current = prefs.getInt(_creditKey) ?? 0;
      await prefs.setInt(_creditKey, current + 3);
      await prefs.setBool(_initialBonusKey, true);
    }
  }

  Future<(int total, bool added)> addCredit() async {
    final prefs = await SharedPreferences.getInstance();
    int currentTotal = prefs.getInt(_creditKey) ?? 0;

    final now = DateTime.now();
    final todayStr = "${now.year}-${now.month}-${now.day}";
    final lastDate = prefs.getString(_lastDateKey);

    if (lastDate != todayStr) {
      await prefs.setString(_lastDateKey, todayStr);
      await prefs.setInt(_dailyCountKey, 0);
    }

    final int dailyCount = prefs.getInt(_dailyCountKey) ?? 0;
    if (dailyCount >= _dailyLimit) {
      //ここで5回制限をかけている
      return (currentTotal, false);
    }

    await prefs.setInt(_dailyCountKey, dailyCount + 1);
    currentTotal++;

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
