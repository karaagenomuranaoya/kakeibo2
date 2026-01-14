import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/transaction_item.dart';

class TransactionRepository {
  static const String _key = 'history';

  // 保存処理 (追加)
  Future<void> addTransaction(TransactionItem item) async {
    final List<TransactionItem> currentList = await getAllTransactions();
    currentList.insert(0, item);
    await _saveList(currentList);
  }

  // 更新処理 (編集)
  Future<void> updateTransaction(TransactionItem newItem) async {
    final List<TransactionItem> currentList = await getAllTransactions();
    // IDが一致するものを探して置き換える
    final index = currentList.indexWhere((item) => item.id == newItem.id);
    if (index != -1) {
      currentList[index] = newItem;
      await _saveList(currentList);
    }
  }

  // 削除処理
  Future<void> deleteTransaction(String id) async {
    final List<TransactionItem> currentList = await getAllTransactions();
    // IDが一致するものを削除
    currentList.removeWhere((item) => item.id == id);
    await _saveList(currentList);
  }

  // 内部共通: リストをJSONにして保存
  Future<void> _saveList(List<TransactionItem> list) async {
    final prefs = await SharedPreferences.getInstance();
    // 日付順（新しい順）にソートしておく
    list.sort((a, b) => b.date.compareTo(a.date));

    final String jsonString = json.encode(
      list.map((e) => e.toJson()).toList(),
    );
    await prefs.setString(_key, jsonString);
  }

  // 全件取得処理
  Future<List<TransactionItem>> getAllTransactions() async {
    final prefs = await SharedPreferences.getInstance();
    final String? jsonString = prefs.getString(_key);

    if (jsonString == null) return [];

    final List<dynamic> jsonList = json.decode(jsonString);
    return jsonList.map((e) => TransactionItem.fromJson(e)).toList();
  }
}
