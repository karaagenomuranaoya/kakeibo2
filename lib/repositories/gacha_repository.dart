import 'dart:convert';
import 'dart:math';
import 'package:flutter/services.dart' show rootBundle;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/gacha_item.dart';

class GachaRepository {
  static const String _creditKey = 'gacha_credits';
  static const String _countsKey = 'gacha_counts_v2';
  static const String _masterDataPath = 'assets/json/gacha_master.json';

  List<GachaItem> _items = [];
  bool _isLoaded = false;
  Map<String, int> _counts = {};

  Future<List<GachaItem>> getItems() async {
    if (!_isLoaded) await _loadMasterData();
    return _items;
  }

  Future<Map<String, int>> getItemCounts() async {
    if (_counts.isEmpty) await _loadCounts();
    return _counts;
  }

  Future<void> _loadMasterData() async {
    try {
      final String jsonString = await rootBundle.loadString(_masterDataPath);
      final List<dynamic> jsonList = json.decode(jsonString);
      _items = jsonList.map((e) => GachaItem.fromJson(e)).toList();
      _items.sort((a, b) => int.parse(a.id).compareTo(int.parse(b.id)));
      _isLoaded = true;
    } catch (e) {
      // ▼▼ 修正箇所: name3, description3 を追加しました ▼▼
      _items = [
        const GachaItem(
          id: '1',
          rarity: 1,
          weight: 1,
          name1: 'データ読込エラー',
          description1: 'JSONデータを確認してください',
          name2: 'データ読込エラー',
          description2: 'JSONデータを確認してください',
          name3: 'データ読込エラー',
          description3: 'JSONデータを確認してください',
        ),
      ];
      _isLoaded = true;
    }
  }

  Future<void> _loadCounts() async {
    final prefs = await SharedPreferences.getInstance();
    final String? jsonString = prefs.getString(_countsKey);
    if (jsonString != null) {
      final Map<String, dynamic> decoded = json.decode(jsonString);
      _counts = decoded.map((key, value) => MapEntry(key, value as int));
    } else {
      const oldKey = 'gacha_collection';
      final List<String>? oldList = prefs.getStringList(oldKey);
      if (oldList != null) {
        for (var id in oldList) {
          _counts[id] = 1;
        }
        await _saveCounts();
      }
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
    if (!_isLoaded) await _loadMasterData();
    int totalWeight = _items.fold(0, (sum, item) => sum + item.weight);
    int randomValue = Random().nextInt(totalWeight);
    for (final item in _items) {
      randomValue -= item.weight;
      if (randomValue < 0) return item;
    }
    return _items.last;
  }

  // --- クレジット管理 ---
  Future<int> getCredits() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_creditKey) ?? 0;
  }

  Future<int> addCredit() async {
    final prefs = await SharedPreferences.getInstance();
    int current = prefs.getInt(_creditKey) ?? 0;
    current++;
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
