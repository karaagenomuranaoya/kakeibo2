import 'dart:convert';
import 'dart:math';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/gacha_item.dart';
import '../data/gacha_data.dart'; // データを読み込む

class GachaRepository {
  static const String _creditKey = 'gacha_credits';
  static const String _countsKey = 'gacha_counts_v2';

  // メモリ上のデータキャッシュ
  Map<String, int> _counts = {};

  // アイテムリスト取得（JSONではなく静的データから返す）
  Future<List<GachaItem>> getItems() async {
    return GachaData.monsters;
  }

  // 所持数取得
  Future<Map<String, int>> getItemCounts() async {
    if (_counts.isEmpty) await _loadCounts();
    return _counts;
  }

  // 所持数ロード
  Future<void> _loadCounts() async {
    final prefs = await SharedPreferences.getInstance();
    final String? jsonString = prefs.getString(_countsKey);
    if (jsonString != null) {
      final Map<String, dynamic> decoded = json.decode(jsonString);
      _counts = decoded.map((key, value) => MapEntry(key, value as int));
    }
  }

  // 所持数セーブ
  Future<void> _saveCounts() async {
    final prefs = await SharedPreferences.getInstance();
    final String jsonString = json.encode(_counts);
    await prefs.setString(_countsKey, jsonString);
  }

  // アイテム獲得処理（カウントアップ）
  Future<int> unlockItem(String id) async {
    await getItemCounts();
    int current = _counts[id] ?? 0;

    // 最大レベル10で止める場合
    // if (current < 10) current++;

    // 青天井でカウントして表示側でmax10扱いにする場合
    current++;

    _counts[id] = current;
    await _saveCounts();
    return current;
  }

  // ガチャ抽選ロジック
  Future<GachaItem> drawItem() async {
    // 重み付き抽選
    final items = GachaData.monsters;
    int totalWeight = items.fold(0, (sum, item) => sum + item.weight);
    int randomValue = Random().nextInt(totalWeight);

    for (final item in items) {
      randomValue -= item.weight;
      if (randomValue < 0) return item;
    }
    return items.last;
  }

  // --- クレジット管理 (変更なし) ---
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
