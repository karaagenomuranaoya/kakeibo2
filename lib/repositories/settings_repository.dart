import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/category_tag.dart';

class SettingsRepository {
  static const String _expenseTagsKey = 'expense_tags_list';
  static const String _cardTagsKey = 'card_tags_list';
  static const String _gachaEnabledKey = 'gacha_enabled';
  static const String _categoryLongPressKey = 'category_long_press_enabled';
  static const String _showCardOnInputKey = 'show_card_on_input';
  // ▼▼ 追加: バイブレーション設定のキー ▼▼
  static const String _vibrationEnabledKey = 'vibration_enabled';

  // --- 費目リスト管理 ---
  Future<List<CategoryTag>> loadExpenseTags() async {
    final prefs = await SharedPreferences.getInstance();
    final String? jsonString = prefs.getString(_expenseTagsKey);

    List<CategoryTag> tags;
    if (jsonString == null) {
      tags = CategoryTag.defaultExpenses;
    } else {
      final List<dynamic> jsonList = json.decode(jsonString);
      tags = jsonList.map((e) => CategoryTag.fromJson(e)).toList();
    }

    // ▼▼ 修正: ID重複チェックと修復処理を通してから返す ▼▼
    return _sanitizeTags(tags);
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

    List<CategoryTag> tags;
    if (jsonString == null) {
      tags = CategoryTag.defaultCards;
    } else {
      final List<dynamic> jsonList = json.decode(jsonString);
      tags = jsonList.map((e) => CategoryTag.fromJson(e)).toList();
    }

    // ▼▼ 修正: ID重複チェックと修復処理を通してから返す ▼▼
    return _sanitizeTags(tags);
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

  // --- カテゴリ長押し設定の管理 ---
  Future<bool> loadCategoryLongPressEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_categoryLongPressKey) ?? true;
  }

  Future<void> saveCategoryLongPressEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_categoryLongPressKey, enabled);
  }

  // --- 入力画面でのカード表示設定 ---
  Future<bool> loadShowCardOnInput() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_showCardOnInputKey) ?? true;
  }

  Future<void> saveShowCardOnInput(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_showCardOnInputKey, enabled);
  }

  // --- バイブレーション設定の管理 ---
  Future<bool> loadVibrationEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    // デフォルトは true (振動する)
    return prefs.getBool(_vibrationEnabledKey) ?? true;
  }

  Future<void> saveVibrationEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_vibrationEnabledKey, enabled);
  }

  // ▼▼ 追加: 重複IDを検知してユニークにするヘルパーメソッド ▼▼
  // これにより、IDが被ってReorderableListViewでエラーになったり
  // 項目が表示されなかったりするバグを自動的に直します。
  List<CategoryTag> _sanitizeTags(List<CategoryTag> rawTags) {
    final Set<String> seenIds = {};
    final List<CategoryTag> sanitized = [];

    for (var tag in rawTags) {
      if (seenIds.contains(tag.id)) {
        // IDが重複している場合、IDをnullにして再生成させた新しいタグを作る
        // (CategoryTagのコンストラクタでid: nullなら自動生成される仕組みを利用)
        final newTag = CategoryTag(
          id: null, // 新規ID生成トリガー
          label: tag.label,
          color: tag.color,
          isCircle: tag.isCircle,
          closingDay: tag.closingDay,
          paymentDay: tag.paymentDay,
          paymentMonthOffset: tag.paymentMonthOffset,
          iconCodePoint: tag.iconCodePoint,
          iconFontFamily: tag.iconFontFamily,
          iconFontPackage: tag.iconFontPackage,
        );
        sanitized.add(newTag);
        // 新しく生成されたIDを記録（理論上被らないが念のため）
        seenIds.add(newTag.id);
      } else {
        // 重複していない正常なデータ
        sanitized.add(tag);
        seenIds.add(tag.id);
      }
    }
    return sanitized;
  }
}
