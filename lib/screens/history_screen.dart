import 'package:flutter/material.dart';
import '../models/transaction_item.dart';
import '../repositories/transaction_repository.dart';

class HistoryScreen extends StatefulWidget {
  final String filterValue;
  final String filterKey; // 'expense' or 'payment'
  final Color? color;

  const HistoryScreen({
    super.key,
    required this.filterValue,
    required this.filterKey,
    this.color,
  });

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  final PageController _pageController = PageController(initialPage: 1000);

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.filterValue)),
      body: PageView.builder(
        controller: _pageController,
        itemBuilder: (context, index) {
          final now = DateTime.now();
          final targetDate = DateTime(now.year, now.month + (index - 1000));

          return _MonthPage(
            year: targetDate.year,
            month: targetDate.month,
            filterValue: widget.filterValue,
            filterKey: widget.filterKey,
            color: widget.color,
            onPrev: () {
              _pageController.previousPage(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
              );
            },
            onNext: () {
              _pageController.nextPage(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
              );
            },
          );
        },
      ),
    );
  }
}

class _MonthPage extends StatefulWidget {
  final int year;
  final int month;
  final String filterValue;
  final String filterKey;
  final Color? color;
  final VoidCallback onPrev;
  final VoidCallback onNext;

  const _MonthPage({
    required this.year,
    required this.month,
    required this.filterValue,
    required this.filterKey,
    required this.color,
    required this.onPrev,
    required this.onNext,
  });

  @override
  State<_MonthPage> createState() => _MonthPageState();
}

class _MonthPageState extends State<_MonthPage> {
  List<TransactionItem> _history = [];
  final TransactionRepository _repository = TransactionRepository();
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final allItems = await _repository.getAllTransactions();
    if (!mounted) return;

    setState(() {
      _history = allItems.where((i) {
        if (i.date.year != widget.year || i.date.month != widget.month) {
          return false;
        }
        if (widget.filterKey == 'expense') {
          return i.expense == widget.filterValue;
        }
        if (widget.filterKey == 'payment') {
          if (widget.filterValue == '現金' && i.payment.isEmpty) {
            return true;
          }
          return i.payment == widget.filterValue;
        }
        return false;
      }).toList();
      _isLoading = false;
    });
  }

  // 編集・削除ダイアログ
  void _showEditDialog(TransactionItem item) {
    final amountController =
        TextEditingController(text: item.amount.toString());

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('履歴の編集'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: amountController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: '金額'),
                autofocus: true,
              ),
              const SizedBox(height: 20),
              Text(
                '${item.date.year}/${item.date.month}/${item.date.day} の記録',
                style: const TextStyle(color: Colors.grey, fontSize: 12),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () async {
                // 削除処理
                await _repository.deleteTransaction(item.id);
                if (context.mounted) Navigator.pop(context);
                _load(); // 再読み込み
              },
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('削除'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('キャンセル'),
            ),
            ElevatedButton(
              onPressed: () async {
                // 更新処理
                final newAmount = int.tryParse(amountController.text);
                if (newAmount != null) {
                  final newItem = item.copyWith(amount: newAmount);
                  await _repository.updateTransaction(newItem);
                  if (context.mounted) Navigator.pop(context);
                  _load(); // 再読み込み
                }
              },
              child: const Text('更新'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    int total = _history.fold(0, (s, i) => s + i.amount);
    final bgColor = widget.color?.withOpacity(0.1) ?? Colors.blue.shade50;
    final fgColor = widget.color ?? Colors.black;

    return Column(
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 20),
          color: bgColor,
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: Icon(Icons.chevron_left, color: fgColor),
                    onPressed: widget.onPrev,
                  ),
                  Text(
                    '${widget.year}年 ${widget.month}月',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: fgColor,
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.chevron_right, color: fgColor),
                    onPressed: widget.onNext,
                  ),
                ],
              ),
              const SizedBox(height: 5),
              Text(
                widget.filterKey == 'expense' ? '月間支出計' : '月間利用額',
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
              Text(
                '¥ $total',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: fgColor,
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: _history.isEmpty
              ? Center(
                  child: Text(
                    "この月の履歴はありません",
                    style: TextStyle(color: Colors.grey.shade400),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.only(bottom: 20),
                  itemCount: _history.length,
                  itemBuilder: (c, i) {
                    final item = _history[i];
                    String detail = "";
                    if (widget.filterKey == 'expense') {
                      if (item.payment.isNotEmpty &&
                          item.payment != 'デフォルト' &&
                          item.payment != '現金') {
                        detail = "  /  ${item.payment}";
                      }
                    } else {
                      if (item.expense != 'デフォルト') {
                        detail = "  /  ${item.expense}";
                      }
                    }

                    return ListTile(
                      leading: Icon(
                        widget.filterKey == 'payment'
                            ? Icons.payment
                            : Icons.label,
                        color: widget.color,
                      ),
                      title: Text(
                        '¥${item.amount}',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Text("${item.displayDate}$detail"),
                      // タップで編集ダイアログを表示
                      onTap: () => _showEditDialog(item),
                      trailing:
                          const Icon(Icons.edit, size: 16, color: Colors.grey),
                    );
                  },
                ),
        ),
      ],
    );
  }
}
