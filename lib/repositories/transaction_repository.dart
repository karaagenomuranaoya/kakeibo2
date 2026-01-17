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

  // --- ⬇️ ここから追加機能：日数カウントロジック ---

  /// ユニークな入力日数を取得する
  /// (1日に複数回入力しても「1日」としてカウント)
  int getUniqueInputDaysCount() {
    if (_memoryCache == null || _memoryCache!.isEmpty) return 0;

    // Setを使って重複する日付を除去する
    final uniqueDates = _memoryCache!.map((item) {
      // 時間情報(HH:mm:ss)を切り捨てて、年月日だけにする
      return DateTime(item.date.year, item.date.month, item.date.day);
    }).toSet();

    return uniqueDates.length;
  }

  /// 継続中の入力日数を取得する（オプション機能：連続記録用）
  /// 今日から遡って何日連続で入力しているか
  int getCurrentStreak() {
    if (_memoryCache == null || _memoryCache!.isEmpty) return 0;

    // 日付のみのリストを作成して降順ソート
    final sortedDates =
        _memoryCache!
            .map((item) {
              return DateTime(item.date.year, item.date.month, item.date.day);
            })
            .toSet()
            .toList()
          ..sort((a, b) => b.compareTo(a)); // 新しい順

    if (sortedDates.isEmpty) return 0;

    final today = DateTime.now();
    final todayOnly = DateTime(today.year, today.month, today.day);

    int streak = 0;
    // 最新の入力が今日、または昨日でない場合はストリーク途切れとみなす場合などの判定
    // ここでは単純にリストを遡る

    DateTime checkDate = sortedDates.first;

    // もし最新入力が今日より未来なら（入力ミスなど）、カウント対象にするか要検討ですが
    // 一旦、最新の日付を基準にカウントを開始します

    // ※ シンプルにするため、最新の日付から「1日ずつ差があるか」をチェック
    for (int i = 0; i < sortedDates.length - 1; i++) {
      final current = sortedDates[i];
      final next = sortedDates[i + 1];

      final diff = current.difference(next).inDays;
      if (diff == 1) {
        streak++;
      } else {
        break; // 連続が途切れたら終了
      }
    }

    // 最初の1日分を加算
    return streak + 1;
  }
}
