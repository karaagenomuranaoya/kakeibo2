import 'package:flutter/material.dart';
import '../models/transaction_item.dart';
import '../models/category_tag.dart';
import '../services/history_service.dart'; // New!
import '../widgets/transaction_tile.dart';
import '../widgets/card_settings_dialog.dart';
import '../widgets/transaction_edit_dialog.dart';

class HistoryScreen extends StatefulWidget {
  final String filterValue;
  final String filterKey; // 'expense' or 'payment'
  final Color? color;
  final int? year; // 互換性のため残存
  final int? month;
  final DateTime? initialDate;

  const HistoryScreen({
    super.key,
    required this.filterValue,
    required this.filterKey,
    this.color,
    this.year,
    this.month,
    this.initialDate,
  });

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  int _viewMode = 0;
  bool _showTab = false;
  CategoryTag? _currentCardTag;

  late PageController _pageController;
  final HistoryService _historyService = HistoryService(); // Serviceを使用

  @override
  void initState() {
    super.initState();

    int initialPage = 1000;
    if (widget.initialDate != null) {
      final now = DateTime.now();
      final diff =
          (widget.initialDate!.year - now.year) * 12 +
          (widget.initialDate!.month - now.month);
      initialPage = 1000 + diff;
    }

    _pageController = PageController(initialPage: initialPage);

    if (widget.filterKey == 'payment' && widget.filterValue != '現金') {
      _loadCardInfo();
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _loadCardInfo() async {
    final card = await _historyService.getCardTagByLabel(widget.filterValue);
    if (card != null && mounted) {
      setState(() {
        _currentCardTag = card;
        _showTab = card.closingDay != null;
        if (!_showTab) _viewMode = 0;
      });
    }
  }

  void _showSetupDialog() {
    if (_currentCardTag == null) return;

    showDialog(
      context: context,
      builder: (context) => CardSettingsDialog(
        currentTag: _currentCardTag!,
        onSave: (closing, payment, offset) async {
          final newTag = CategoryTag(
            id: _currentCardTag!.id,
            label: _currentCardTag!.label,
            color: _currentCardTag!.color,
            isCircle: _currentCardTag!.isCircle,
            closingDay: closing,
            paymentDay: payment,
            paymentMonthOffset: offset,
          );

          await _historyService.updateCardTag(newTag);

          if (mounted) {
            setState(() {
              _currentCardTag = newTag;
              _showTab = newTag.closingDay != null;
              if (!_showTab) _viewMode = 0;
            });
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(const SnackBar(content: Text('設定を保存しました')));
          }
        },
      ),
    );
  }

  void _jumpToDate(DateTime date) {
    final DateTime now = DateTime.now();
    final int diffMonths =
        (date.year - now.year) * 12 + (date.month - now.month);
    final int targetPage = 1000 + diffMonths;
    _pageController.jumpToPage(targetPage);
  }

  @override
  Widget build(BuildContext context) {
    String title = widget.filterValue;
    if (widget.year != null && widget.month != null) {
      title = "${widget.year}/${widget.month} $title";
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        actions: [
          if (_currentCardTag != null)
            IconButton(
              icon: const Icon(Icons.settings_outlined),
              tooltip: 'カード設定',
              onPressed: _showSetupDialog,
            ),
        ],
      ),
      body: Column(
        children: [
          if (_showTab)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: SegmentedButton<int>(
                segments: const [
                  ButtonSegment(
                    value: 0,
                    label: Text('利用履歴'),
                    icon: Icon(Icons.shopping_bag_outlined),
                  ),
                  ButtonSegment(
                    value: 1,
                    label: Text('引き落とし予定'),
                    icon: Icon(Icons.account_balance_wallet_outlined),
                  ),
                ],
                selected: {_viewMode},
                onSelectionChanged: (newSelection) {
                  setState(() => _viewMode = newSelection.first);
                },
                style: ButtonStyle(
                  visualDensity: VisualDensity.compact,
                  backgroundColor: MaterialStateProperty.resolveWith((states) {
                    if (states.contains(MaterialState.selected)) {
                      return widget.color?.withOpacity(0.2) ??
                          Colors.blue.shade100;
                    }
                    return null;
                  }),
                ),
              ),
            ),
          Expanded(
            child: (widget.year != null && widget.month != null)
                ? _HistoryPage(
                    year: widget.year!,
                    month: widget.month!,
                    filterValue: widget.filterValue,
                    filterKey: widget.filterKey,
                    color: widget.color ?? Colors.blue,
                    viewMode: _viewMode,
                    showNavButtons: false,
                    service: _historyService, // Serviceを渡す
                  )
                : PageView.builder(
                    controller: _pageController,
                    itemBuilder: (context, index) {
                      final now = DateTime.now();
                      final targetDate = DateTime(
                        now.year,
                        now.month + (index - 1000),
                      );
                      return _HistoryPage(
                        year: targetDate.year,
                        month: targetDate.month,
                        filterValue: widget.filterValue,
                        filterKey: widget.filterKey,
                        color: widget.color ?? Colors.blue,
                        viewMode: _viewMode,
                        onPrev: () => _pageController.previousPage(
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeInOut,
                        ),
                        onNext: () => _pageController.nextPage(
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeInOut,
                        ),
                        onDateTap: () async {
                          final DateTime current = DateTime(
                            targetDate.year,
                            targetDate.month,
                          );
                          final DateTime? picked = await showDatePicker(
                            context: context,
                            initialDate: current,
                            firstDate: DateTime(2000),
                            lastDate: DateTime(2101),
                            initialDatePickerMode: DatePickerMode.year,
                            helpText: '移動先の年月を選択',
                          );
                          if (picked != null) {
                            _jumpToDate(picked);
                          }
                        },
                        service: _historyService, // Serviceを渡す
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class _HistoryPage extends StatefulWidget {
  final int year;
  final int month;
  final String filterValue;
  final String filterKey;
  final Color color;
  final int viewMode;
  final VoidCallback? onPrev;
  final VoidCallback? onNext;
  final bool showNavButtons;
  final VoidCallback? onDateTap;
  final HistoryService service; // 追加

  const _HistoryPage({
    required this.year,
    required this.month,
    required this.filterValue,
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
  State<_HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends State<_HistoryPage> {
  List<TransactionItem> _history = [];
  List<CategoryTag> _expenseTags = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didUpdateWidget(covariant _HistoryPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.viewMode != widget.viewMode ||
        oldWidget.year != widget.year ||
        oldWidget.month != widget.month) {
      _load();
    }
  }

  Future<void> _load() async {
    // Serviceを使ってデータを取得（スッキリ！）
    final items = await widget.service.getFilteredTransactions(
      filterKey: widget.filterKey,
      filterValue: widget.filterValue,
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

    return Column(
      children: [
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
                    try {
                      final tag = _expenseTags.firstWhere(
                        (t) => t.label == item.expense,
                      );
                      icon = tag.displayIcon;
                    } catch (_) {}

                    return TransactionTile(
                      item: item,
                      categoryColor: widget.color,
                      categoryIcon: icon,
                      showDate: true,
                      onTap: () {
                        showDialog(
                          context: context,
                          builder: (context) => TransactionEditDialog(
                            item: item,
                            onSuccess: () {
                              _load();
                            },
                          ),
                        );
                      },
                    );
                  },
                ),
        ),
      ],
    );
  }
}
