import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/category_tag.dart';
// ▼ 今回作成したサービスをインポート
import '../services/input_service.dart';
import '../repositories/settings_repository.dart';
import '../widgets/category_selector.dart';
import '../widgets/custom_number_keyboard.dart';
import '../widgets/flash_message.dart';
import '../widgets/input/amount_input_area.dart';
import '../widgets/input/input_control_panel.dart';
import '../widgets/input/payment_selector.dart';
import 'settings/category_manage_screen.dart';
import 'history_screen.dart';

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

  // --- Services & Repositories ---
  final InputService _inputService = InputService(); // New!
  final SettingsRepository _settingsRepository = SettingsRepository();

  // --- State ---
  List<CategoryTag> _expenseList = [];
  List<CategoryTag> _cardList = [];
  bool _isGachaEnabled = true;
  bool _isCategoryLongPressEnabled = true;
  bool _showCardOnInput = true;
  bool _isLoading = true;

  int _selectedExpenseIndex = 0;
  DateTime _selectedDate = DateTime.now();

  bool _isCardPayment = false;
  int _selectedCardIndex = 0;

  bool _showCustomKeyboard = false;
  String? _lastInputId;

  // --- フラッシュメッセージ用 State ---
  bool _isFlashVisible = false;
  String _flashMsg = '';
  Color _flashColor = Colors.blue;
  Timer? _flashTimer;

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
    _flashTimer?.cancel();

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
    final gachaEnabled = await _settingsRepository.loadGachaEnabled();
    final catLongPressEnabled = await _settingsRepository
        .loadCategoryLongPressEnabled();
    final showCard = await _settingsRepository.loadShowCardOnInput();

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
        _isGachaEnabled = gachaEnabled;
        _isCategoryLongPressEnabled = catLongPressEnabled;
        _showCardOnInput = showCard;
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

  void _onCategoryLongPress(int index) {
    if (!_isCategoryLongPressEnabled) return;
    if (index >= _expenseList.length) return;

    _closeKeyboard();
    final tag = _expenseList[index];
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => HistoryScreen(
          filterValue: tag.label,
          filterKey: 'expense',
          color: tag.color,
        ),
      ),
    );
  }

  Future<void> _toggleCardPayment(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    setState(() => _isCardPayment = value);
    await prefs.setBool('last_is_card', value);
  }

  Future<void> _changeCardIndex(int index) async {
    final prefs = await SharedPreferences.getInstance();
    setState(() => _selectedCardIndex = index);
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

  void _onCardLongPress(CategoryTag tag) {
    _closeKeyboard();
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => HistoryScreen(
          filterValue: tag.label,
          filterKey: 'payment',
          color: tag.color,
        ),
      ),
    );
  }

  // --- Save Logic (大幅に簡略化！) ---
  Future<void> _saveData({bool keepKeyboard = false}) async {
    if (_isLoading) return;

    if (_expenseList.isEmpty) {
      _showFlashMessage('カテゴリがありません', Colors.redAccent);
      return;
    }
    // インデックス範囲外ガード
    if (_selectedExpenseIndex >= _expenseList.length) {
      _selectedExpenseIndex = 0;
    }

    if (!keepKeyboard) _closeKeyboard();

    // 選択されているカードタグの取得
    CategoryTag? selectedCardTag;
    if (_cardList.isNotEmpty && _selectedCardIndex < _cardList.length) {
      selectedCardTag = _cardList[_selectedCardIndex];
    }

    // ★ サービスに処理を委譲
    final result = await _inputService.registerTransaction(
      rawAmount: _amountController.text,
      memo: _memoController.text.trim(),
      date: _selectedDate,
      expenseTag: _expenseList[_selectedExpenseIndex],
      isCardPayment: _isCardPayment,
      cardTag: selectedCardTag,
      showCardOnInput: _showCardOnInput,
      isGachaEnabled: _isGachaEnabled,
    );

    // 結果に応じたUI更新
    if (result.success) {
      // 成功時
      if (result.formattedAmount != null) {
        _amountController.text = result.formattedAmount!;
      }

      // UI状態の保存（これはUIの責任）
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('last_expense_index', _selectedExpenseIndex);
      if (_showCardOnInput && _isCardPayment) {
        await prefs.setInt('last_card_index', _selectedCardIndex);
      }
      await prefs.setBool('last_is_card', _isCardPayment);

      setState(() {
        _amountController.clear();
        _memoController.clear();
        _lastInputId = result.savedId;
      });

      if (keepKeyboard) _amountFocusNode.requestFocus();

      if (mounted) {
        _showFlashMessage(result.message, result.messageColor);
      }
    } else {
      // 失敗時（バリデーションエラーなど）
      if (mounted) {
        _showFlashMessage(result.message, result.messageColor);
      }
    }
  }

  Future<void> _undoLastInput() async {
    if (_lastInputId == null) return;

    // 削除対象の情報を取得
    final targetItem = await _inputService.getTransaction(_lastInputId!);
    if (targetItem == null) {
      setState(() => _lastInputId = null);
      return;
    }

    if (!mounted) return;
    final weekDays = ["月", "火", "水", "木", "金", "土", "日"];
    final weekStr = weekDays[targetItem.date.weekday - 1];

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('直前の入力を取り消しますか？'),
        content: Text(
          '¥${targetItem.amount} (${targetItem.expense})\n'
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
              // ★ 削除処理もサービスに委譲
              await _inputService.deleteTransaction(_lastInputId!);
              if (mounted) {
                setState(() => _lastInputId = null);
                _showFlashMessage('入力を取り消しました', Colors.grey);
              }
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('削除する'),
          ),
        ],
      ),
    );
  }

  void _showFlashMessage(String msg, Color color) {
    _flashTimer?.cancel();
    setState(() {
      _flashMsg = msg;
      _flashColor = color;
      _isFlashVisible = true;
    });

    _flashTimer = Timer(const Duration(milliseconds: 1500), () {
      if (mounted) {
        setState(() {
          _isFlashVisible = false;
        });
      }
    });
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
                  AmountInputArea(
                    selectedDate: _selectedDate,
                    amountController: _amountController,
                    amountFocusNode: _amountFocusNode,
                    memoController: _memoController,
                    memoFocusNode: _memoFocusNode,
                    onDateTap: _pickDate,
                    onAmountTap: () => _amountFocusNode.requestFocus(),
                  ),

                  if (_showCardOnInput)
                    GestureDetector(
                      onTap: () {},
                      child: PaymentSelector(
                        isCardPayment: _isCardPayment,
                        onToggle: _toggleCardPayment,
                        cardList: _cardList,
                        selectedCardIndex: _selectedCardIndex,
                        onCardSelected: _changeCardIndex,
                        onCardLongPress: _onCardLongPress,
                      ),
                    )
                  else
                    const SizedBox(height: 24),

                  CategorySelector(
                    tags: _expenseList,
                    selectedIndex: _selectedExpenseIndex,
                    onSelected: _changeExpenseIndex,
                    onLongPress: _isCategoryLongPressEnabled
                        ? _onCategoryLongPress
                        : null,
                    onAddPressed: _openCategorySettings,
                  ),
                  const SizedBox(height: 20),
                  InputControlPanel(
                    onSave: () => _saveData(keepKeyboard: false),
                    onUndo: _undoLastInput,
                    showUndo: _lastInputId != null,
                  ),
                ],
              ),
            ),
          ),
          if (_showCustomKeyboard)
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              height: _keyboardHeight,
              child: CustomNumberKeyboard(
                controller: _amountController,
                onSubmitted: () => _saveData(keepKeyboard: true),
                onSaveAndClose: () => _saveData(keepKeyboard: false),
                onUndo: _lastInputId != null ? _undoLastInput : null,
                onClose: _closeKeyboard,
                onChanged: (_) {},
              ),
            ),

          FlashMessage(
            isVisible: _isFlashVisible,
            message: _flashMsg,
            color: _flashColor,
          ),
        ],
      ),
    );
  }
}
