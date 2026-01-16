import 'package:flutter/material.dart';
import '../models/category_tag.dart';
import '../models/transaction_item.dart';
import '../repositories/transaction_repository.dart';
import '../repositories/gacha_repository.dart';
import '../utils/simple_calculator.dart';

/// 保存処理の結果をまとめたクラス
class InputServiceResult {
  final bool success; // 成功したか
  final String message; // 表示するメッセージ
  final Color messageColor; // メッセージの色
  final String? formattedAmount; // 計算後の金額文字列（UI更新用）
  final String? savedId; // 保存されたデータのID（Undo用）

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

  /// データを保存するメインの処理
  Future<InputServiceResult> registerTransaction({
    required String rawAmount, // 入力された金額（数式の可能性あり）
    required String memo, // メモ
    required DateTime date, // 選ばれた日付
    required CategoryTag expenseTag, // 選ばれた費目
    required bool isCardPayment, // カード払いモードか
    required CategoryTag? cardTag, // 選ばれたカード（あれば）
    required bool showCardOnInput, // 設定：カード入力を表示しているか
    required bool isGachaEnabled, // 設定：ガチャが有効か
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

    // 設定でカードが隠されている場合は、強制的に現金扱いにするかどうか
    // ※元のロジックに従い、UIで隠していてもisCardPaymentがtrueならカード扱いにします
    final bool shouldUseCard = showCardOnInput && isCardPayment;

    if (shouldUseCard) {
      if (cardTag != null) {
        paymentMethod = cardTag.label;

        // 締め日・支払日の計算
        if (cardTag.closingDay != null && cardTag.paymentDay != null) {
          int monthsToAdd = cardTag.paymentMonthOffset;
          if (cardTag.closingDay != 99 && date.day > cardTag.closingDay!) {
            monthsToAdd++;
          }
          int targetYear = date.year;
          int targetMonth = date.month + monthsToAdd;
          int targetDay = cardTag.paymentDay!;

          paymentDate = (targetDay == 99)
              ? DateTime(targetYear, targetMonth + 1, 0) // 末日
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
        final int currentCredits = result.$1;
        final bool isAdded = result.$2;

        if (isAdded) {
          if (currentCredits % 3 == 0) {
            msg = 'ガチャが回せます！';
            color = Colors.orange;
          } else {
            msg = '保存しました';
          }
        } else {
          msg = '保存しました（本日のポイント上限）';
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

  /// 削除（取り消し）処理
  Future<void> deleteTransaction(String id) async {
    await _transactionRepo.deleteTransaction(id);
  }

  /// 取り消し対象のアイテムを取得
  Future<TransactionItem?> getTransaction(String id) async {
    final allItems = await _transactionRepo.getAllTransactions();
    try {
      return allItems.firstWhere((e) => e.id == id);
    } catch (_) {
      return null;
    }
  }
}
