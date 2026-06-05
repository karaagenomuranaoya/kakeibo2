import 'package:flutter_test/flutter_test.dart';
import 'package:atsumeru_kakeibo/models/transaction_item.dart';

void main() {
  group('TransactionItem Tests', () {
    test('Constructor creates instance with generated ID if null', () {
      final item = TransactionItem(
        amount: 1000,
        expense: 'Food',
        payment: 'Cash',
        date: DateTime(2024, 1, 1),
      );
      expect(item.id, isNotNull);
      expect(item.id, isNotEmpty);
      expect(item.amount, 1000);
    });

    test('toJson converts object to map correctly', () {
      final date = DateTime(2024, 1, 1, 12, 0);
      final item = TransactionItem(
        id: 'test-id',
        amount: 500,
        expense: 'Snack',
        expenseId: 'exp-1',
        payment: 'Card',
        paymentId: 'pay-1',
        date: date,
        paymentDate: date.add(const Duration(days: 30)),
        memo: 'Delicious',
      );

      final json = item.toJson();

      expect(json['id'], 'test-id');
      expect(json['amount'], 500);
      expect(json['expense'], 'Snack');
      expect(json['expense_id'], 'exp-1');
      expect(json['payment'], 'Card');
      expect(json['payment_id'], 'pay-1');
      expect(json['date_iso'], date.toIso8601String());
      expect(
        json['payment_date_iso'],
        date.add(const Duration(days: 30)).toIso8601String(),
      );
      expect(json['memo'], 'Delicious');
    });

    test('fromJson creates object from map correctly', () {
      final date = DateTime(2024, 1, 1, 12, 0);
      final json = {
        'id': 'json-id',
        'amount': 2000,
        'expense': 'Book',
        'expense_id': 'exp-2',
        'payment': 'PayPay',
        'payment_id': 'pay-2',
        'date_iso': date.toIso8601String(),
        'payment_date_iso': null,
        'memo': 'Study',
      };

      final item = TransactionItem.fromJson(json);

      expect(item.id, 'json-id');
      expect(item.amount, 2000);
      expect(item.expense, 'Book');
      expect(item.expenseId, 'exp-2');
      expect(item.payment, 'PayPay');
      expect(item.paymentId, 'pay-2');
      expect(item.date, date);
      expect(item.paymentDate, isNull);
      expect(item.memo, 'Study');
    });

    test('copyWith updates specified fields', () {
      final item = TransactionItem(
        amount: 1000,
        expense: 'Food',
        payment: 'Cash',
        date: DateTime(2024, 1, 1),
      );

      final updated = item.copyWith(amount: 1500, expense: 'Lunch');

      expect(updated.amount, 1500);
      expect(updated.expense, 'Lunch');
      expect(updated.payment, 'Cash'); // Should remain same
      expect(updated.date, item.date); // Should remain same
    });
  });
}
