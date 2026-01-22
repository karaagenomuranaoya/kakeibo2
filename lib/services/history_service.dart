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
    String? filterId, // IDでのフィルタリング用 (追加)
    required int year,
    required int month,
    required int viewMode, // 0: 利用日基準, 1: 支払日基準（引き落とし予定）
  }) async {
    final allItems = await _transactionRepo.getAllTransactions();

    // ▼デバッグログ: 何を探そうとしているか確認
    debugPrint("--- DEBUG SEARCH ---");
    debugPrint(
      "Target: $year/$month, Key: $filterKey, Name: $filterValue, ID: $filterId",
    );

    // ▼デバッグログ: 何を探そうとしているか確認
    debugPrint("--- DEBUG SEARCH ---");
    debugPrint(
      "Target: $year/$month, Key: $filterKey, Name: $filterValue, ID: $filterId",
    );

    final filtered = allItems.where((i) {
      // 1. 年月チェック（ここを先にやると無駄なログが減ります）
      DateTime targetDate;
      if (viewMode == 1) {
        targetDate = i.paymentDate ?? i.date;
      } else {
        targetDate = i.date;
      }
      if (targetDate.year != year || targetDate.month != month) {
        return false;
      }

      // 2. キーによる判定（ID または 名前 が合致すればOKにする）
      bool isMatch = false;

      if (filterKey == 'expense') {
        // IDが一致するか？
        bool idMatches = (filterId != null && i.expenseId == filterId);
        // 名前が一致するか？
        bool nameMatches = (i.expense == filterValue);

        // どっちかが合えばOK
        if (idMatches || nameMatches) {
          isMatch = true;

          // なぜ一致したかログに出す（確認用）
          // debugPrint("Match Found: ${i.expense} (ID: ${i.expenseId}) - By ID:$idMatches, By Name:$nameMatches");
        } else {
          // 同じ月なのに弾かれたデータをログに出す（ここが重要）
          debugPrint(
            "Rejected in same month: ${i.expense} (ID: ${i.expenseId}) vs Filter(Name:$filterValue, ID:$filterId)",
          );
        }
      } else if (filterKey == 'payment') {
        if (filterValue == '記録しない' && i.payment.isEmpty) {
          isMatch = true;
        } else {
          bool idMatches = (filterId != null && i.paymentId == filterId);
          bool nameMatches = (i.payment == filterValue);

          if (idMatches || nameMatches) {
            isMatch = true;
          }
        }
      }

      return isMatch;
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
