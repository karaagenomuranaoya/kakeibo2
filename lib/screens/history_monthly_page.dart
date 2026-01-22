import 'package:flutter/material.dart';
import '../models/transaction_item.dart';
import '../models/category_tag.dart';
import '../services/history_service.dart';
import '../widgets/transaction_tile.dart';
import '../screens/transaction_edit_screen.dart';

// クラス名を _HistoryPage から HistoryMonthlyPage に変更し、publicにしました
class HistoryMonthlyPage extends StatefulWidget {
  final int year;
  final int month;
  final String filterValue;
  final String? filterId; // 追加
  final String filterKey;
  final Color color;
  final int viewMode;
  final VoidCallback? onPrev;
  final VoidCallback? onNext;
  final bool showNavButtons;
  final VoidCallback? onDateTap;
  final HistoryService service;

  const HistoryMonthlyPage({
    super.key,
    required this.year,
    required this.month,
    required this.filterValue,
    this.filterId, // 追加
    required this.filterKey,
    required this.color,
    required this.viewMode,
    this.onPrev,
    this.onNext,
    this.showNavButtons = true,
    this.onDateTap,
    required this.service,
  });

  @override
  State<HistoryMonthlyPage> createState() => _HistoryMonthlyPageState();
}

class _HistoryMonthlyPageState extends State<HistoryMonthlyPage> {
  List<TransactionItem> _history = [];
  List<CategoryTag> _expenseTags = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didUpdateWidget(covariant HistoryMonthlyPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.viewMode != widget.viewMode ||
        oldWidget.year != widget.year ||
        oldWidget.month != widget.month ||
        oldWidget.filterValue != widget.filterValue ||
        oldWidget.filterId != widget.filterId) {
      _load();
    }
  }

  Future<void> _load() async {
    final items = await widget.service.getFilteredTransactions(
      filterKey: widget.filterKey,
      filterValue: widget.filterValue,
      filterId: widget.filterId, // 追加
      year: widget.year,
      month: widget.month,
      viewMode: widget.viewMode,
    );

    final expenses = await widget.service.getExpenseTags();

    if (!mounted) return;

    setState(() {
      _history = items;
      _expenseTags = expenses;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    final int total = _history.fold(0, (s, i) => s + i.amount);

    // ID -> Tag, Label -> Tag のMap作成
    final idToTag = {for (var t in _expenseTags) t.id: t};
    final labelToTag = {for (var t in _expenseTags) t.label: t};

    return Column(
      children: [
        // ヘッダー部分（金額・ナビゲーション）
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 20),
          color: widget.color.withOpacity(0.1),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  if (widget.showNavButtons)
                    IconButton(
                      icon: Icon(Icons.chevron_left, color: widget.color),
                      onPressed: widget.onPrev,
                    )
                  else
                    const SizedBox(width: 48),

                  GestureDetector(
                    onTap: widget.onDateTap,
                    child: Container(
                      color: Colors.transparent,
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            '${widget.year}年 ${widget.month}月',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: widget.color,
                            ),
                          ),
                          if (widget.onDateTap != null) ...[
                            const SizedBox(width: 4),
                            Icon(
                              Icons.arrow_drop_down,
                              color: widget.color,
                              size: 20,
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                  if (widget.showNavButtons)
                    IconButton(
                      icon: Icon(Icons.chevron_right, color: widget.color),
                      onPressed: widget.onNext,
                    )
                  else
                    const SizedBox(width: 48),
                ],
              ),
              const SizedBox(height: 5),
              Text(
                widget.viewMode == 1
                    ? '引き落とし予定額'
                    : (widget.filterKey == 'expense' ? '月間支出計' : '月間利用額'),
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
              Text(
                '¥ $total',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: widget.color,
                ),
              ),
            ],
          ),
        ),
        // リスト部分
        Expanded(
          child: _history.isEmpty
              ? Center(
                  child: Text(
                    "この月の履歴はありません",
                    style: TextStyle(color: Colors.grey.shade400),
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.only(bottom: 20, top: 10),
                  itemCount: _history.length,
                  separatorBuilder: (c, i) => const Divider(height: 1),
                  itemBuilder: (c, i) {
                    final item = _history[i];
                    IconData? icon;
                    String? categoryName;

                    // ID優先で検索、なければ名前で検索
                    CategoryTag? tag;
                    if (item.expenseId != null) {
                      tag = idToTag[item.expenseId];
                    }
                    if (tag == null) {
                      tag = labelToTag[item.expense];
                    }

                    if (tag != null) {
                      icon = tag.displayIcon;
                      categoryName = tag.label;
                    }

                    return TransactionTile(
                      item: item,
                      categoryColor: widget.color,
                      categoryIcon: icon,
                      categoryName: categoryName,
                      showDate: true,
                      onTap: () async {
                        await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                TransactionEditScreen(item: item),
                          ),
                        );
                        _load();
                      },
                    );
                  },
                ),
        ),
      ],
    );
  }
}
