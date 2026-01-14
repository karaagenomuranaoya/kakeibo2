import 'package:flutter/material.dart';
import '../models/transaction_item.dart';
import '../models/category_tag.dart';
import '../repositories/transaction_repository.dart';
import '../repositories/settings_repository.dart';

class HistoryScreen extends StatefulWidget {
  final String filterValue;
  final String filterKey; // 'expense' or 'payment'
  final Color? color;
  final int? year; // 追加: 年フィルタ (nullなら全期間)
  final int? month; // 追加: 月フィルタ

  const HistoryScreen({
    super.key,
    required this.filterValue,
    required this.filterKey,
    this.color,
    this.year,
    this.month,
  });

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  // 0: 利用日基準, 1: 支払日基準
  int _viewMode = 0;

  // タブを表示するかどうか
  bool _showTab = false;

  // 現在表示中のカード情報
  CategoryTag? _currentCardTag;
  bool _isCardType = false;

  final PageController _pageController = PageController(initialPage: 1000);
  final SettingsRepository _settingsRepository = SettingsRepository();

  @override
  void initState() {
    super.initState();
    if (widget.filterKey == 'payment' && widget.filterValue != '現金') {
      _isCardType = true;
    }
    _loadCardInfo();
  }

  Future<void> _loadCardInfo() async {
    if (_isCardType) {
      final cards = await _settingsRepository.loadCardTags();
      try {
        final card = cards.firstWhere((c) => c.label == widget.filterValue);
        if (mounted) {
          setState(() {
            _currentCardTag = card;
            _showTab = card.closingDay != null;
            if (!_showTab) {
              _viewMode = 0;
            }
          });
        }
      } catch (_) {}
    }
  }

  void _showSetupDialog() {
    // カード設定ダイアログ（省略せず実装）
    bool isEnabled = _currentCardTag?.closingDay != null;
    int closingDay = _currentCardTag?.closingDay ?? 99;
    int paymentDay = _currentCardTag?.paymentDay ?? 27;
    int paymentOffset = _currentCardTag?.paymentMonthOffset ?? 1;

    List<DropdownMenuItem<int>> getDayItems() {
      final items = List.generate(
        28,
        (i) => i + 1,
      ).map((i) => DropdownMenuItem(value: i, child: Text('$i日'))).toList();
      items.add(const DropdownMenuItem(value: 99, child: Text('末日')));
      return items;
    }

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              title: const Text('カード設定'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Expanded(child: Text('締め日・支払日を管理する')),
                      Switch(
                        value: isEnabled,
                        onChanged: (val) =>
                            setStateDialog(() => isEnabled = val),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  if (isEnabled) ...[
                    const Text(
                      '締め日と支払日を設定すると、\n「引き落とし予定」タブが表示されます。',
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                    const SizedBox(height: 15),
                    Row(
                      children: [
                        const Text('締め: '),
                        DropdownButton<int>(
                          value: closingDay,
                          items: getDayItems(),
                          onChanged: (val) =>
                              setStateDialog(() => closingDay = val!),
                        ),
                        const SizedBox(width: 15),
                        const Text('払い: '),
                        DropdownButton<int>(
                          value: paymentDay,
                          items: getDayItems(),
                          onChanged: (val) =>
                              setStateDialog(() => paymentDay = val!),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        const Text('支払月: '),
                        DropdownButton<int>(
                          value: paymentOffset,
                          items: const [
                            DropdownMenuItem(value: 1, child: Text('翌月')),
                            DropdownMenuItem(value: 2, child: Text('翌々月')),
                          ],
                          onChanged: (val) =>
                              setStateDialog(() => paymentOffset = val!),
                        ),
                      ],
                    ),
                  ] else ...[
                    const Text(
                      'PayPayやデビットカードなど、\n即時決済の場合はオフにしてください。',
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ],
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('キャンセル'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    await _saveCardSettings(
                      isEnabled ? closingDay : null,
                      isEnabled ? paymentDay : null,
                      paymentOffset,
                    );
                    if (context.mounted) {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(isEnabled ? '設定を保存しました' : '設定を解除しました'),
                        ),
                      );
                    }
                  },
                  child: const Text('保存'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _saveCardSettings(int? closing, int? payment, int offset) async {
    if (_currentCardTag == null) return;
    final cards = await _settingsRepository.loadCardTags();
    final index = cards.indexWhere((c) => c.id == _currentCardTag!.id);

    if (index != -1) {
      final newTag = CategoryTag(
        id: _currentCardTag!.id,
        label: _currentCardTag!.label,
        color: _currentCardTag!.color,
        isCircle: _currentCardTag!.isCircle,
        closingDay: closing,
        paymentDay: payment,
        paymentMonthOffset: offset,
      );

      cards[index] = newTag;
      await _settingsRepository.saveCardTags(cards);

      setState(() {
        _currentCardTag = newTag;
        _showTab = newTag.closingDay != null;
        if (!_showTab) _viewMode = 0;
      });
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // 年月指定がある場合、タイトルに年月を表示
    String title = widget.filterValue;
    if (widget.year != null && widget.month != null) {
      title = "${widget.year}/${widget.month} $title";
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        actions: [
          if (_isCardType)
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
                  setState(() {
                    _viewMode = newSelection.first;
                  });
                },
                style: ButtonStyle(
                  visualDensity: VisualDensity.compact,
                  backgroundColor: MaterialStateProperty.resolveWith<Color?>((
                    Set<MaterialState> states,
                  ) {
                    if (states.contains(MaterialState.selected)) {
                      return widget.color?.withOpacity(0.2) ??
                          Colors.blue.shade100;
                    }
                    return null;
                  }),
                ),
              ),
            ),
          // 年月指定がある場合はPageViewを使わず単一ページ表示
          // 年月指定がない場合（全期間モード）はPageViewで月送り可能にする
          Expanded(
            child: (widget.year != null && widget.month != null)
                ? _MonthPage(
                    year: widget.year!,
                    month: widget.month!,
                    filterValue: widget.filterValue,
                    filterKey: widget.filterKey,
                    color: widget.color,
                    viewMode: _viewMode,
                    // 年月固定時は前次ボタン不要
                    onPrev: () {},
                    onNext: () {},
                    showNavButtons: false,
                  )
                : PageView.builder(
                    controller: _pageController,
                    itemBuilder: (context, index) {
                      final now = DateTime.now();
                      final targetDate = DateTime(
                        now.year,
                        now.month + (index - 1000),
                      );

                      return _MonthPage(
                        year: targetDate.year,
                        month: targetDate.month,
                        filterValue: widget.filterValue,
                        filterKey: widget.filterKey,
                        color: widget.color,
                        viewMode: _viewMode,
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
                        showNavButtons: true,
                      );
                    },
                  ),
          ),
        ],
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
  final int viewMode;
  final VoidCallback onPrev;
  final VoidCallback onNext;
  final bool showNavButtons;

  const _MonthPage({
    required this.year,
    required this.month,
    required this.filterValue,
    required this.filterKey,
    required this.color,
    required this.viewMode,
    required this.onPrev,
    required this.onNext,
    this.showNavButtons = true,
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

  @override
  void didUpdateWidget(covariant _MonthPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.viewMode != widget.viewMode ||
        oldWidget.year != widget.year ||
        oldWidget.month != widget.month) {
      _load();
    }
  }

  Future<void> _load() async {
    final allItems = await _repository.getAllTransactions();
    if (!mounted) return;

    setState(() {
      _history = allItems.where((i) {
        bool isTarget = false;
        if (widget.filterKey == 'expense') {
          isTarget = i.expense == widget.filterValue;
        } else if (widget.filterKey == 'payment') {
          if (widget.filterValue == '現金' && i.payment.isEmpty) {
            isTarget = true;
          } else {
            isTarget = i.payment == widget.filterValue;
          }
        }
        if (!isTarget) return false;

        if (widget.viewMode == 1) {
          final targetDate = i.paymentDate ?? i.date;
          return targetDate.year == widget.year &&
              targetDate.month == widget.month;
        } else {
          return i.date.year == widget.year && i.date.month == widget.month;
        }
      }).toList();
      // 日付順ソート
      _history.sort((a, b) => b.date.compareTo(a.date));
      _isLoading = false;
    });
  }

  void _showEditDialog(TransactionItem item) {
    // 編集ダイアログ（既存と同じロジック）
    final amountController = TextEditingController(
      text: item.amount.toString(),
    );
    final memoController = TextEditingController(text: item.memo);

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
                if (item.paymentDate != null)
                  Text(
                    '支払日: ${item.paymentDate!.year}/${item.paymentDate!.month}/${item.paymentDate!.day}',
                    style: const TextStyle(
                      color: Colors.orange,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
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
                    memo: memoController.text.trim(),
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
                  if (widget.showNavButtons)
                    IconButton(
                      icon: Icon(Icons.chevron_left, color: fgColor),
                      onPressed: widget.onPrev,
                    )
                  else
                    const SizedBox(width: 48),
                  Text(
                    '${widget.year}年 ${widget.month}月',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: fgColor,
                    ),
                  ),
                  if (widget.showNavButtons)
                    IconButton(
                      icon: Icon(Icons.chevron_right, color: fgColor),
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

                    String dateInfo = item.displayDate;
                    if (widget.viewMode == 1) {
                      if (item.paymentDate != null) {
                        dateInfo = "利用: ${item.date.month}/${item.date.day}";
                      } else {
                        dateInfo =
                            "利用: ${item.date.month}/${item.date.day} (未確定)";
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
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text("$dateInfo$detail"),
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
                      onTap: () => _showEditDialog(item),
                      trailing: const Icon(
                        Icons.edit,
                        size: 16,
                        color: Colors.grey,
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
}
