import 'package:flutter/material.dart';
import '../../models/category_tag.dart';
import '../../services/input_service.dart';
import '../../utils/flash_message_mixin.dart'; // Import

// ▼▼ with FlashMessageMixin を追加 ▼▼
class InputTabViewModel extends ChangeNotifier with FlashMessageMixin {
  final InputService _service = InputService();

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

  // Flash Message関連の変数は Mixin に移動したので削除！

  InputTabViewModel() {
    amountFocusNode.addListener(_onAmountFocusChange);
    memoFocusNode.addListener(_onMemoFocusChange);
  }

  @override
  void dispose() {
    amountController.dispose();
    memoController.dispose();
    amountFocusNode.dispose();
    memoFocusNode.dispose();
    super.dispose(); // Mixinのdisposeも呼ばれる
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
      showFlash('カテゴリがありません', Colors.redAccent); // Mixinのメソッド
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

      showFlash(result.message, result.messageColor); // Mixinのメソッド
    } else {
      showFlash(result.message, result.messageColor); // Mixinのメソッド
    }
  }

  // --- Undo Logic ---
  Future<void> undoLastInput(BuildContext context) async {
    if (lastInputId == null) return;

    final targetItem = await _service.getTransaction(lastInputId!);
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
      showFlash('入力を取り消しました', Colors.grey); // Mixinのメソッド
    }
  }

  Future<void> markTutorialAsShown() async {
    await _service.markTutorialAsShown();
  }
}
