import 'package:flutter/material.dart';
import '../models/transaction_item.dart';
import '../models/category_tag.dart';
import '../repositories/transaction_repository.dart';
import '../repositories/settings_repository.dart';

class HistoryService {
  final TransactionRepository _transactionRepo = TransactionRepository();
  final SettingsRepository _settingsRepo = SettingsRepository();

  /// 指定された年月のデータを取得する
  Future<List<TransactionItem>> getMonthlyTransactions({
    required int year,
    required int month,
  }) async {
    final allItems = await _transactionRepo.getAllTransactions();

    // 指定月でフィルタリング
    final filtered = allItems.where((i) {
      return i.date.year == year && i.date.month == month;
    }).toList();

    // 日付順（新しい順）に並び替え
    filtered.sort((a, b) => b.date.compareTo(a.date));

    return filtered;
  }

  /// 条件（費目やカード）で絞り込んだデータを取得する
  Future<List<TransactionItem>> getFilteredTransactions({
    required String filterKey, // 'expense' or 'payment'
    required String filterValue,
    required int year,
    required int month,
    required int viewMode, // 0: 利用日基準, 1: 支払日基準（引き落とし予定）
  }) async {
    final allItems = await _transactionRepo.getAllTransactions();

    final filtered = allItems.where((i) {
      // 1. キーによるフィルタリング
      if (filterKey == 'expense') {
        if (i.expense != filterValue) return false;
      } else if (filterKey == 'payment') {
        if (filterValue == '記録しない' && i.payment.isEmpty) {
          // 記録しない扱い（空文字）OK
        } else if (i.payment != filterValue) {
          return false;
        }
      }

      // 2. 年月によるフィルタリング
      if (viewMode == 1) {
        // 引き落とし予定モードなら、paymentDateを見る
        final targetDate = i.paymentDate ?? i.date; // paymentDateがなければ利用日
        return targetDate.year == year && targetDate.month == month;
      } else {
        // 通常モードなら利用日を見る
        return i.date.year == year && i.date.month == month;
      }
    }).toList();

    // 日付順に並び替え
    filtered.sort((a, b) => b.date.compareTo(a.date));

    return filtered;
  }

  /// 費目タグのリストを取得（アイコン表示などに必要）
  Future<List<CategoryTag>> getExpenseTags() async {
    return await _settingsRepo.loadExpenseTags();
  }

  /// カードタグのリストを取得
  Future<List<CategoryTag>> getCardTags() async {
    return await _settingsRepo.loadCardTags();
  }

  /// 特定のカード情報を取得（設定変更用）
  Future<CategoryTag?> getCardTagByLabel(String label) async {
    final cards = await getCardTags();
    try {
      return cards.firstWhere((c) => c.label == label);
    } catch (_) {
      return null;
    }
  }

  /// カード設定を更新する
  Future<void> updateCardTag(CategoryTag newTag) async {
    final cards = await getCardTags();
    final index = cards.indexWhere((c) => c.id == newTag.id);
    if (index != -1) {
      cards[index] = newTag;
      await _settingsRepo.saveCardTags(cards);
    }
  }
}
