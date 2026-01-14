import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/category_tag.dart';
import '../models/transaction_item.dart';
import '../repositories/transaction_repository.dart';
import '../repositories/gacha_repository.dart';
import '../repositories/settings_repository.dart';
import '../widgets/category_selector.dart';
import '../widgets/custom_number_keyboard.dart';
import '../widgets/input/amount_input_area.dart';
import '../widgets/input/input_control_panel.dart';
import '../utils/simple_calculator.dart';
import 'settings/category_manage_screen.dart';

class InputTab extends StatefulWidget {
  final int dataVersion;
  final Function(bool visible)? onTabBarVisibilityChanged;

  const InputTab({
    super.key,
    this.dataVersion = 0,
    this.onTabBarVisibilityChanged,
  });

  @override
  State<InputTab> createState() => _InputTabState();
}

class _InputTabState extends State<InputTab>
    with AutomaticKeepAliveClientMixin, WidgetsBindingObserver {
  // --- Controllers & FocusNodes ---
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _memoController = TextEditingController();
  final FocusNode _amountFocusNode = FocusNode();
  final FocusNode _memoFocusNode = FocusNode();

  // --- Repositories ---
  final TransactionRepository _repository = TransactionRepository();
  final GachaRepository _gachaRepository = GachaRepository();
  final SettingsRepository _settingsRepository = SettingsRepository();

  // --- State ---
  List<CategoryTag> _expenseList = [];
  List<CategoryTag> _cardList = [];
  bool _isLoading = true;

  int _selectedExpenseIndex = 0;
  DateTime _selectedDate = DateTime.now();

  bool _isCardPayment = false;
  int _selectedCardIndex = 0;

  bool _showCustomKeyboard = false;
  String? _lastInputId;

  // キーボード高さ (キーエリア 272 + 閉じるバー 40)
  static const double _keyboardHeight = 312.0;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadAllData();

    _amountFocusNode.addListener(_onAmountFocusChange);
    _memoFocusNode.addListener(_onMemoFocusChange);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _amountFocusNode.removeListener(_onAmountFocusChange);
    _memoFocusNode.removeListener(_onMemoFocusChange);

    _amountController.dispose();
    _memoController.dispose();
    _amountFocusNode.dispose();
    _memoFocusNode.dispose();
    super.dispose();
  }

  @override
  void didChangeMetrics() {
    super.didChangeMetrics();
    final bottomInset = WidgetsBinding.instance.window.viewInsets.bottom;
    // OSキーボードが出たらカスタムキーボードを隠す
    if (bottomInset > 0 && _showCustomKeyboard && !_amountFocusNode.hasFocus) {
      setState(() => _showCustomKeyboard = false);
    }
  }

  @override
  void didUpdateWidget(covariant InputTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.dataVersion != widget.dataVersion) {
      _loadAllData();
    }
  }

  // --- Focus Handling ---
  void _onAmountFocusChange() {
    if (_amountFocusNode.hasFocus) {
      setState(() => _showCustomKeyboard = true);
      widget.onTabBarVisibilityChanged?.call(false);
    }
  }

  void _onMemoFocusChange() {
    if (_memoFocusNode.hasFocus) {
      setState(() => _showCustomKeyboard = false);
    }
  }

  void _closeKeyboard() {
    _amountFocusNode.unfocus();
    _memoFocusNode.unfocus();
    setState(() => _showCustomKeyboard = false);
    widget.onTabBarVisibilityChanged?.call(true);
  }

  // --- Data Loading ---
  Future<void> _loadAllData() async {
    final expenses = await _settingsRepository.loadExpenseTags();
    final cards = await _settingsRepository.loadCardTags();
    final prefs = await SharedPreferences.getInstance();

    int savedExpenseIndex = prefs.getInt('last_expense_index') ?? 0;
    if (savedExpenseIndex >= expenses.length) savedExpenseIndex = 0;
    int savedCardIndex = prefs.getInt('last_card_index') ?? 0;
    if (savedCardIndex >= cards.length) savedCardIndex = 0;
    final savedIsCard = prefs.getBool('last_is_card') ?? false;

    if (mounted) {
      setState(() {
        _expenseList = expenses;
        _cardList = cards;
        _selectedExpenseIndex = savedExpenseIndex;
        _selectedCardIndex = savedCardIndex;
        _isCardPayment = savedIsCard;
        _isLoading = false;
      });
    }
  }

  // --- User Actions ---
  Future<void> _pickDate() async {
    _closeKeyboard();
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );
    if (picked != null) setState(() => _selectedDate = picked);
  }

  Future<void> _changeExpenseIndex(int index) async {
    final prefs = await SharedPreferences.getInstance();
    setState(() => _selectedExpenseIndex = index);
    await prefs.setInt('last_expense_index', index);
  }

  Future<void> _toggleCardPayment(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    setState(() => _isCardPayment = value);
    _closeKeyboard();
    await prefs.setBool('last_is_card', value);
  }

  Future<void> _changeCardIndex(int index) async {
    final prefs = await SharedPreferences.getInstance();
    setState(() => _selectedCardIndex = index);
    _closeKeyboard();
    await prefs.setInt('last_card_index', index);
  }

  Future<void> _openCategorySettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('last_expense_index', _selectedExpenseIndex);

    if (!mounted) return;
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const CategoryManageScreen()),
    );
    await _loadAllData();
  }

  // --- Save Logic ---
  Future<void> _saveData({bool keepKeyboard = false}) async {
    if (_isLoading) return;

    final rawText = _amountController.text;
    final calculatedText = SimpleCalculator.calculate(rawText);

    if (calculatedText.isEmpty || calculatedText == "0") {
      _showSnackBar('金額を入力してください', Colors.redAccent);
      return;
    }

    _amountController.text = calculatedText;
    final int amount = double.tryParse(calculatedText)?.toInt() ?? 0;
    if (amount == 0) {
      _showSnackBar('金額を入力してください', Colors.redAccent);
      return;
    }
    if (_expenseList.isEmpty) {
      _showSnackBar('カテゴリがありません', Colors.redAccent);
      return;
    }
    if (_selectedExpenseIndex >= _expenseList.length) {
      _selectedExpenseIndex = 0;
    }

    if (!keepKeyboard) _closeKeyboard();

    // 支払い方法と日付の決定
    String paymentMethod = '';
    DateTime? paymentDate;

    if (_isCardPayment && _cardList.isNotEmpty) {
      final card = _cardList[_selectedCardIndex];
      paymentMethod = card.label;

      if (card.closingDay != null && card.paymentDay != null) {
        int monthsToAdd = card.paymentMonthOffset;
        if (card.closingDay != 99 && _selectedDate.day > card.closingDay!) {
          monthsToAdd++;
        }
        int targetYear = _selectedDate.year;
        int targetMonth = _selectedDate.month + monthsToAdd;
        int targetDay = card.paymentDay!;

        paymentDate = (targetDay == 99)
            ? DateTime(targetYear, targetMonth + 1, 0)
            : DateTime(targetYear, targetMonth, targetDay);
      }
    } else if (_isCardPayment) {
      paymentMethod = 'カード';
    }

    try {
      final newItem = TransactionItem(
        amount: amount,
        expense: _expenseList[_selectedExpenseIndex].label,
        payment: paymentMethod,
        date: DateTime(
          _selectedDate.year,
          _selectedDate.month,
          _selectedDate.day,
          DateTime.now().hour,
          DateTime.now().minute,
        ),
        paymentDate: paymentDate,
        memo: _memoController.text.trim(),
      );

      await _repository.addTransaction(newItem);
      final newCredits = await _gachaRepository.addCredit();

      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('last_expense_index', _selectedExpenseIndex);
      if (_isCardPayment) {
        await prefs.setInt('last_card_index', _selectedCardIndex);
      }
      await prefs.setBool('last_is_card', _isCardPayment);

      setState(() {
        _amountController.clear();
        _memoController.clear();
        _lastInputId = newItem.id;
      });

      if (keepKeyboard) _amountFocusNode.requestFocus();

      if (mounted) {
        String msg = '保存しました';
        if (newCredits % 3 == 0) {
          msg = 'ガチャが回せます！';
        } else if (paymentDate != null) {
          msg = '保存しました（支払日: ${paymentDate.month}/${paymentDate.day}）';
        }
        _showSnackBar(msg, newCredits % 3 == 0 ? Colors.orange : Colors.blue);
      }
    } catch (e) {
      _showSnackBar('保存エラー: $e', Colors.red);
    }
  }

  Future<void> _undoLastInput() async {
    if (_lastInputId == null) return;
    final allItems = await _repository.getAllTransactions();
    TransactionItem? targetItem;
    try {
      targetItem = allItems.firstWhere((e) => e.id == _lastInputId);
    } catch (_) {
      setState(() => _lastInputId = null);
      return;
    }

    if (!mounted) return;
    final weekDays = ["月", "火", "水", "木", "金", "土", "日"];
    final weekStr = weekDays[targetItem!.date.weekday - 1];

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('直前の入力を取り消しますか？'),
        content: Text(
          '¥${targetItem!.amount} (${targetItem.expense})\n'
          '日時: ${targetItem.date.month}/${targetItem.date.day} ($weekStr)',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('キャンセル'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await _repository.deleteTransaction(_lastInputId!);
              if (mounted) {
                setState(() => _lastInputId = null);
                _showSnackBar('入力を取り消しました', Colors.grey);
              }
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('削除する'),
          ),
        ],
      ),
    );
  }

  void _showSnackBar(String msg, Color color) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: color,
        duration: const Duration(milliseconds: 1500),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    if (_isLoading) return const Center(child: CircularProgressIndicator());

    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final double additionalPadding = _showCustomKeyboard
        ? _keyboardHeight
        : bottomInset;
    final double bottomPadding = 80 + additionalPadding;

    return GestureDetector(
      onTap: _closeKeyboard,
      behavior: HitTestBehavior.opaque,
      child: Stack(
        children: [
          Positioned.fill(
            child: SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(16, 10, 16, bottomPadding),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // 金額・日付・メモ入力エリア (Widget切り出し)
                  AmountInputArea(
                    selectedDate: _selectedDate,
                    amountController: _amountController,
                    amountFocusNode: _amountFocusNode,
                    memoController: _memoController,
                    memoFocusNode: _memoFocusNode,
                    onDateTap: _pickDate,
                    onAmountTap: () => _amountFocusNode.requestFocus(),
                  ),
                  const SizedBox(height: 20),

                  // カテゴリ選択
                  CategorySelector(
                    tags: _expenseList,
                    selectedIndex: _selectedExpenseIndex,
                    onSelected: _changeExpenseIndex,
                    onAddPressed: _openCategorySettings,
                  ),
                  const SizedBox(height: 20),

                  // 下部コントロールパネル (Widget切り出し)
                  InputControlPanel(
                    isCardPayment: _isCardPayment,
                    onToggleCard: _toggleCardPayment,
                    cardList: _cardList,
                    selectedCardIndex: _selectedCardIndex,
                    onCardSelected: _changeCardIndex,
                    onSave: () => _saveData(keepKeyboard: false),
                    onUndo: _undoLastInput,
                    showUndo: _lastInputId != null,
                  ),
                ],
              ),
            ),
          ),
          // カスタムキーボード
          if (_showCustomKeyboard)
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              height: _keyboardHeight,
              child: CustomNumberKeyboard(
                controller: _amountController,
                onSubmitted: () => _saveData(keepKeyboard: true),
                onClose: _closeKeyboard,
                onChanged: (_) {},
              ),
            ),
        ],
      ),
    );
  }
}
