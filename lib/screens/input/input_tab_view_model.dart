import 'dart:math'; // Random用
import 'package:flutter/material.dart';

import '../../models/category_tag.dart';
import '../../models/transaction_item.dart'; // TransactionItem用
import '../../services/input_service.dart';
import '../../utils/flash_message_mixin.dart';
import '../../repositories/transaction_repository.dart'; // Repository用
import '../../repositories/gacha_repository.dart'; // Repository用

class InputTabViewModel extends ChangeNotifier with FlashMessageMixin {
  final InputService _service; // Injected InputService

  // --- Controllers & FocusNodes ---
  final TextEditingController amountController = TextEditingController();
  final TextEditingController memoController = TextEditingController();
  final FocusNode amountFocusNode = FocusNode();
  final FocusNode memoFocusNode = FocusNode();

  // --- State Data ---
  InputInitialData? data;
  bool isLoading = true;

  // --- Selections ---
  int selectedExpenseIndex = 0;
  DateTime selectedDate = DateTime.now();
  bool isCardPayment = false;
  int selectedCardIndex = 0;

  // --- UI Control State ---
  bool showCustomKeyboard = false;
  String? lastInputId;

  // Modified constructor to accept InputService
  InputTabViewModel({required InputService inputService})
    : _service = inputService {
    amountFocusNode.addListener(_onAmountFocusChange);
    memoFocusNode.addListener(_onMemoFocusChange);
  }

  @override
  void dispose() {
    amountController.dispose();
    memoController.dispose();
    amountFocusNode.dispose();
    memoFocusNode.dispose();
    super.dispose();
  }

  // --- Initialization ---
  Future<void> loadData() async {
    data = await _service.loadInitialData();
    if (data != null) {
      selectedExpenseIndex = data!.lastExpenseIndex;
      selectedCardIndex = data!.lastCardIndex;
      isCardPayment = data!.lastIsCard;
      isLoading = false;
      notifyListeners();
    }
  }

  // --- Focus & Keyboard Logic ---
  void _onAmountFocusChange() {
    if (amountFocusNode.hasFocus) {
      showCustomKeyboard = true;
      notifyListeners();
    }
  }

  void _onMemoFocusChange() {
    if (memoFocusNode.hasFocus) {
      showCustomKeyboard = false;
      notifyListeners();
    }
  }

  void closeKeyboard() {
    amountFocusNode.unfocus();
    memoFocusNode.unfocus();
    showCustomKeyboard = false;
    notifyListeners();
  }

  void onSystemKeyboardShown() {
    if (showCustomKeyboard && !amountFocusNode.hasFocus) {
      showCustomKeyboard = false;
      notifyListeners();
    }
  }

  // --- User Actions ---
  Future<void> pickDate(BuildContext context) async {
    closeKeyboard();
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );
    if (picked != null) {
      selectedDate = picked;
      notifyListeners();
    }
  }

  void setExpenseIndex(int index) {
    selectedExpenseIndex = index;
    _service.saveLastInputState(expenseIndex: index);
    notifyListeners();
  }

  void toggleCardPayment(bool value) {
    isCardPayment = value;
    _service.saveLastInputState(isCard: value);
    notifyListeners();
  }

  void setCardIndex(int index) {
    selectedCardIndex = index;
    _service.saveLastInputState(cardIndex: index);
    notifyListeners();
  }

  // --- Save Logic ---
  Future<void> saveData({bool keepKeyboard = false}) async {
    if (isLoading || data == null) return;
    if (data!.expenses.isEmpty) {
      showFlash("カテゴリがありません", Colors.redAccent);
      return;
    }

    if (selectedExpenseIndex >= data!.expenses.length) {
      selectedExpenseIndex = 0;
    }

    if (!keepKeyboard) closeKeyboard();

    CategoryTag? selectedCardTag;
    if (data!.cards.isNotEmpty && selectedCardIndex < data!.cards.length) {
      selectedCardTag = data!.cards[selectedCardIndex];
    }

    final result = await _service.registerTransaction(
      rawAmount: amountController.text,
      memo: memoController.text.trim(),
      date: selectedDate,
      expenseTag: data!.expenses[selectedExpenseIndex],
      isCardPayment: isCardPayment,
      cardTag: selectedCardTag,
      showCardOnInput: data!.showCardOnInput,
      isGachaEnabled: data!.isGachaEnabled,
    );

    if (result.success) {
      if (result.formattedAmount != null) {
        amountController.text = result.formattedAmount!;
      }

      await _service.saveLastInputState(
        expenseIndex: selectedExpenseIndex,
        cardIndex: data!.showCardOnInput && isCardPayment
            ? selectedCardIndex
            : null,
        isCard: isCardPayment,
      );

      amountController.clear();
      memoController.clear();
      lastInputId = result.savedId;

      if (keepKeyboard) amountFocusNode.requestFocus();

      showFlash(result.message, result.messageColor);
    } else {
      showFlash(result.message, result.messageColor);
    }
  }

  // --- Undo Logic ---
  Future<void> undoLastInput(BuildContext context) async {
    if (lastInputId == null) return;

    final targetItem = await _service.getTransaction(
      lastInputId!,
    ); // Corrected typo here
    if (targetItem == null) {
      lastInputId = null;
      notifyListeners();
      return;
    }

    if (!context.mounted) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('直前の入力を取り消しますか？'),
        content: Text(
          '¥${targetItem.amount} (${targetItem.expense})\n'
          '日時: ${targetItem.date.month}/${targetItem.date.day}',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('キャンセル'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('削除する'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _service.deleteTransaction(lastInputId!);
      lastInputId = null;
      showFlash('入力を取り消しました', Colors.grey);
    }
  }

  Future<void> markTutorialAsShown() async {
    await _service.markTutorialAsShown();
  }

  // ▼▼▼ 追加: デモデータ注入機能 ▼▼▼
  Future<void> confirmAndInjectDemoData(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('デモデータ注入'),
        content: const Text(
          '先月〜今月の家計簿データ（約50件）と、\n'
          'ガチャデータをランダムに注入します。\n\n'
          '※この操作は取り消せません。',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('キャンセル'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('実行する'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;
    if (data == null || data!.expenses.isEmpty) {
      showFlash('カテゴリがないため実行できません', Colors.red);
      return;
    }

    closeKeyboard();
    isLoading = true;
    notifyListeners();

    try {
      final random = Random();
      final transRepo = TransactionRepository();
      final gachaRepo = GachaRepository();

      final now = DateTime.now();

      // 1. 家計簿データの注入
      for (int i = 0; i < 50; i++) {
        final daysAgo = random.nextInt(60); // 0〜59日前
        final targetDate = now.subtract(Duration(days: daysAgo));
        final amount = (random.nextInt(50) + 1) * 100;

        final expense = data!.expenses[random.nextInt(data!.expenses.length)];

        String payment = '記録しない';
        CategoryTag? card;
        DateTime? paymentDate;

        if (random.nextDouble() < 0.3 && data!.cards.isNotEmpty) {
          card = data!.cards[random.nextInt(data!.cards.length)];
          payment = card.label;
          paymentDate = DateTime(targetDate.year, targetDate.month + 2, 27);
        }

        final item = TransactionItem(
          amount: amount,
          expense: expense.label,
          payment: payment,
          date: DateTime(
            targetDate.year,
            targetDate.month,
            targetDate.day,
            12 + random.nextInt(8),
            random.nextInt(60),
          ),
          paymentDate: paymentDate,
          memo: 'デモデータ',
        );

        await transRepo.addTransaction(item);
      }

      // 2. ガチャデータの注入
      final monsters = await gachaRepo.getItems();
      for (final monster in monsters) {
        if (random.nextDouble() < 0.8) {
          int targetLevel = random.nextInt(10) + 1;
          for (int k = 0; k < targetLevel; k++) {
            await gachaRepo.unlockItem(monster.id);
          }
        }
      }

      showFlash('デモデータを注入しました', Colors.green);
    } catch (e) {
      showFlash('エラーが発生しました: $e', Colors.red);
    } finally {
      isLoading = false;
      await loadData();
      amountController.clear();
      notifyListeners();
    }
  }
}
