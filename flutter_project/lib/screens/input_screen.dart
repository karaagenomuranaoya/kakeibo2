import 'package:flutter/material.dart';
import '../models/category_tag.dart';
import '../models/transaction_item.dart';
import '../repositories/transaction_repository.dart';
import '../widgets/category_selector.dart';
import '../widgets/app_drawer.dart';

class InputScreen extends StatefulWidget {
  const InputScreen({super.key});
  @override
  State<InputScreen> createState() => _InputScreenState();
}

class _InputScreenState extends State<InputScreen> {
  final TextEditingController _amountController = TextEditingController();
  final FocusNode _amountFocusNode = FocusNode();
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final TransactionRepository _repository = TransactionRepository();

  int? _selectedExpenseIndex;
  int? _selectedPaymentIndex;
  DateTime _selectedDate = DateTime.now();

  @override
  void dispose() {
    _amountFocusNode.dispose();
    _amountController.dispose();
    super.dispose();
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

  Future<void> _saveData({required bool shouldDismissKeyboard}) async {
    final amountText = _amountController.text;
    if (amountText.isEmpty || amountText == "0") {
      if (shouldDismissKeyboard) _amountFocusNode.unfocus();
      return;
    }

    final newItem = TransactionItem(
      amount: int.tryParse(amountText) ?? 0,
      expense: _selectedExpenseIndex != null
          ? expenseTags[_selectedExpenseIndex!].label
          : '未分類',
      payment: _selectedPaymentIndex != null
          ? paymentTags[_selectedPaymentIndex!].label
          : '現金',
      date: DateTime(
        _selectedDate.year,
        _selectedDate.month,
        _selectedDate.day,
        DateTime.now().hour,
        DateTime.now().minute,
      ),
    );

    await _repository.addTransaction(newItem);

    setState(() {
      _amountController.clear();
      _selectedExpenseIndex = null;
      _selectedPaymentIndex = null;
    });

    if (shouldDismissKeyboard) _amountFocusNode.unfocus();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('保存しました'),
          duration: Duration(milliseconds: 500),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      onDrawerChanged: (isOpened) {
        if (isOpened) _amountFocusNode.unfocus();
      },
      drawer: const AppDrawer(),
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        behavior: HitTestBehavior.opaque,
        child: Stack(
          children: [
            Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(20, 80, 20, 0),
                    child: Column(
                      children: [
                        _buildAmountInput(),
                        const SizedBox(height: 15),
                        CategorySelector(
                          tags: expenseTags,
                          selectedIndex: _selectedExpenseIndex,
                          rowCount: 2,
                          onSelected: (i) =>
                              setState(() => _selectedExpenseIndex = i),
                        ),
                        const Divider(
                          height: 30,
                          thickness: 1,
                          color: Colors.black12,
                        ),
                        CategorySelector(
                          tags: paymentTags,
                          selectedIndex: _selectedPaymentIndex,
                          rowCount: 2,
                          onSelected: (i) =>
                              setState(() => _selectedPaymentIndex = i),
                        ),
                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
                ),
                _buildActionButtons(),
              ],
            ),
            _buildMenuButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildAmountInput() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const Text(
          '¥ ',
          style: TextStyle(
            fontSize: 44,
            color: Colors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
        Expanded(
          child: TextField(
            controller: _amountController,
            focusNode: _amountFocusNode,
            autofocus: true,
            keyboardType: TextInputType.number,
            textAlign: TextAlign.right,
            style: const TextStyle(fontSize: 44, fontWeight: FontWeight.bold),
            decoration: const InputDecoration(
              hintText: '0',
              enabledBorder: UnderlineInputBorder(
                borderSide: BorderSide(color: Colors.black12, width: 2),
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Padding(
          padding: const EdgeInsets.only(top: 12),
          child: IconButton(
            onPressed: _pickDate,
            icon: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.calendar_today, size: 20, color: Colors.blue),
                const SizedBox(height: 2),
                Text(
                  "${_selectedDate.month}/${_selectedDate.day}",
                  style: const TextStyle(
                    fontSize: 11,
                    color: Colors.blue,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildActionButtons() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton(
              onPressed: () => _saveData(shouldDismissKeyboard: false),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              child: const Text('次へ'),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: ElevatedButton(
              onPressed: () => _saveData(shouldDismissKeyboard: true),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12),
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
              ),
              child: const Text('完了'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuButton() {
    return Positioned(
      top: 45,
      left: 15,
      child: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4)],
        ),
        child: IconButton(
          icon: const Icon(Icons.menu, color: Colors.blue, size: 24),
          onPressed: () => _scaffoldKey.currentState?.openDrawer(),
        ),
      ),
    );
  }
}
