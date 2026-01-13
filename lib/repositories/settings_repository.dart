import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/category_tag.dart';

class SettingsRepository {
  static const String _favoritesKey = 'favorites_list';
  static const String _expenseTagsKey = 'expense_tags_list';
  static const String _cardTagsKey = 'card_tags_list';

  // --- お気に入り機能 (既存) ---
  static const List<String> _defaultFavorites = [
    'expense:食費',
    'payment:楽天カード', // デフォルト名に合わせて修正
  ];

  Future<List<String>> loadFavorites() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList(_favoritesKey) ?? _defaultFavorites;
  }

  Future<void> saveFavorites(List<String> favorites) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_favoritesKey, favorites);
  }

  // --- 費目リスト管理 (新規) ---
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

  // --- カードリスト管理 (新規) ---
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
}
