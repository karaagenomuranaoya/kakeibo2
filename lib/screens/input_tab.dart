import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/category_tag.dart';
import '../models/transaction_item.dart';
import '../repositories/transaction_repository.dart';
import '../widgets/category_selector.dart';
import '../widgets/custom_numeric_keyboard.dart';

class InputTab extends StatefulWidget {
  const InputTab({super.key});

  @override
  State<InputTab> createState() => _InputTabState();
}

class _InputTabState extends State<InputTab> {
  String _amountStr = "0";
  final TransactionRepository _repository = TransactionRepository();

  // 初期値は 0 (リストの先頭) にしておき、nullチェックの手間を減らす
  int _selectedExpenseIndex = 0;
  DateTime _selectedDate = DateTime.now();

  bool _isCardPayment = false;
  int _selectedCardIndex = 0;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  // 設定の読み込み（カード ＆ 費目）
  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      // 1. カード設定の復元
      _isCardPayment = prefs.getBool('last_is_card') ?? false;
      _selectedCardIndex = prefs.getInt('last_card_index') ?? 0;
      if (_selectedCardIndex >= creditCardTags.length) {
        _selectedCardIndex = 0;
      }

      // 2. 費目設定の復元
      _selectedExpenseIndex = prefs.getInt('last_expense_index') ?? 0;
      if (_selectedExpenseIndex >= expenseTags.length) {
        _selectedExpenseIndex = 0;
      }
    });
  }

  // 費目変更時に保存
  Future<void> _changeExpenseIndex(int index) async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _selectedExpenseIndex = index;
    });
    await prefs.setInt('last_expense_index', index);
  }

  // カードスイッチ切り替え時に保存
  Future<void> _toggleCardPayment(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _isCardPayment = value;
    });
    await prefs.setBool('last_is_card', value);
  }

  // カード種類変更時に保存
  Future<void> _changeCardIndex(int index) async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _selectedCardIndex = index;
    });
    await prefs.setInt('last_card_index', index);
  }

  void _onNumberTap(String key) {
    if (key == '.') return;
    setState(() {
      if (_amountStr == "0") {
        if (key == "00") return;
        _amountStr = key;
      } else {
        if (_amountStr.length < 9) {
          _amountStr += key;
        }
      }
    });
  }

  void _onBackspace() {
    setState(() {
      if (_amountStr.length > 1) {
        _amountStr = _amountStr.substring(0, _amountStr.length - 1);
      } else {
        _amountStr = "0";
      }
    });
  }

  void _onClear() {
    setState(() {
      _amountStr = "0";
    });
  }

  Future<void> _pickDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );
    if (picked != null) setState(() => _selectedDate = picked);
  }

  Future<void> _saveData() async {
    final int amount = int.tryParse(_amountStr) ?? 0;
    if (amount == 0) {
      _showSnackBar('金額を入力してください', Colors.redAccent);
      return;
    }

    final String paymentMethod =
        _isCardPayment ? creditCardTags[_selectedCardIndex].label : '現金';

    // 費目は必ず選択されている前提
    final String expenseLabel = expenseTags[_selectedExpenseIndex].label;

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
      );

      await _repository.addTransaction(newItem);

      // 保存時に念のため設定を再保存（冗長だが安全）
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('last_expense_index', _selectedExpenseIndex);
      if (_isCardPayment) {
        await prefs.setInt('last_card_index', _selectedCardIndex);
      }
      await prefs.setBool('last_is_card', _isCardPayment);

      setState(() {
        _amountStr = "0";
        // ▼▼ 変更: 費目のリセット(_selectedExpenseIndex = null)を削除し、位置をキープ ▼▼
      });

      _showSnackBar('保存しました', Colors.blue);
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
        duration: const Duration(milliseconds: 800),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final dateStr = DateFormat('MM/dd').format(_selectedDate);

    return Column(
      children: [
        // --- 1. スクロール領域（日付、金額、費目） ---
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(height: 5),
                GestureDetector(
                  onTap: _pickDate,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.blue.shade100),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.calendar_today,
                            size: 16, color: Colors.blue),
                        const SizedBox(width: 8),
                        Text(
                          "$dateStr (${_getDayOfWeek(_selectedDate)})",
                          style: const TextStyle(
                            color: Colors.blue,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                FittedBox(
                  child: Text(
                    "¥ $_amountStr",
                    style: const TextStyle(
                      fontSize: 56,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                ),
                const SizedBox(height: 10),

                // 費目選択
                CategorySelector(
                  tags: expenseTags,
                  selectedIndex: _selectedExpenseIndex,
                  rowCount: 2,
                  // ▼▼ 変更: 選択時に即時保存する関数を呼ぶ ▼▼
                  onSelected: (i) => _changeExpenseIndex(i),
                ),

                const SizedBox(height: 10),
              ],
            ),
          ),
        ),

        // --- 2. 支払い設定バー（固定） ---
        Container(
          width: double.infinity,
          height: 56,
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 4,
                offset: const Offset(0, -2),
              )
            ],
            border: Border(
              top: BorderSide(color: Colors.grey.shade200),
            ),
          ),
          child: Row(
            children: [
              // 左側：カード選択エリア（ONの時のみ表示）
              Expanded(
                child: _isCardPayment
                    ? ListView.builder(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 8),
                        itemCount: creditCardTags.length,
                        itemBuilder: (context, index) {
                          final tag = creditCardTags[index];
                          final isSelected = _selectedCardIndex == index;
                          return Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: ChoiceChip(
                              label: Text(
                                tag.label,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: isSelected
                                      ? Colors.white
                                      : Colors.black87,
                                  fontWeight: isSelected
                                      ? FontWeight.bold
                                      : FontWeight.normal,
                                ),
                              ),
                              selected: isSelected,
                              showCheckmark: false,
                              selectedColor: tag.color,
                              backgroundColor: Colors.grey.shade100,
                              onSelected: (_) => _changeCardIndex(index),
                              visualDensity: VisualDensity.compact,
                            ),
                          );
                        },
                      )
                    : const SizedBox.shrink(),
              ),

              // 右側：カードON/OFFスイッチ
              Padding(
                padding: const EdgeInsets.only(right: 16, left: 8),
                child: Row(
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
                  ],
                ),
              ),
            ],
          ),
        ),

        // --- 3. キーボード（固定） ---
        CustomNumericKeyboard(
          onNumberTap: _onNumberTap,
          onBackspace: _onBackspace,
          onClear: _onClear,
          onDone: _saveData,
        ),
      ],
    );
  }

  String _getDayOfWeek(DateTime date) {
    const weekDays = ["月", "火", "水", "木", "金", "土", "日"];
    return weekDays[date.weekday - 1];
  }
}
