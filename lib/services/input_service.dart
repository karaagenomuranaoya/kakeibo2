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
    required String rawAmount, //計算前の金額
    required String memo, //メモ
    required DateTime date, //日付
    required CategoryTag expenseTag, //カテゴリ
    required bool isCardPayment, //支払いが現金以外か
    required CategoryTag? cardTag, //支払い方法
    required bool showCardOnInput, //カード機能をのものを画面に置いているか
    required bool isGachaEnabled, //なんだこれは
  }) async {
    // 1. 計算とバリデーション
    final calculatedText = SimpleCalculator.calculate(rawAmount); //計算した

    if (calculatedText.isEmpty) {
      return InputServiceResult(
        success: false,
        message: '金額を入力してください',
        messageColor: Colors.redAccent,
      ); //最終的な結果。無入力で保存しない。
    }

    final int amount =
        double.tryParse(calculatedText)?.toInt() ?? 0; //parseってなんだ？
    if (amount <= 0) {
      return InputServiceResult(
        success: false,
        message: '1円以上の金額を入力してください',
        messageColor: Colors.redAccent,
      ); //-チェッカー
    }

    // ▼▼ 追加: 桁数（金額）の上限チェック ▼▼
    // 10桁まで = 9,999,999,999 までOK。10,000,000,000 (100億)以上はNG
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

          // 1. その月の「本当の末日」を計算する（例：4月なら30日）
          final int lastDayOfMonth = DateTime(
            targetYear,
            targetMonth + 1,
            0,
          ).day;

          // 2. 支払日を決める
          // targetDay（31）が lastDayOfMonth（30）より大きければ、30を使う。そうでなければ31を使う。
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

      // 4. ガチャポイント処理とメッセージ生成
      String msg = '保存しました'; // 基本のメッセージ
      Color color = Colors.blue;

      // ① まず支払日の情報をメッセージに入れる
      if (paymentDate != null) {
        msg = '保存しました（支払日: ${paymentDate.month}/${paymentDate.day}）';
      }

      // ② 次に（elseを使わずに）ガチャ処理を行う
      if (isGachaEnabled) {
        // addCreditは (int 現在のポイント, bool 追加できたか) の2つを返します
        final result = await _gachaRepo.addCredit();

        // result.$2 が「ポイントが追加できたかどうか(bool)」です
        final bool isAdded = result.$2;

        if (isAdded) {
          // ポイントが増えたら、メッセージの後ろにチケットを付け足す
          msg += '🎫';
        }
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
