import 'package:flutter/material.dart';
import '../models/category_tag.dart';
import '../models/transaction_item.dart';
import '../repositories/transaction_repository.dart';
import '../repositories/settings_repository.dart';

class MonthlyHistoryScreen extends StatefulWidget {
  const MonthlyHistoryScreen({super.key});
  @override
  State<MonthlyHistoryScreen> createState() => _MonthlyHistoryScreenState();
}

class _MonthlyHistoryScreenState extends State<MonthlyHistoryScreen> {
  final PageController _pageController = PageController(initialPage: 1000);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('月別レポート')),
      body: PageView.builder(
        controller: _pageController,
        itemBuilder: (context, index) {
          final d = DateTime(
            DateTime.now().year,
            DateTime.now().month + (index - 1000),
          );
          return MonthPage(year: d.year, month: d.month);
        },
      ),
    );
  }
}

class MonthPage extends StatefulWidget {
  final int year;
  final int month;
  const MonthPage({super.key, required this.year, required this.month});
  @override
  State<MonthPage> createState() => _MonthPageState();
}

class _MonthPageState extends State<MonthPage> {
  List<TransactionItem> _history = [];
  List<CategoryTag> _expenseList = [];
  final TransactionRepository _repository = TransactionRepository();
  final SettingsRepository _settingsRepository = SettingsRepository();

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final allItems = await _repository.getAllTransactions();
    final expenses = await _settingsRepository.loadExpenseTags();

    if (mounted) {
      setState(() {
        _history = allItems.where((i) {
          return i.date.year == widget.year && i.date.month == widget.month;
        }).toList();
        _expenseList = expenses;
      });
    }
  }

  // 編集・削除ダイアログ
  void _showEditDialog(TransactionItem item) {
    final amountController =
        TextEditingController(text: item.amount.toString());
    final memoController = TextEditingController(text: item.memo); // メモ用

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('履歴の編集'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: amountController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: '金額'),
                  autofocus: true,
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: memoController,
                  decoration: const InputDecoration(labelText: 'メモ'),
                ),
                const SizedBox(height: 20),
                Text(
                  '利用日: ${item.date.year}/${item.date.month}/${item.date.day}',
                  style: const TextStyle(color: Colors.grey, fontSize: 12),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () async {
                await _repository.deleteTransaction(item.id);
                if (context.mounted) Navigator.pop(context);
                _load();
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
                final newAmount = int.tryParse(amountController.text);
                if (newAmount != null) {
                  final newItem = item.copyWith(
                    amount: newAmount,
                    memo: memoController.text.trim(), // メモ更新
                  );
                  await _repository.updateTransaction(newItem);
                  if (context.mounted) Navigator.pop(context);
                  _load();
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
    int total = _history.fold(0, (s, i) => s + i.amount);
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(10),
          child: Text(
            "${widget.year}年 ${widget.month}月",
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
        ),
        _buildSummaryCard(total),
        Expanded(
          child: ListView.builder(
            itemCount: _history.length,
            padding: const EdgeInsets.only(bottom: 20),
            itemBuilder: (c, i) {
              final item = _history[i];
              final expenseStr =
                  item.expense == 'デフォルト' ? '' : ' (${item.expense})';

              final paymentStr = (item.payment.isEmpty ||
                      item.payment == 'デフォルト' ||
                      item.payment == '現金')
                  ? ''
                  : '${item.payment} / ';

              return ListTile(
                title: Text('¥${item.amount}$expenseStr'),
                // サブタイトルをColumnにして、メモがある場合のみ表示
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('$paymentStr${item.displayDate}'),
                    if (item.memo.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: Text(
                          item.memo,
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 12,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                  ],
                ),
                trailing: const Icon(Icons.edit, size: 16, color: Colors.grey),
                onTap: () => _showEditDialog(item),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryCard(int total) {
    final usedExpenseNames = _history.map((e) => e.expense).toSet();

    return Card(
      margin: const EdgeInsets.all(15),
      color: Colors.blue.shade50,
      child: Padding(
        padding: const EdgeInsets.all(15),
        child: Column(
          children: [
            Text(
              '¥ $total',
              style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
            ),
            const Divider(),
            Wrap(
              spacing: 10,
              children: usedExpenseNames.map((name) {
                if (name == 'デフォルト') return const SizedBox.shrink();

                int s = _history
                    .where((i) => i.expense == name)
                    .fold(0, (sum, i) => sum + i.amount);

                Color color = Colors.black;
                try {
                  color = _expenseList.firstWhere((t) => t.label == name).color;
                } catch (_) {
                  color = Colors.grey;
                }

                return s > 0
                    ? Text(
                        '$name: ¥$s',
                        style: TextStyle(
                          color: color,
                          fontWeight: FontWeight.bold,
                        ),
                      )
                    : const SizedBox.shrink();
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }
}
