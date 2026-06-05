import 'package:flutter/material.dart';

import '../../models/category_tag.dart';
import '../../models/transaction_item.dart';
import '../../services/input_service.dart';
import '../../utils/flash_message_mixin.dart';

class TransactionEditViewModel extends ChangeNotifier with FlashMessageMixin {
  final InputService _service;
  final TransactionItem initialItem;

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

  TransactionEditViewModel({
    required InputService inputService,
    required this.initialItem,
  }) : _service = inputService {
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
    // 1. カテゴリ等のマスタデータを読み込む
    data = await _service.loadInitialData();

    // 2. 初期値の設定
    amountController.text = initialItem.amount.toString();
    memoController.text = initialItem.memo;
    selectedDate = initialItem.date;

    // 費目の初期選択
    if (initialItem.expenseId != null) {
      final index = data!.expenses.indexWhere(
        (e) => e.id == initialItem.expenseId,
      );
      if (index != -1) {
        selectedExpenseIndex = index;
      } else {
        // IDで見つからなければ名前で検索
        final indexByName = data!.expenses.indexWhere(
          (e) => e.label == initialItem.expense,
        );
        if (indexByName != -1) selectedExpenseIndex = indexByName;
      }
    } else {
      // IDがない場合（古いデータなど）は名前で検索
      final indexByName = data!.expenses.indexWhere(
        (e) => e.label == initialItem.expense,
      );
      if (indexByName != -1) selectedExpenseIndex = indexByName;
    }

    // 支払いの初期選択
    if (initialItem.paymentId != null) {
      isCardPayment = true;
      final index = data!.cards.indexWhere(
        (c) => c.id == initialItem.paymentId,
      );
      if (index != -1) {
        selectedCardIndex = index;
      } else {
        // IDで見つからなければ名前で検索
        final indexByName = data!.cards.indexWhere(
          (c) => c.label == initialItem.payment,
        );
        if (indexByName != -1) selectedCardIndex = indexByName;
      }
    } else {
      // 支払い方法が記録されているがIDがない場合
      if (initialItem.payment.isNotEmpty &&
          initialItem.payment != '現金' &&
          initialItem.payment != '不明') {
        // カードリストにあるかチェック
        final indexByName = data!.cards.indexWhere(
          (c) => c.label == initialItem.payment,
        );
        if (indexByName != -1) {
          isCardPayment = true;
          selectedCardIndex = indexByName;
        } else {
          // 現金扱いまたは不明
          isCardPayment = false;
        }
      } else {
        isCardPayment = false;
      }
    }

    isLoading = false;
    notifyListeners();
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
    notifyListeners();
  }

  void toggleCardPayment(bool value) {
    isCardPayment = value;
    notifyListeners();
  }

  void setCardIndex(int index) {
    selectedCardIndex = index;
    notifyListeners();
  }

  // --- Save Logic ---
  Future<bool> saveData(BuildContext context) async {
    if (isLoading || data == null) return false;
    if (data!.expenses.isEmpty) {
      showFlash("カテゴリがありません", Colors.redAccent);
      return false;
    }

    if (selectedExpenseIndex >= data!.expenses.length) {
      selectedExpenseIndex = 0;
    }

    closeKeyboard();

    CategoryTag? selectedCardTag;
    if (data!.cards.isNotEmpty && selectedCardIndex < data!.cards.length) {
      selectedCardTag = data!.cards[selectedCardIndex];
    }

    final result = await _service.updateTransaction(
      id: initialItem.id,
      rawAmount: amountController.text,
      memo: memoController.text.trim(),
      date: selectedDate,
      expenseTag: data!.expenses[selectedExpenseIndex],
      isCardPayment: isCardPayment,
      cardTag: selectedCardTag,
      showCardOnInput: data!.showCardOnInput,
    );

    if (result.success) {
      showFlash(result.message, result.messageColor);
      return true;
    } else {
      showFlash(result.message, result.messageColor);
      return false;
    }
  }

  Future<void> deleteTransaction(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('履歴を削除しますか？'),
        content: Text(
          '¥${initialItem.amount} (${initialItem.expense})\n'
          '日時: ${initialItem.date.month}/${initialItem.date.day}',
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
      await _service.deleteTransaction(initialItem.id);
      if (context.mounted) {
        Navigator.pop(context); // 画面を閉じる
      }
    }
  }
}
