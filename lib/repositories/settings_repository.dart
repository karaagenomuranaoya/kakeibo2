import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/category_tag.dart';

class SettingsRepository {
  static const String _favoritesKey = 'favorites_list';
  static const String _expenseTagsKey = 'expense_tags_list';
  static const String _cardTagsKey = 'card_tags_list';
  static const String _gachaEnabledKey = 'gacha_enabled';
  // ▼▼ 追加: カテゴリ長押し機能の有効無効設定キー ▼▼
  static const String _categoryLongPressKey = 'category_long_press_enabled';

  // --- お気に入り機能 (既存) ---
  static const List<String> _defaultFavorites = ['expense:食費', 'payment:楽天カード'];

  Future<List<String>> loadFavorites() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList(_favoritesKey) ?? _defaultFavorites;
  }

  Future<void> saveFavorites(List<String> favorites) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_favoritesKey, favorites);
  }

  // --- 費目リスト管理 ---
  Future<List<CategoryTag>> loadExpenseTags() async {
    final prefs = await SharedPreferences.getInstance();
    final String? jsonString = prefs.getString(_expenseTagsKey);
    if (jsonString == null) {
      return CategoryTag.defaultExpenses;
    }
    final List<dynamic> jsonList = json.decode(jsonString);
    return jsonList.map((e) => CategoryTag.fromJson(e)).toList();
  }

  Future<void> saveExpenseTags(List<CategoryTag> tags) async {
    final prefs = await SharedPreferences.getInstance();
    final String jsonString = json.encode(tags.map((e) => e.toJson()).toList());
    await prefs.setString(_expenseTagsKey, jsonString);
  }

  // --- カードリスト管理 ---
  Future<List<CategoryTag>> loadCardTags() async {
    final prefs = await SharedPreferences.getInstance();
    final String? jsonString = prefs.getString(_cardTagsKey);
    if (jsonString == null) {
      return CategoryTag.defaultCards;
    }
    final List<dynamic> jsonList = json.decode(jsonString);
    return jsonList.map((e) => CategoryTag.fromJson(e)).toList();
  }

  Future<void> saveCardTags(List<CategoryTag> tags) async {
    final prefs = await SharedPreferences.getInstance();
    final String jsonString = json.encode(tags.map((e) => e.toJson()).toList());
    await prefs.setString(_cardTagsKey, jsonString);
  }

  // --- ガチャ設定の管理 ---
  Future<bool> loadGachaEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_gachaEnabledKey) ?? true;
  }

  Future<void> saveGachaEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_gachaEnabledKey, enabled);
  }

  // --- ▼▼ 追加: カテゴリ長押し設定の管理 ▼▼ ---
  Future<bool> loadCategoryLongPressEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    // デフォルトは true (オン)
    return prefs.getBool(_categoryLongPressKey) ?? true;
  }

  Future<void> saveCategoryLongPressEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_categoryLongPressKey, enabled);
  }
}
