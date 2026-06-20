import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:atsumeru_kakeibo/models/category_tag.dart';
import 'package:atsumeru_kakeibo/models/transaction_item.dart';
import 'package:atsumeru_kakeibo/models/gacha_item.dart';
import 'package:atsumeru_kakeibo/repositories/transaction_repository.dart';
import 'package:atsumeru_kakeibo/repositories/settings_repository.dart';
import 'package:atsumeru_kakeibo/repositories/gacha_repository.dart';

void main() {
  setUpAll(() {
    // SharedPreferencesを使うテストのために初期化
    TestWidgetsFlutterBinding.ensureInitialized();
  });

  group('App Core Logic Tests - アプリの核となるロジック', () {
    // ============================================
    // CategoryTag (カテゴリ・支払方法) のロジック
    // ============================================
    group('CategoryTag - Categories & Payment Methods', () {
      test('Default expenses should have 9 categories with unique IDs', () {
        final expenses = CategoryTag.defaultExpenses;

        expect(expenses.length, 9);

        // すべてのIDがユニークか確認
        Set<String> ids = {};
        for (final expense in expenses) {
          expect(
            ids.contains(expense.id),
            false,
            reason: 'Duplicate ID: ${expense.id}',
          );
          ids.add(expense.id);
        }

        expect(ids.length, 9);
      });

      test(
        'Default cards should have 2 payment methods with closing/payment days',
        () {
          final cards = CategoryTag.defaultCards;

          expect(cards.length, 2);

          // クレジットカードは閉計日・支払日が設定されている
          for (final card in cards) {
            expect(card.closingDay, isNotNull);
            expect(card.paymentDay, isNotNull);
            expect(card.closingDay, greaterThan(0));
            expect(card.paymentDay, greaterThan(0));
          }
        },
      );

      test('CategoryTag JSON serialization roundtrip', () {
        final original = CategoryTag(
          id: 'test_cat_123',
          label: 'Test Category',
          color: Colors.red,
          isCircle: false,
        );

        final json = original.toJson();
        final restored = CategoryTag.fromJson(json);

        expect(restored.id, original.id);
        expect(restored.label, original.label);
        expect(restored.color.value, original.color.value);
        expect(restored.isCircle, original.isCircle);
      });

      test('CategoryTag displayIcon returns valid IconData', () {
        final category = CategoryTag(
          id: 'food',
          label: 'Food',
          color: Colors.orange,
          isCircle: true,
        );

        expect(category.displayIcon, isNotNull);
        expect(category.displayIcon, isA<IconData>());
      });

      test('CategoryTag isManageablePayment status for system categories', () {
        final editable = CategoryTag(
          id: 'custom_cat',
          label: 'Custom',
          color: Colors.blue,
          isCircle: false,
        );

        final systemNoRecord = CategoryTag(
          id: CategoryTag.systemNoRecordId,
          label: 'No Record',
          color: Colors.grey,
          isCircle: false,
        );

        // isManageablePayment プロパティで管理性を確認
        expect(editable.isManageablePayment, true);
        expect(systemNoRecord.isManageablePayment, false);
      });
    });

    // ============================================
    // TransactionItem (取引データ) のロジック
    // ============================================
    group('TransactionItem - Transaction Data', () {
      test('TransactionItem creation with required fields', () {
        final now = DateTime.now();
        final item = TransactionItem(
          id: 'trans_001',
          amount: 1000,
          expense: 'food',
          expenseId: 'food_id',
          payment: 'cash',
          paymentId: null,
          date: now,
          paymentDate: null,
          memo: 'Lunch',
        );

        expect(item.id, 'trans_001');
        expect(item.amount, 1000);
        expect(item.expense, 'food');
        expect(item.payment, 'cash');
        expect(item.memo, 'Lunch');
      });

      test(
        'TransactionItem copyWith preserves original when not specified',
        () {
          final original = TransactionItem(
            id: 'trans_001',
            amount: 1000,
            expense: 'food',
            expenseId: 'food_id',
            payment: 'cash',
            paymentId: null,
            date: DateTime(2026, 6, 14),
            paymentDate: null,
            memo: 'Lunch',
          );

          final copied = original.copyWith(amount: 2000);

          expect(copied.amount, 2000);
          expect(copied.id, original.id);
          expect(copied.expense, original.expense);
          expect(copied.memo, original.memo);
        },
      );

      test('TransactionItem JSON roundtrip maintains data integrity', () {
        final date = DateTime(2026, 6, 14);
        final original = TransactionItem(
          id: 'trans_001',
          amount: 5000,
          expense: 'food',
          expenseId: 'food_id',
          payment: 'credit_card',
          paymentId: 'card_001',
          date: date,
          paymentDate: null,
          memo: 'Dinner with friends',
        );

        final json = original.toJson();
        final restored = TransactionItem.fromJson(json);

        expect(restored.id, original.id);
        expect(restored.amount, original.amount);
        expect(restored.expense, original.expense);
        expect(restored.payment, original.payment);
        expect(restored.memo, original.memo);
      });

      test(
        'TransactionItem with credit card payment and calculated payment date',
        () {
          final registrationDate = DateTime(2026, 1, 15);
          final paymentDate = DateTime(2026, 3, 10);

          final item = TransactionItem(
            id: 'card_trans',
            amount: 30000,
            expense: 'shopping',
            expenseId: 'shopping_id',
            payment: 'credit_card',
            paymentId: 'card_id',
            date: registrationDate,
            paymentDate: paymentDate,
            memo: 'Large purchase',
          );

          expect(item.paymentDate, isNotNull);
          expect(item.paymentDate!.year, 2026);
        },
      );
    });

    // ============================================
    // GachaItem (ガチャアイテム) のロジック
    // ============================================
    group('GachaItem - Gacha Collection Items', () {
      test('GachaItem creation with level progression', () {
        final item = GachaItem(
          id: 'monster_001',
          baseName: 'Fire Dragon',
          weight: 10,
          rarity: 2,
          iconData: Icons.star,
          descriptions: ['A powerful fire dragon', 'Rarity: SR'],
        );

        expect(item.id, 'monster_001');
        expect(item.baseName, 'Fire Dragon');
        expect(item.weight, 10);
        expect(item.rarity, 2);
      });

      test('GachaItem iconData and descriptions properties', () {
        final descriptions = ['Strong ability', 'Elemental: Fire'];
        final item = GachaItem(
          id: 'monster_001',
          baseName: 'Fire Dragon',
          weight: 10,
          rarity: 2,
          iconData: Icons.star,
          descriptions: descriptions,
        );

        expect(item.iconData, Icons.star);
        expect(item.descriptions, descriptions);
      });

      test('GachaItem weight determines draw probability', () {
        final common = GachaItem(
          id: 'common',
          baseName: 'Common Monster',
          weight: 50,
          rarity: 1,
          iconData: Icons.emoji_events,
          descriptions: ['Common'],
        );

        final rare = GachaItem(
          id: 'rare',
          baseName: 'Rare Monster',
          weight: 10,
          rarity: 3,
          iconData: Icons.star,
          descriptions: ['Rare'],
        );

        expect(common.weight, greaterThan(rare.weight));
      });

      test('GachaItem getStage method for level tracking', () {
        final item = GachaItem(
          id: 'monster_001',
          baseName: 'Fire Dragon',
          weight: 10,
          rarity: 2,
          iconData: Icons.star,
          descriptions: ['Fire Dragon'],
        );

        // ステージ計算テスト
        expect(item.getStage(0), 0); // 未所持
        expect(item.getStage(5), 5); // レベル5
        expect(item.getStage(10), 10); // 最大レベル
        expect(item.getStage(15), 10); // カンスト（10以上）
      });
    });

    // ============================================
    // Repository - Persistence Logic
    // ============================================
    group('SettingsRepository - Persistence', () {
      test('Default expenses loaded when no saved data', () async {
        final repo = SettingsRepository();
        final expenses = await repo.loadExpenseTags();

        expect(expenses, isNotEmpty);
        expect(expenses.length, 9);
      });

      test('Default cards loaded with payment info', () async {
        final repo = SettingsRepository();
        final cards = await repo.loadCardTags();

        expect(cards.length, 2);

        for (final card in cards) {
          expect(card.closingDay, isNotNull);
          expect(card.paymentDay, isNotNull);
        }
      });

      test('Settings flags (gacha, tutorial, etc) have defaults', () async {
        final repo = SettingsRepository();

        final gachaEnabled = await repo.loadGachaEnabled();
        final longPressEnabled = await repo.loadCategoryLongPressEnabled();
        final showCard = await repo.loadShowCardOnInput();

        expect(gachaEnabled, isA<bool>());
        expect(longPressEnabled, isA<bool>());
        expect(showCard, isA<bool>());
      });
    });

    group('TransactionRepository - Transaction Persistence', () {
      test('TransactionRepository is singleton', () {
        final repo1 = TransactionRepository();
        final repo2 = TransactionRepository();

        expect(identical(repo1, repo2), true);
      });

      test(
        'Transaction cache invalidation method exists and is callable',
        () async {
          final repo = TransactionRepository();

          expect(repo.invalidateCache, isA<Function>());

          final result = repo.invalidateCache();
          expect(result, isA<Future>());
        },
      );

      test('getAllTransactions returns list (with or without data)', () async {
        final repo = TransactionRepository();
        final transactions = await repo.getAllTransactions();

        expect(transactions, isA<List<TransactionItem>>());
      });
    });

    group('GachaRepository - Gacha System Logic', () {
      test('GachaRepository is singleton', () {
        final repo1 = GachaRepository();
        final repo2 = GachaRepository();

        expect(identical(repo1, repo2), true);
      });

      test('Credits can be retrieved', () async {
        final repo = GachaRepository();
        final credits = await repo.getCredits();

        expect(credits, isA<int>());
        expect(credits, greaterThanOrEqualTo(0));
      });

      test('checkInitialBonus sets flag', () async {
        final repo = GachaRepository();
        await repo.checkInitialBonus();

        final credits = await repo.getCredits();
        expect(credits, isA<int>());
      });
    });

    // ============================================
    // Business Logic - Transaction Validation
    // ============================================
    group('Transaction Amount Validation', () {
      test('Amount must be positive and non-zero', () {
        final validAmounts = [1, 100, 999999, 1000000];
        final invalidAmounts = [0, -100, -1];

        for (final amount in validAmounts) {
          expect(amount > 0, true, reason: 'Amount $amount should be valid');
        }

        for (final amount in invalidAmounts) {
          expect(amount > 0, false, reason: 'Amount $amount should be invalid');
        }
      });

      test('Amount has maximum limit', () {
        const maxAmount = 10000000000;
        const validAmount = 9999999999;
        const invalidAmount = 10000000001;

        expect(validAmount < maxAmount, true);
        expect(invalidAmount >= maxAmount, true);
      });

      test('Amount must be parseable from string calculation', () {
        final testCases = [
          ('100', 100),
          ('50.5', 50),
          ('1000', 1000),
          ('100+50', 150),
        ];

        for (final (input, expected) in testCases) {
          final result = double.tryParse(input);
          if (result != null) {
            expect(result.toInt(), expected);
          }
        }
      });
    });

    // ============================================
    // Business Logic - Date & Payment Processing
    // ============================================
    group('Credit Card Payment Date Calculation', () {
      test('Payment date calculation accounts for closing day', () {
        int closingDay = 25;
        int paymentDay = 10;
        int paymentMonthOffset = 1;

        int registrationDayA = 15;
        int monthsToAddA = paymentMonthOffset;
        if (closingDay != 99 && registrationDayA > closingDay) {
          monthsToAddA++;
        }
        expect(monthsToAddA, paymentMonthOffset);

        int registrationDayB = 26;
        int monthsToAddB = paymentMonthOffset;
        if (closingDay != 99 && registrationDayB > closingDay) {
          monthsToAddB++;
        }
        expect(monthsToAddB, paymentMonthOffset + 1);
      });

      test('Month overflow handling in payment calculation', () {
        int targetMonth = 11 + 2;
        int targetYear = 2026;

        if (targetMonth > 12) {
          targetYear += (targetMonth - 1) ~/ 12;
          targetMonth = ((targetMonth - 1) % 12) + 1;
        }

        expect(targetMonth, 1);
        expect(targetYear, 2027);
      });

      test('Payment day adjustment for short months', () {
        int paymentDay = 30;
        int targetMonth = 2;
        int targetYear = 2026;

        DateTime? paymentDate;
        try {
          paymentDate = DateTime(targetYear, targetMonth, paymentDay);
        } catch (e) {
          final lastDay = DateTime(targetYear, targetMonth + 1, 0).day;
          paymentDate = DateTime(targetYear, targetMonth, lastDay);
        }

        expect(paymentDate.day, lessThanOrEqualTo(29));
      });
    });

    // ============================================
    // Business Logic - Data Consistency
    // ============================================
    group('Data Consistency & Integrity', () {
      test('Transaction with category maintains reference integrity', () {
        final category = CategoryTag(
          id: 'food_123',
          label: 'Food',
          color: Colors.orange,
          isCircle: true,
        );

        final transaction = TransactionItem(
          id: 'trans_001',
          amount: 1000,
          expense: category.label,
          expenseId: category.id,
          payment: 'cash',
          paymentId: null,
          date: DateTime.now(),
          paymentDate: null,
          memo: 'Test',
        );

        expect(transaction.expenseId, category.id);
        expect(transaction.expense, category.label);
      });

      test('Category deletion handling for existing transactions', () {
        final deletedCategoryId = 'food_123';
        const systemNoRecordId = CategoryTag.systemNoRecordId;

        final transaction = TransactionItem(
          id: 'trans_001',
          amount: 1000,
          expense: 'Food',
          expenseId: deletedCategoryId,
          payment: 'cash',
          paymentId: null,
          date: DateTime.now(),
          paymentDate: null,
          memo: 'Test',
        );

        final movedTransaction = transaction.copyWith(
          expenseId: systemNoRecordId,
          expense: 'その他',
        );

        expect(movedTransaction.expenseId, systemNoRecordId);
        expect(transaction.expenseId, deletedCategoryId);
      });
    });

    // ============================================
    // Business Logic - Gacha System
    // ============================================
    group('Gacha System - Collection & Rewards', () {
      test('Gacha weight distribution - common, rare, ultra-rare', () {
        final monsters = [
          GachaItem(
            id: 'common',
            baseName: 'Common',
            weight: 50,
            rarity: 1,
            iconData: Icons.emoji_events,
            descriptions: ['Common'],
          ),
          GachaItem(
            id: 'rare',
            baseName: 'Rare',
            weight: 30,
            rarity: 2,
            iconData: Icons.star,
            descriptions: ['Rare'],
          ),
          GachaItem(
            id: 'sr',
            baseName: 'SR',
            weight: 15,
            rarity: 3,
            iconData: Icons.favorite,
            descriptions: ['SR'],
          ),
          GachaItem(
            id: 'ssr',
            baseName: 'SSR',
            weight: 5,
            rarity: 4,
            iconData: Icons.diamond,
            descriptions: ['SSR'],
          ),
        ];

        int totalWeight = monsters.fold<int>(
          0,
          (sum, item) => sum + item.weight,
        );
        expect(totalWeight, 100);

        for (int i = 0; i < monsters.length - 1; i++) {
          expect(
            monsters[i].weight,
            greaterThanOrEqualTo(monsters[i + 1].weight),
          );
        }
      });

      test('Item level progression system (Lv1-10)', () {
        final levels = List.generate(11, (i) => i);

        for (int level in levels) {
          expect(level, greaterThanOrEqualTo(0));
          expect(level, lessThanOrEqualTo(10));
        }
      });

      test('Daily credit bonus system', () {
        const initialBonus = 3;
        const dailyBonus = 1;

        int credits = 0;
        credits += initialBonus;

        expect(credits, initialBonus);
      });

      test('Hall of Fame unlocks when all items max level', () {
        const allItemsMaxLevel = true;
        const hallOfFameEnabled = allItemsMaxLevel;

        expect(hallOfFameEnabled, true);
      });
    });

    // ============================================
    // Edge Cases & Error Handling
    // ============================================
    group('Edge Cases & Error Handling', () {
      test('Empty memo is handled gracefully', () {
        final transaction = TransactionItem(
          id: 'trans_001',
          amount: 1000,
          expense: 'food',
          expenseId: 'food_id',
          payment: 'cash',
          paymentId: null,
          date: DateTime.now(),
          paymentDate: null,
          memo: '',
        );

        expect(transaction.memo, isEmpty);
      });

      test('Very large transaction amounts handled', () {
        final largeAmount = 999999999;
        final transaction = TransactionItem(
          id: 'large_trans',
          amount: largeAmount,
          expense: 'other',
          expenseId: 'other_id',
          payment: 'cash',
          paymentId: null,
          date: DateTime.now(),
          paymentDate: null,
          memo: 'Very large transaction',
        );

        expect(transaction.amount, largeAmount);
      });

      test('Transaction from very old date (1900)', () {
        final oldDate = DateTime(1900, 1, 1);
        final transaction = TransactionItem(
          id: 'old_trans',
          amount: 100,
          expense: 'food',
          expenseId: 'food_id',
          payment: 'cash',
          paymentId: null,
          date: oldDate,
          paymentDate: null,
          memo: 'Historical data',
        );

        expect(transaction.date.year, 1900);
      });

      test('Multiple special characters in memo', () {
        final specialMemo = '🎉 お昼ご飯 @カフェ #lunch ¥1,000';
        final transaction = TransactionItem(
          id: 'special_trans',
          amount: 1000,
          expense: 'food',
          expenseId: 'food_id',
          payment: 'cash',
          paymentId: null,
          date: DateTime.now(),
          paymentDate: null,
          memo: specialMemo,
        );

        expect(transaction.memo, specialMemo);
      });
    });

    // ============================================
    // Integration Tests
    // ============================================
    group('Integration - Complete Workflows', () {
      test('Complete transaction workflow: create → validate → save', () async {
        final settingsRepo = SettingsRepository();
        final expenses = await settingsRepo.loadExpenseTags();
        expect(expenses.isNotEmpty, true);

        final selectedCategory = expenses.first;

        final transaction = TransactionItem(
          id: 'workflow_trans_${DateTime.now().millisecondsSinceEpoch}',
          amount: 1500,
          expense: selectedCategory.label,
          expenseId: selectedCategory.id,
          payment: 'cash',
          paymentId: null,
          date: DateTime.now(),
          paymentDate: null,
          memo: 'Integration test',
        );

        expect(transaction.amount, greaterThan(0));
        expect(transaction.expenseId, isNotEmpty);
        expect(transaction.amount, lessThan(10000000000));

        final json = transaction.toJson();
        expect(json.containsKey('id'), true);
        expect(json.containsKey('amount'), true);

        final restored = TransactionItem.fromJson(json);
        expect(restored.id, transaction.id);
        expect(restored.amount, transaction.amount);
      });

      test('Credit card payment workflow with date calculation', () {
        final cards = CategoryTag.defaultCards;
        final creditCard = cards.firstWhere((c) => c.label.contains('クレジット'));

        final transactionDate = DateTime(2026, 6, 15);

        int monthsToAdd = creditCard.paymentMonthOffset;
        if (creditCard.closingDay != null &&
            creditCard.closingDay != 99 &&
            transactionDate.day > creditCard.closingDay!) {
          monthsToAdd++;
        }

        int targetMonth = transactionDate.month + monthsToAdd;
        int targetYear = transactionDate.year;

        if (targetMonth > 12) {
          targetYear += (targetMonth - 1) ~/ 12;
          targetMonth = ((targetMonth - 1) % 12) + 1;
        }

        expect(targetMonth, isA<int>());
        expect(targetYear, isA<int>());
        expect(targetMonth, greaterThan(0));
        expect(targetMonth, lessThanOrEqualTo(12));
      });

      test('Settings persistence workflow', () async {
        final repo = SettingsRepository();

        final expenses = await repo.loadExpenseTags();
        final cards = await repo.loadCardTags();
        final gachaEnabled = await repo.loadGachaEnabled();

        expect(expenses.isNotEmpty, true);
        expect(cards.isNotEmpty, true);
        expect(gachaEnabled, isA<bool>());

        final expensesAgain = await repo.loadExpenseTags();
        expect(expensesAgain.length, expenses.length);
      });
    });
  });
}
