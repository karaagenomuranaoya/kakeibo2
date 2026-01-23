import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:atsumeru_kakeibo/repositories/transaction_repository.dart';
import 'package:atsumeru_kakeibo/models/transaction_item.dart';

void main() {
  group('TransactionRepository Tests', () {
    late TransactionRepository repository;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      repository = TransactionRepository();
      // Ensure cache is cleared/reloaded for each test
      // Since it's a singleton, memory cache persists unless forced reload from empty SP
      await repository.getAllTransactions(forceReload: true);
    });

    test('Initial state is empty', () async {
      final transactions = await repository.getAllTransactions();
      expect(transactions, isEmpty);
    });

    test('addTransaction adds item and sorts by date', () async {
      final item1 = TransactionItem(
        id: '1',
        amount: 100,
        expense: 'A',
        payment: 'Cash',
        date: DateTime(2024, 1, 1),
      );
      final item2 = TransactionItem(
        id: '2',
        amount: 200,
        expense: 'B',
        payment: 'Card',
        date: DateTime(2024, 1, 2), // Newer
      );

      await repository.addTransaction(item1);
      await repository.addTransaction(item2);

      final list = await repository.getAllTransactions();
      expect(list.length, 2);
      expect(list[0].id, '2'); // Newer first
      expect(list[1].id, '1');
    });

    test('updateTransaction modifies existing item', () async {
      final item = TransactionItem(
        id: '1',
        amount: 100,
        expense: 'Old',
        payment: 'Cash',
        date: DateTime(2024, 1, 1),
      );
      await repository.addTransaction(item);

      final newItem = TransactionItem(
        id: '1',
        amount: 500,
        expense: 'New',
        payment: 'Cash',
        date: DateTime(2024, 1, 1),
      );
      await repository.updateTransaction(newItem);

      final list = await repository.getAllTransactions();
      expect(list.first.amount, 500);
      expect(list.first.expense, 'New');
    });

    test('deleteTransaction removes item', () async {
      final item = TransactionItem(
        id: '1',
        amount: 100,
        expense: 'A',
        payment: 'Cash',
        date: DateTime(2024, 1, 1),
      );
      await repository.addTransaction(item);
      expect((await repository.getAllTransactions()).length, 1);

      await repository.deleteTransaction('1');
      expect((await repository.getAllTransactions()).isEmpty, true);
    });

    test(
      'getAllTransactions with forceReload refreshes from storage',
      () async {
        // 1. Add item normally
        final item = TransactionItem(
          id: '1',
          amount: 100,
          expense: 'A',
          payment: 'Cash',
          date: DateTime(2024, 1, 1),
        );
        await repository.addTransaction(item);

        // 2. Simulate external change by modifying SharedPreferences directly
        // This simulates "data lost" or "changed outside app"
        SharedPreferences.setMockInitialValues({}); // Empty it

        // 3. Without forceReload, it should return cached data
        var list = await repository.getAllTransactions(forceReload: false);
        expect(list.length, 1);

        // 4. With forceReload, it should return empty (from SP)
        list = await repository.getAllTransactions(forceReload: true);
        expect(list, isEmpty);
      },
    );
  });
}
