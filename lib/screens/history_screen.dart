import 'package:flutter/material.dart';
import '../models/transaction_item.dart';
import '../models/category_tag.dart';
import '../repositories/transaction_repository.dart';
import '../repositories/settings_repository.dart';

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
  // 0: 利用日基準, 1: 支払日基準
  int _viewMode = 0;

  // 現在表示中のカード情報（設定取得用）
  CategoryTag? _currentCardTag;

  // 現金以外の支払い方法かどうか
  bool _isCardType = false;

  final PageController _pageController = PageController(initialPage: 1000);
  final SettingsRepository _settingsRepository = SettingsRepository();

  @override
  void initState() {
    super.initState();

    // ▼▼ 修正: データ読み込みを待たずに、条件だけで即座にフラグを立てる ▼▼
    if (widget.filterKey == 'payment' && widget.filterValue != '現金') {
      _isCardType = true;
    }

    // その後、詳細な設定（締め日など）を裏で読み込む
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
          });
        }
      } catch (_) {
        // タグが見つからない場合でも、_isCardTypeはtrueのままでOK
      }
    }
  }

  void _onTabChanged(int newValue) {
    if (newValue == 1) {
      // 「引き落とし予定」が選ばれた時、設定（締め日）がなければダイアログを出す
      // _currentCardTagがまだロードできていない場合も考慮してnullチェック
      if (_currentCardTag == null || _currentCardTag!.closingDay == null) {
        _showSetupDialog();
        return;
      }
    }

    setState(() {
      _viewMode = newValue;
    });
  }

  void _showSetupDialog() {
    int closingDay = 99; // デフォルト末日
    int paymentDay = 27; // デフォルト27日
    int paymentOffset = 1; // デフォルト翌月

    List<DropdownMenuItem<int>> getDayItems() {
      final items = List.generate(28, (i) => i + 1)
          .map((i) => DropdownMenuItem(value: i, child: Text('$i日')))
          .toList();
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
                  const Text('引き落とし予定を計算するために、\n締め日と支払日を教えてください。'),
                  const SizedBox(height: 20),
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
                        closingDay, paymentDay, paymentOffset);
                    if (context.mounted) {
                      Navigator.pop(context);
                      setState(() {
                        _viewMode = 1;
                      });
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content: Text('設定を保存しました。次回入力分から支払日が自動計算されます。')),
                      );
                    }
                  },
                  child: const Text('保存して表示'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _saveCardSettings(int closing, int payment, int offset) async {
    // タグ情報がまだロードされていない場合は何もしない（あるいはリロードする）
    // 通常はダイアログが出る時点でロードされているはず
    if (_currentCardTag == null) {
      // 万が一nullなら、名前から検索して再取得を試みるなどの処理が必要だが
      // ここでは簡易的にロード待ちをするか、エラーにする
      await _loadCardInfo();
      if (_currentCardTag == null) return;
    }

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
    return Scaffold(
      appBar: AppBar(title: Text(widget.filterValue)),
      body: Column(
        children: [
          // _isCardTypeがtrueなら即座に表示（ロード待ちしない）
          if (_isCardType)
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
                onSelectionChanged: (newSelection) =>
                    _onTabChanged(newSelection.first),
                style: ButtonStyle(
                  visualDensity: VisualDensity.compact,
                  backgroundColor: MaterialStateProperty.resolveWith<Color?>(
                    (Set<MaterialState> states) {
                      if (states.contains(MaterialState.selected)) {
                        return widget.color?.withOpacity(0.2) ??
                            Colors.blue.shade100;
                      }
                      return null;
                    },
                  ),
                ),
              ),
            ),

          Expanded(
            child: PageView.builder(
              controller: _pageController,
              itemBuilder: (context, index) {
                final now = DateTime.now();
                final targetDate =
                    DateTime(now.year, now.month + (index - 1000));

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
  final int viewMode; // 0:利用日, 1:支払日
  final VoidCallback onPrev;
  final VoidCallback onNext;

  const _MonthPage({
    required this.year,
    required this.month,
    required this.filterValue,
    required this.filterKey,
    required this.color,
    required this.viewMode,
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

  @override
  void didUpdateWidget(covariant _MonthPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.viewMode != widget.viewMode) {
      _load();
    }
  }

  Future<void> _load() async {
    final allItems = await _repository.getAllTransactions();
    if (!mounted) return;

    setState(() {
      _history = allItems.where((i) {
        // 1. タグフィルタ
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

        // 2. 年月フィルタ
        if (widget.viewMode == 1) {
          // 支払日基準
          final targetDate = i.paymentDate ?? i.date;
          return targetDate.year == widget.year &&
              targetDate.month == widget.month;
        } else {
          // 利用日基準
          return i.date.year == widget.year && i.date.month == widget.month;
        }
      }).toList();
      _isLoading = false;
    });
  }

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
                '利用日: ${item.date.year}/${item.date.month}/${item.date.day}',
                style: const TextStyle(color: Colors.grey, fontSize: 12),
              ),
              if (item.paymentDate != null)
                Text(
                  '支払日: ${item.paymentDate!.year}/${item.paymentDate!.month}/${item.paymentDate!.day}',
                  style: const TextStyle(
                      color: Colors.orange,
                      fontSize: 12,
                      fontWeight: FontWeight.bold),
                ),
            ],
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
                  final newItem = item.copyWith(amount: newAmount);
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
                      subtitle: Text("$dateInfo$detail"),
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
