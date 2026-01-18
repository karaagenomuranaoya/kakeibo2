import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:atsumeru_kakeibo/services/input_service.dart';
import 'package:atsumeru_kakeibo/models/category_tag.dart';
import 'package:atsumeru_kakeibo/repositories/transaction_repository.dart';

void main() {
  setUp(() async {
    // 毎回データをリセット
    SharedPreferences.setMockInitialValues({});
    final repo = TransactionRepository();
    await repo.getAllTransactions(forceReload: true);
  });

  group('クレジットカードの引き落とし日計算テスト', () {
    // テスト用のカード設定：20日締め / 翌月10日払い
    final testCard = CategoryTag(
      label: 'メインカード',
      color: Colors.blue,
      closingDay: 20, // 20日締め
      paymentDay: 10, // 10日払い
      paymentMonthOffset: 1, // 翌月
    );

    final expenseTag = CategoryTag(label: '食費', color: Colors.red);

    test('締め日より前(1/15)なら、翌月(2/10)になるはず', () async {
      final service = InputService();

      // 1月15日の買い物
      final date = DateTime(2025, 1, 15);

      await service.registerTransaction(
        rawAmount: '1000',
        memo: 'ランチ',
        date: date,
        expenseTag: expenseTag,
        isCardPayment: true,
        cardTag: testCard,
        showCardOnInput: true,
        isGachaEnabled: false,
      );

      // 保存されたデータを確認
      final repo = TransactionRepository();
      final list = await repo.getAllTransactions();
      final item = list.first;

      // 期待値: 2025年2月10日
      expect(item.paymentDate, DateTime(2025, 2, 10));
    });

    test('締め日より後(1/25)なら、翌々月(3/10)になるはず', () async {
      final service = InputService();

      // 1月25日の買い物（20日を過ぎている！）
      final date = DateTime(2025, 1, 25);

      await service.registerTransaction(
        rawAmount: '5000',
        memo: '飲み会',
        date: date,
        expenseTag: expenseTag,
        isCardPayment: true,
        cardTag: testCard,
        showCardOnInput: true,
        isGachaEnabled: false,
      );

      final repo = TransactionRepository();
      final list = await repo.getAllTransactions();
      final item = list.first;

      // 期待値: 2025年3月10日
      expect(item.paymentDate, DateTime(2025, 3, 10));
    });
  });
}

//flutter test test/input_service_test.dart
