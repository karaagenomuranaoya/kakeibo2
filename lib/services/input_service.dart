import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart'; // Added
import '../models/category_tag.dart';
import '../models/transaction_item.dart';
import '../repositories/transaction_repository.dart';
import '../repositories/gacha_repository.dart';
import '../repositories/settings_repository.dart'; // Added
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

  InputServiceResult({
    required this.success,
    required this.message,
    this.messageColor = Colors.blue,
    this.formattedAmount,
    this.savedId,
  });
}

class InputService {
  final TransactionRepository _transactionRepo = TransactionRepository();
  final GachaRepository _gachaRepo = GachaRepository();
  final SettingsRepository _settingsRepo = SettingsRepository(); // Added

  // --- keys ---
  static const String _keyLastExpenseIdx = 'last_expense_index';
  static const String _keyLastCardIdx = 'last_card_index';
  static const String _keyLastIsCard = 'last_is_card';
  static const String _keyTutorialShown = 'is_input_tutorial_shown_v1';

  /// 入力画面に必要な初期データを一括で取得する
  Future<InputInitialData> loadInitialData() async {
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

          paymentDate = (targetDay == 99)
              ? DateTime(targetYear, targetMonth + 1, 0)
              : DateTime(targetYear, targetMonth, targetDay);
        }
      } else {
        paymentMethod = 'カード';
      }
    }

    // 3. データの保存
    try {
      final newItem = TransactionItem(
        amount: amount,
        expense: expenseTag.label,
        payment: paymentMethod,
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

      // 4. ガチャポイント処理
      String msg = '保存しました';
      Color color = Colors.blue;

      if (isGachaEnabled) {
        final result = await _gachaRepo.addCredit();
        // final int currentCredits = result.$1;
        final bool isAdded = result.$2;

        if (isAdded) {
          msg = 'ガチャチケット獲得！';
          color = Colors.orange;
        } else {
          msg = '保存しました（本日の上限到達）';
          color = Colors.grey;
        }
      } else if (paymentDate != null) {
        msg = '保存しました（支払日: ${paymentDate.month}/${paymentDate.day}）';
      }

      return InputServiceResult(
        success: true,
        message: msg,
        messageColor: color,
        formattedAmount: calculatedText,
        savedId: newItem.id,
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
}
