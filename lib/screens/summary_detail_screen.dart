import 'package:flutter/material.dart';
import '../models/category_tag.dart';
import '../models/transaction_item.dart';
import '../repositories/transaction_repository.dart';
import '../repositories/settings_repository.dart';
import 'history_screen.dart';

class SummaryDetailScreen extends StatefulWidget {
  final int year;
  final int month;

  const SummaryDetailScreen({
    super.key,
    required this.year,
    required this.month,
  });

  @override
  State<SummaryDetailScreen> createState() => _SummaryDetailScreenState();
}

class _SummaryDetailScreenState extends State<SummaryDetailScreen> {
  final TransactionRepository _repository = TransactionRepository();
  final SettingsRepository _settingsRepository = SettingsRepository();

  List<TransactionItem> _history = [];
  List<CategoryTag> _expenseList = [];
  bool _isLoading = true;

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
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final int total = _history.fold(0, (s, i) => s + i.amount);

    // 費目ごとの集計
    final expenseSums = <String, int>{};
    for (var item in _history) {
      expenseSums[item.expense] =
          (expenseSums[item.expense] ?? 0) + item.amount;
    }

    // 金額が大きい順にソート
    final sortedEntries = expenseSums.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return Scaffold(
      appBar: AppBar(title: Text('${widget.year}年${widget.month}月 内訳詳細')),
      body: Column(
        children: [
          // 合計カード
          Container(
            width: double.infinity,
            color: Colors.blue.shade50,
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                const Text(
                  '合計支出',
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
                Text(
                  '¥ $total',
                  style: const TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          // 内訳リスト
          Expanded(
            child: sortedEntries.isEmpty
                ? Center(
                    child: Text(
                      'データがありません',
                      style: TextStyle(color: Colors.grey.shade400),
                    ),
                  )
                : ListView.separated(
                    itemCount: sortedEntries.length,
                    separatorBuilder: (c, i) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final entry = sortedEntries[index];
                      final label = entry.key;
                      final amount = entry.value;

                      Color color = Colors.grey;
                      try {
                        color = _expenseList
                            .firstWhere((t) => t.label == label)
                            .color;
                      } catch (_) {}

                      final percentage = (total > 0)
                          ? (amount / total * 100).toStringAsFixed(1)
                          : "0.0";

                      return ListTile(
                        leading: Container(
                          width: 20,
                          height: 20,
                          decoration: BoxDecoration(
                            color: color,
                            shape: BoxShape.circle,
                          ),
                        ),
                        title: Row(
                          children: [
                            Expanded(child: Text(label)),
                            Text(
                              '¥$amount',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        subtitle: LinearProgressIndicator(
                          value: total > 0 ? amount / total : 0,
                          backgroundColor: Colors.grey.shade100,
                          color: color,
                          minHeight: 4,
                          borderRadius: BorderRadius.circular(2),
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              '$percentage%',
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.grey,
                              ),
                            ),
                            const SizedBox(width: 5),
                            const Icon(
                              Icons.chevron_right,
                              size: 16,
                              color: Colors.grey,
                            ),
                          ],
                        ),
                        onTap: () {
                          // その月のその費目の履歴へ遷移
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => HistoryScreen(
                                filterValue: label,
                                filterKey: 'expense',
                                color: color,
                                year: widget.year,
                                month: widget.month,
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
