import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/category_tag.dart';
import '../models/transaction_item.dart';
import '../repositories/transaction_repository.dart';
import '../repositories/gacha_repository.dart';
import '../repositories/settings_repository.dart';
import '../widgets/category_selector.dart';
import '../widgets/custom_numeric_keyboard.dart';

class InputTab extends StatefulWidget {
  final int dataVersion;
  const InputTab({super.key, this.dataVersion = 0});

  @override
  State<InputTab> createState() => _InputTabState();
}

class _InputTabState extends State<InputTab> {
  String _amountStr = "0";
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

  @override
  void initState() {
    super.initState();
    _loadAllData();
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
    await prefs.setBool('last_is_card', value);
  }

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
    if (_isLoading) return;

    final int amount = int.tryParse(_amountStr) ?? 0;
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

    final String paymentMethod = _isCardPayment
        ? (_cardList.isNotEmpty ? _cardList[_selectedCardIndex].label : 'カード')
        : '';

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
        _amountStr = "0";
      });

      if (newCredits % 3 == 0) {
        _showSnackBar('ガチャが回せます！', Colors.orange);
      } else {
        _showSnackBar('保存しました', Colors.blue);
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
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    final dateStr = DateFormat('MM/dd').format(_selectedDate);

    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            // 余白を最小限に抑えて、コンテンツ領域を確保
            padding: const EdgeInsets.fromLTRB(16, 5, 16, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                GestureDetector(
                  onTap: _pickDate,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.blue.shade100),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.calendar_today,
                            size: 14, color: Colors.blue),
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
                // 金額表示の周りの余白を削減
                const SizedBox(height: 5),
                FittedBox(
                  child: Text(
                    "¥ $_amountStr",
                    style: const TextStyle(
                      // 文字サイズを少し小さくして圧迫感を減らす (52 -> 44)
                      fontSize: 44,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                      height: 1.0,
                    ),
                  ),
                ),
                // カテゴリとの間隔も詰める
                const SizedBox(height: 10),

                CategorySelector(
                  tags: _expenseList,
                  selectedIndex: _selectedExpenseIndex,
                  onSelected: (i) => _changeExpenseIndex(i),
                ),
                // 下部の余白
                const SizedBox(height: 10),
              ],
            ),
          ),
        ),

        // 固定フッターエリア
        Container(
          width: double.infinity,
          height: 50, // 高さも少しコンパクトに (56 -> 50)
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
              Expanded(
                child: _isCardPayment && _cardList.isNotEmpty
                    ? ListView.builder(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 8),
                        itemCount: _cardList.length,
                        itemBuilder: (context, index) {
                          final tag = _cardList[index];
                          final isSelected = _selectedCardIndex == index;
                          return Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: ChoiceChip(
                              label: Text(
                                tag.label,
                                style: TextStyle(
                                  fontSize: 11, // フォントサイズ調整
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
        // テンキー
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
