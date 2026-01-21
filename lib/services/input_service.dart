import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/category_tag.dart';
import '../models/transaction_item.dart';
import '../repositories/transaction_repository.dart';
import '../repositories/gacha_repository.dart';
import '../repositories/settings_repository.dart';
import '../utils/simple_calculator.dart';

/// 初期表示に必要なデータをまとめたクラス
class InputInitialData {
  final List<CategoryTag> expenses;
  final List<CategoryTag> cards;
  final bool isGachaEnabled;
  final bool isCategoryLongPressEnabled;
  final bool showCardOnInput;
  final int lastExpenseIndex;
  final int lastCardIndex;
  final bool lastIsCard;
  final bool shouldShowTutorial;

  InputInitialData({
    required this.expenses,
    required this.cards,
    required this.isGachaEnabled,
    required this.isCategoryLongPressEnabled,
    required this.showCardOnInput,
    required this.lastExpenseIndex,
    required this.lastCardIndex,
    required this.lastIsCard,
    required this.shouldShowTutorial,
  });
}

class InputServiceResult {
  final bool success;
  final String message;
  final Color messageColor;
  final String? formattedAmount;
  final String? savedId;
  final bool gachaCreditsAdded; // 追加

  InputServiceResult({
    required this.success,
    required this.message,
    this.messageColor = Colors.blue,
    this.formattedAmount,
    this.savedId,
    this.gachaCreditsAdded = false, // デフォルト値を設定
  });
}

class InputService {
  final TransactionRepository _transactionRepo = TransactionRepository();
  final GachaRepository _gachaRepo = GachaRepository();
  final SettingsRepository _settingsRepo = SettingsRepository();
  final ValueNotifier<int> gachaDataVersionNotifier = ValueNotifier<int>(
    0,
  ); // 追加

  // --- keys ---
  static const String _keyLastExpenseIdx = 'last_expense_index';
  static const String _keyLastCardIdx = 'last_card_index';
  static const String _keyLastIsCard = 'last_is_card';
  static const String _keyTutorialShown = 'is_input_tutorial_shown_v1';
  static const String _keyMigrationV1Done = 'is_category_migration_v1_done';

  /// 入力画面に必要な初期データを一括で取得する
  Future<InputInitialData> loadInitialData() async {
    // データ移行（カテゴリ名管理→ID管理への移行）
    await _migrateCategoriesToIds();

    final expenses = await _settingsRepo.loadExpenseTags();
    final cards = await _settingsRepo.loadCardTags();
    final gachaEnabled = await _settingsRepo.loadGachaEnabled();
    final catLongPressEnabled = await _settingsRepo
        .loadCategoryLongPressEnabled();
    final showCard = await _settingsRepo.loadShowCardOnInput();

    final prefs = await SharedPreferences.getInstance();

    int savedExpenseIndex = prefs.getInt(_keyLastExpenseIdx) ?? 0;
    if (savedExpenseIndex >= expenses.length) savedExpenseIndex = 0;

    int savedCardIndex = prefs.getInt(_keyLastCardIdx) ?? 0;
    if (savedCardIndex >= cards.length) savedCardIndex = 0;

    final savedIsCard = prefs.getBool(_keyLastIsCard) ?? false;
    final tutorialShown = prefs.getBool(_keyTutorialShown) ?? false;

    return InputInitialData(
      expenses: expenses,
      cards: cards,
      isGachaEnabled: gachaEnabled,
      isCategoryLongPressEnabled: catLongPressEnabled,
      showCardOnInput: showCard,
      lastExpenseIndex: savedExpenseIndex,
      lastCardIndex: savedCardIndex,
      lastIsCard: savedIsCard,
      shouldShowTutorial: !tutorialShown,
    );
  }

  /// チュートリアル表示済みフラグを立てる
  Future<void> markTutorialAsShown() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyTutorialShown, true);
  }

  /// 最後に選択した状態を保存する
  Future<void> saveLastInputState({
    int? expenseIndex,
    int? cardIndex,
    bool? isCard,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    if (expenseIndex != null) {
      await prefs.setInt(_keyLastExpenseIdx, expenseIndex);
    }
    if (cardIndex != null) {
      await prefs.setInt(_keyLastCardIdx, cardIndex);
    }
    if (isCard != null) {
      await prefs.setBool(_keyLastIsCard, isCard);
    }
  }

  Future<InputServiceResult> registerTransaction({
    required String rawAmount,
    required String memo,
    required DateTime date,
    required CategoryTag expenseTag,
    required bool isCardPayment,
    required CategoryTag? cardTag,
    required bool showCardOnInput,
    required bool isGachaEnabled,
  }) async {
    // 1. 計算とバリデーション
    final calculatedText = SimpleCalculator.calculate(rawAmount);

    if (calculatedText.isEmpty) {
      return InputServiceResult(
        success: false,
        message: '金額を入力してください',
        messageColor: Colors.redAccent,
      );
    }

    final int amount = double.tryParse(calculatedText)?.toInt() ?? 0;
    if (amount <= 0) {
      return InputServiceResult(
        success: false,
        message: '1円以上の金額を入力してください',
        messageColor: Colors.redAccent,
      );
    }

    // ▼▼ 追加: 桁数（金額）の上限チェック ▼▼
    if (amount >= 10000000000) {
      return InputServiceResult(
        success: false,
        message: '金額が大きすぎます',
        messageColor: Colors.redAccent,
      );
    }
    // ▲▲ 追加ここまで ▲▲

    // 2. 支払い情報の構築
    String paymentMethod = '';
    DateTime? paymentDate;

    final bool shouldUseCard = showCardOnInput && isCardPayment;

    if (shouldUseCard) {
      if (cardTag != null) {
        paymentMethod = cardTag.label;
        if (cardTag.closingDay != null && cardTag.paymentDay != null) {
          int monthsToAdd = cardTag.paymentMonthOffset;
          if (cardTag.closingDay != 99 && date.day > cardTag.closingDay!) {
            monthsToAdd++;
          }
          int targetYear = date.year;
          int targetMonth = date.month + monthsToAdd;
          int targetDay = cardTag.paymentDay!;

          final int lastDayOfMonth = DateTime(
            targetYear,
            targetMonth + 1,
            0,
          ).day;

          final int realPaymentDay = (targetDay > lastDayOfMonth)
              ? lastDayOfMonth
              : targetDay;

          paymentDate = DateTime(targetYear, targetMonth, realPaymentDay);
        }
      } else {
        paymentMethod = '不明';
      }
    }

    // 3. データの保存
    try {
      final newItem = TransactionItem(
        amount: amount,
        expense: expenseTag.label,
        expenseId: expenseTag.id,
        payment: paymentMethod,
        paymentId: shouldUseCard ? cardTag?.id : null,
        date: DateTime(
          date.year,
          date.month,
          date.day,
          DateTime.now().hour,
          DateTime.now().minute,
        ),
        paymentDate: paymentDate,
        memo: memo,
      );

      await _transactionRepo.addTransaction(newItem);

      // 4. ガチャポイント処理とメッセージ生成
      String msg = '保存しました';
      Color color = Colors.blue;
      bool gachaCreditsAdded = false; // 追加

      if (paymentDate != null) {
        msg = '保存しました（支払日: ${paymentDate.month}/${paymentDate.day}）';
      }

      if (isGachaEnabled) {
        final result = await _gachaRepo.addCredit();
        gachaCreditsAdded = result.$2;
        if (gachaCreditsAdded) {
          gachaDataVersionNotifier.value++; // gachaDataVersionNotifier をインクリメント
        }
      }

      if (gachaCreditsAdded) {
        msg += '🎫'; // チケット絵文字はここで追加
      }

      return InputServiceResult(
        success: true,
        message: msg,
        messageColor: color,
        formattedAmount: calculatedText,
        savedId: newItem.id,
        gachaCreditsAdded: gachaCreditsAdded, // gachaCreditsAdded を返す
      );
    } catch (e) {
      return InputServiceResult(
        success: false,
        message: '保存エラー: $e',
        messageColor: Colors.red,
      );
    }
  }

  Future<void> deleteTransaction(String id) async {
    await _transactionRepo.deleteTransaction(id);
  }

  Future<TransactionItem?> getTransaction(String id) async {
    final allItems = await _transactionRepo.getAllTransactions();
    try {
      return allItems.firstWhere((e) => e.id == id);
    } catch (_) {
      return null;
    }
  }

  /// 既存データのカテゴリ名・カード名をIDに紐付ける移行処理
  Future<void> _migrateCategoriesToIds() async {
    final prefs = await SharedPreferences.getInstance();
    final bool done = prefs.getBool(_keyMigrationV1Done) ?? false;
    if (done) return;

    try {
      final allTransactions = await _transactionRepo.getAllTransactions();
      final expenses = await _settingsRepo.loadExpenseTags();
      final cards = await _settingsRepo.loadCardTags();

      bool changed = false;
      final updatedList = <TransactionItem>[];

      for (final item in allTransactions) {
        String? newExpenseId = item.expenseId;
        String? newPaymentId = item.paymentId;
        bool itemChanged = false;

        // 費目の紐付け
        if (newExpenseId == null) {
          try {
            final tag = expenses.firstWhere((e) => e.label == item.expense);
            newExpenseId = tag.id;
            itemChanged = true;
          } catch (_) {
            // 見つからない場合は古い名前のままIDなし
          }
        }

        // 支払いの紐付け
        if (newPaymentId == null && item.payment.isNotEmpty) {
          // カードリストから探す
          try {
            final tag = cards.firstWhere((c) => c.label == item.payment);
            newPaymentId = tag.id;
            itemChanged = true;
          } catch (_) {
            // 見つからない場合はIDなし
          }
        }

        if (itemChanged) {
          updatedList.add(
            item.copyWith(expenseId: newExpenseId, paymentId: newPaymentId),
          );
          changed = true;
        } else {
          updatedList.add(item);
        }
      }

      if (changed) {
        // TransactionRepositoryには一括更新メソッドがないので、
        // 内部実装を知っている前提で少し強引だが、一件ずつ更新するか、
        // あるいはRepositoryに一括更新メソッドを追加するのが筋。
        // ここでは件数が多いと一件ずつは重いので、Repositoryのメモリキャッシュを書き換えて保存させる
        // ただし _saveToPrefs は private なので、一件ずつ updateTransaction するしかない。
        // 件数が数百件程度なら問題ないはず。
        for (final newItem in updatedList) {
          // IDが変わっていなくても、copyWithでインスタンスが変わっているものを保存
          // ただし、getAllTransactionsで取得したリストの要素と updatedList の要素を比較...
          // ここでは単純に changed フラグが立っている item だけ update する
          if (newItem.expenseId != null || newItem.paymentId != null) {
            await _transactionRepo.updateTransaction(newItem);
          }
        }
      }

      await prefs.setBool(_keyMigrationV1Done, true);
    } catch (e) {
      debugPrint('Migration failed: $e');
    }
  }
}
