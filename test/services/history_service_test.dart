import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:atsumeru_kakeibo/services/history_service.dart';
import 'package:atsumeru_kakeibo/repositories/transaction_repository.dart';
import 'package:atsumeru_kakeibo/models/transaction_item.dart';
import 'package:atsumeru_kakeibo/models/category_tag.dart';
import 'package:flutter/material.dart';

void main() {
  group('HistoryService Tests', () {
    late HistoryService service;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      service = HistoryService();
      // Force singleton repo to reload from (empty) SP
      await TransactionRepository().getAllTransactions(forceReload: true);
    });

    // Helper to seed transactions
    Future<void> seedTransactions(List<TransactionItem> items) async {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = json.encode(items.map((e) => e.toJson()).toList());
      await prefs.setString('history', jsonString);
      // Force reload cache so Repository picks up the seeded data
      await TransactionRepository().getAllTransactions(forceReload: true);
    }

    test('getMonthlyTransactions filters by date', () async {
      final itemJan = TransactionItem(
        id: '1',
        amount: 100,
        expense: 'A',
        payment: 'Cash',
        date: DateTime(2024, 1, 15),
      );
      final itemFeb = TransactionItem(
        id: '2',
        amount: 200,
        expense: 'B',
        payment: 'Cash',
        date: DateTime(2024, 2, 15),
      );

      await seedTransactions([itemJan, itemFeb]);

      // Get Jan
      final janList = await service.getMonthlyTransactions(
        year: 2024,
        month: 1,
      );
      expect(janList.length, 1);
      expect(janList.first.id, '1');

      // Get Feb
      final febList = await service.getMonthlyTransactions(
        year: 2024,
        month: 2,
      );
      expect(febList.length, 1);
      expect(febList.first.id, '2');

      // Get Mar (Empty)
      final marList = await service.getMonthlyTransactions(
        year: 2024,
        month: 3,
      );
      expect(marList, isEmpty);
    });

    test('getFilteredTransactions (Expense) matches ID or Name', () async {
      final item1 = TransactionItem(
        id: '1',
        amount: 100,
        expense: 'Food',
        expenseId: 'food-id',
        payment: 'Cash',
        date: DateTime(2024, 1, 1),
      );
      final item2 = TransactionItem(
        id: '2',
        amount: 200,
        expense: 'Food',
        expenseId: 'diff-id', // Name match
        payment: 'Cash',
        date: DateTime(2024, 1, 2),
      );
      final item3 = TransactionItem(
        id: '3',
        amount: 300,
        expense: 'Other',
        expenseId: 'food-id', // ID match
        payment: 'Cash',
        date: DateTime(2024, 1, 3),
      );
      final item4 = TransactionItem(
        id: '4',
        amount: 400,
        expense: 'Other',
        expenseId: 'other-id', // No match
        payment: 'Cash',
        date: DateTime(2024, 1, 4),
      );

      await seedTransactions([item1, item2, item3, item4]);

      final result = await service.getFilteredTransactions(
        filterKey: 'expense',
        filterValue: 'Food',
        filterId: 'food-id',
        year: 2024,
        month: 1,
        viewMode: 0,
      );

      // Should match item1 (both), item2 (name), item3 (id)
      expect(result.length, 3);
      final ids = result.map((e) => e.id).toList();
      expect(ids, containsAll(['1', '2', '3']));
      expect(ids, isNot(contains('4')));
    });

    test('getFilteredTransactions uses PaymentDate in viewMode 1', () async {
      final item = TransactionItem(
        id: '1',
        amount: 100,
        expense: 'A',
        payment: 'Card',
        date: DateTime(2024, 1, 15), // Used in Mode 0
        paymentDate: DateTime(2024, 2, 27), // Used in Mode 1
      );
      await seedTransactions([item]);

      // Mode 0: Jan
      var list = await service.getFilteredTransactions(
        filterKey: 'expense',
        filterValue: 'A',
        year: 2024,
        month: 1,
        viewMode: 0,
      );
      expect(list.length, 1);

      // Mode 0: Feb
      list = await service.getFilteredTransactions(
        filterKey: 'expense',
        filterValue: 'A',
        year: 2024,
        month: 2,
        viewMode: 0,
      );
      expect(list, isEmpty);

      // Mode 1: Jan (Should be empty, payment is Feb)
      list = await service.getFilteredTransactions(
        filterKey: 'expense',
        filterValue: 'A',
        year: 2024,
        month: 1,
        viewMode: 1,
      );
      expect(list, isEmpty);

      // Mode 1: Feb (Should match)
      list = await service.getFilteredTransactions(
        filterKey: 'expense',
        filterValue: 'A',
        year: 2024,
        month: 2,
        viewMode: 1,
      );
      expect(list.length, 1);
    });

    test('updateCardTag updates settings', () async {
      // Seed cards
      final card = CategoryTag(id: 'c1', label: 'OldCard', color: Colors.blue);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('card_tags_list', json.encode([card.toJson()]));

      // Update
      final updatedCard = CategoryTag(
        id: 'c1',
        label: 'NewCard',
        color: Colors.red,
      );
      await service.updateCardTag(updatedCard);

      // Verify
      final cards = await service.getCardTags();
      expect(cards.first.label, 'NewCard');
      expect(cards.first.color.value, Colors.red.value);
    });
  });
}
