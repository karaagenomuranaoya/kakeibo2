import 'dart:math'; // max関数用
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/category_tag.dart';
import '../models/transaction_item.dart';
import '../repositories/transaction_repository.dart';
import '../repositories/gacha_repository.dart';
import '../repositories/settings_repository.dart';
import '../widgets/category_selector.dart';
import '../widgets/custom_number_keyboard.dart';
import '../utils/simple_calculator.dart';

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
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _memoController = TextEditingController();

  final FocusNode _amountFocusNode = FocusNode();
  final FocusNode _memoFocusNode = FocusNode();

  final TransactionRepository _repository = TransactionRepository();
  final GachaRepository _gachaRepository = GachaRepository();
  final SettingsRepository _settingsRepository = SettingsRepository();

  List<CategoryTag> _expenseList = [];
  List<CategoryTag> _cardList = [];
  bool _isLoading = true;

  int _selectedExpenseIndex = 0;
  DateTime _selectedDate = DateTime.now();

  bool _isCardPayment = false;
  int _selectedCardIndex = 0;

  bool _showCustomKeyboard = false;
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

    // 金額入力以外でOSキーボードが出たらカスタムキーボードを隠す
    if (bottomInset > 0 && _showCustomKeyboard && !_amountFocusNode.hasFocus) {
      setState(() {
        _showCustomKeyboard = false;
      });
    }
  }

  void _onAmountFocusChange() {
    if (_amountFocusNode.hasFocus) {
      setState(() {
        _showCustomKeyboard = true;
      });
      widget.onTabBarVisibilityChanged?.call(false);
    }
  }

  void _onMemoFocusChange() {
    if (_memoFocusNode.hasFocus) {
      setState(() {
        _showCustomKeyboard = false;
      });
    }
  }

  @override
  void didUpdateWidget(covariant InputTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.dataVersion != widget.dataVersion) {
      _loadAllData();
    }
  }

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

  Future<void> _changeExpenseIndex(int index) async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _selectedExpenseIndex = index;
    });
    await prefs.setInt('last_expense_index', index);
  }

  Future<void> _toggleCardPayment(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _isCardPayment = value;
    });
    _closeKeyboard();
    await prefs.setBool('last_is_card', value);
  }

  Future<void> _changeCardIndex(int index) async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _selectedCardIndex = index;
    });
    _closeKeyboard();
    await prefs.setInt('last_card_index', index);
  }

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

  void _closeKeyboard() {
    _amountFocusNode.unfocus();
    _memoFocusNode.unfocus();
    setState(() {
      _showCustomKeyboard = false;
    });
    widget.onTabBarVisibilityChanged?.call(true);
  }

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
      _showSnackBar('カテゴリがありません。設定から追加してください', Colors.redAccent);
      return;
    }

    if (_selectedExpenseIndex >= _expenseList.length) {
      _selectedExpenseIndex = 0;
    }

    if (!keepKeyboard) {
      _closeKeyboard();
    }

    String paymentMethod = '';
    DateTime? paymentDate;

    if (_isCardPayment) {
      if (_cardList.isNotEmpty) {
        final card = _cardList[_selectedCardIndex];
        paymentMethod = card.label;

        if (card.closingDay != null && card.paymentDay != null) {
          int monthsToAdd = card.paymentMonthOffset;
          if (card.closingDay != 99) {
            if (_selectedDate.day > card.closingDay!) {
              monthsToAdd++;
            }
          }
          int targetYear = _selectedDate.year;
          int targetMonth = _selectedDate.month + monthsToAdd;
          int targetDay = card.paymentDay!;

          if (targetDay == 99) {
            paymentDate = DateTime(targetYear, targetMonth + 1, 0);
          } else {
            paymentDate = DateTime(targetYear, targetMonth, targetDay);
          }
        }
      } else {
        paymentMethod = 'カード';
      }
    } else {
      paymentMethod = '';
    }

    final String expenseLabel = _expenseList[_selectedExpenseIndex].label;

    try {
      final newItem = TransactionItem(
        amount: amount,
        expense: expenseLabel,
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
      });

      if (keepKeyboard) {
        _amountFocusNode.requestFocus();
      }

      if (mounted) {
        String msg = '保存しました';
        if (newCredits % 3 == 0) {
          msg = 'ガチャが回せます！';
        } else if (paymentDate != null) {
          msg = '保存しました（支払日: ${paymentDate!.month}/${paymentDate!.day}）';
        }
        _showSnackBar(msg, newCredits % 3 == 0 ? Colors.orange : Colors.blue);
      }
    } catch (e) {
      _showSnackBar('保存エラー: $e', Colors.red);
    }
  }

  void _showSnackBar(String msg, Color color) {
    if (!mounted) return;
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

    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    final dateStr = DateFormat('MM/dd').format(_selectedDate);

    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    // 下部パディング計算
    final double additionalPadding = _showCustomKeyboard
        ? _keyboardHeight
        : bottomInset;

    // 基本パディング80 + キーボード分
    final double bottomPadding = 80 + additionalPadding;

    return GestureDetector(
      onTap: _closeKeyboard,
      behavior: HitTestBehavior.opaque,
      child: Stack(
        children: [
          // コンテンツ領域
          Positioned.fill(
            child: SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(16, 10, 16, bottomPadding),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  GestureDetector(
                    onTap: _pickDate,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.blue.shade100),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.calendar_today,
                            size: 14,
                            color: Colors.blue,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            "$dateStr (${_getDayOfWeek(_selectedDate)})",
                            style: const TextStyle(
                              color: Colors.blue,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 15),

                  GestureDetector(
                    onTap: () {
                      _amountFocusNode.requestFocus();
                    },
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        const Text(
                          "¥",
                          style: TextStyle(
                            fontSize: 56,
                            fontWeight: FontWeight.bold,
                            color: Colors.black54,
                          ),
                        ),
                        const SizedBox(width: 10),
                        IntrinsicWidth(
                          child: TextField(
                            controller: _amountController,
                            focusNode: _amountFocusNode,
                            readOnly: true,
                            showCursor: true,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 56,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                              height: 1.0,
                            ),
                            decoration: const InputDecoration(
                              hintText: '0',
                              hintStyle: TextStyle(color: Colors.black12),
                              border: InputBorder.none,
                              isDense: true,
                              contentPadding: EdgeInsets.zero,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),

                  Container(
                    width: 240,
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: TextField(
                      controller: _memoController,
                      focusNode: _memoFocusNode,
                      textAlign: TextAlign.center,
                      decoration: const InputDecoration(
                        hintText: 'メモを入力...',
                        isDense: true,
                        contentPadding: EdgeInsets.symmetric(vertical: 8),
                        border: InputBorder.none,
                        hintStyle: TextStyle(fontSize: 12, color: Colors.grey),
                        prefixIcon: Icon(
                          Icons.edit,
                          size: 14,
                          color: Colors.grey,
                        ),
                        prefixIconConstraints: BoxConstraints(minWidth: 24),
                      ),
                      style: const TextStyle(fontSize: 13),
                      textInputAction: TextInputAction.done,
                      onSubmitted: (_) => _memoFocusNode.unfocus(),
                    ),
                  ),
                  const SizedBox(height: 20),

                  CategorySelector(
                    tags: _expenseList,
                    selectedIndex: _selectedExpenseIndex,
                    onSelected: (i) => _changeExpenseIndex(i),
                  ),
                  const SizedBox(height: 20),

                  _buildBottomControlPanel(context),
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
                onClose: _closeKeyboard, // 閉じるボタンでキーボードを閉じる
                onChanged: (val) {},
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildBottomControlPanel(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
        border: Border.all(color: Colors.grey.shade200),
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        children: [
          Row(
            children: [
              Text(
                "カード",
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: _isCardPayment ? Colors.blue : Colors.grey,
                ),
              ),
              const SizedBox(width: 5),
              Transform.scale(
                scale: 0.8,
                child: Switch(
                  value: _isCardPayment,
                  activeColor: Colors.blue,
                  onChanged: (bool value) => _toggleCardPayment(value),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _isCardPayment && _cardList.isNotEmpty
                    ? SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: _cardList.asMap().entries.map((entry) {
                            final index = entry.key;
                            final tag = entry.value;
                            final isSelected = _selectedCardIndex == index;
                            return Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: ChoiceChip(
                                label: Text(tag.label),
                                labelStyle: TextStyle(
                                  fontSize: 11,
                                  color: isSelected
                                      ? Colors.white
                                      : Colors.black87,
                                  fontWeight: isSelected
                                      ? FontWeight.bold
                                      : FontWeight.normal,
                                ),
                                selected: isSelected,
                                showCheckmark: false,
                                selectedColor: tag.color,
                                backgroundColor: Colors.grey.shade100,
                                onSelected: (_) => _changeCardIndex(index),
                                visualDensity: VisualDensity.compact,
                              ),
                            );
                          }).toList(),
                        ),
                      )
                    : const SizedBox.shrink(),
              ),
            ],
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => _saveData(keepKeyboard: false),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              child: const Text(
                '保存',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _getDayOfWeek(DateTime date) {
    const weekDays = ["月", "火", "水", "木", "金", "土", "日"];
    return weekDays[date.weekday - 1];
  }
}
