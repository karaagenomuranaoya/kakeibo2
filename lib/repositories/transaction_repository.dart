import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/transaction_item.dart';

class TransactionRepository {
  static final TransactionRepository _instance =
      TransactionRepository._internal();
  factory TransactionRepository() => _instance;
  TransactionRepository._internal();

  static const String _key = 'history';

  // メモリキャッシュ
  List<TransactionItem>? _memoryCache;

  // ▼▼ 追加 #7: キャッシュを手動で無効化するメソッド ▼▼
  // データ更新後に呼び出すことで、次回の取得時に最新データを読み込む
  Future<void> invalidateCache() async {
    _memoryCache = null;
  }
  // ▲▲ 追加ここまで ▲▲

  /// 全件取得 (メモリキャッシュがあればそれを返す)
  Future<List<TransactionItem>> getAllTransactions({
    bool forceReload = false,
  }) async {
    if (_memoryCache != null && !forceReload) {
      return List.from(_memoryCache!);
    }

    final prefs = await SharedPreferences.getInstance();
    final String? jsonString = prefs.getString(_key);

    if (jsonString == null) {
      _memoryCache = [];
      return [];
    }

    try {
      final List<dynamic> jsonList = json.decode(jsonString);
      final list = jsonList.map((e) => TransactionItem.fromJson(e)).toList();

      // 日付順（新しい順）にソート
      list.sort((a, b) => b.date.compareTo(a.date));

      _memoryCache = list;
      return list;
    } catch (e) {
      return [];
    }
  }

  /// 追加処理
  Future<void> addTransaction(TransactionItem item) async {
    await getAllTransactions();
    _memoryCache!.insert(0, item);
    _memoryCache!.sort((a, b) => b.date.compareTo(a.date));
    await _saveToPrefs();
  }

  /// 更新処理
  Future<void> updateTransaction(TransactionItem newItem) async {
    await getAllTransactions();
    final index = _memoryCache!.indexWhere((item) => item.id == newItem.id);
    if (index != -1) {
      _memoryCache![index] = newItem;
      _memoryCache!.sort((a, b) => b.date.compareTo(a.date));
      await _saveToPrefs();
    }
  }

  /// 削除処理
  Future<void> deleteTransaction(String id) async {
    await getAllTransactions();
    _memoryCache!.removeWhere((item) => item.id == id);
    await _saveToPrefs();
  }

  /// 内部保存処理
  Future<void> _saveToPrefs() async {
    if (_memoryCache == null) return;
    final prefs = await SharedPreferences.getInstance();
    final String jsonString = json.encode(
      _memoryCache!.map((e) => e.toJson()).toList(),
    );
    await prefs.setString(_key, jsonString);
  }
}
