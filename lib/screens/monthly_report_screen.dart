import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart'; // グラフ用
import '../models/category_tag.dart';
import '../models/transaction_item.dart';
import '../repositories/transaction_repository.dart';
import '../repositories/settings_repository.dart';
import 'summary_detail_screen.dart'; // 詳細画面

class MonthlyHistoryScreen extends StatefulWidget {
  const MonthlyHistoryScreen({super.key});
  @override
  State<MonthlyHistoryScreen> createState() => _MonthlyHistoryScreenState();
}

class _MonthlyHistoryScreenState extends State<MonthlyHistoryScreen>
    with SingleTickerProviderStateMixin {
  final PageController _pageController = PageController(initialPage: 1000);
  late TabController _tabController;

  // AppBarに表示するための現在の年月
  late int _currentYear;
  late int _currentMonth;

  // 現在のタブインデックス (0:カレンダー, 1:グラフ)
  int _currentTabIndex = 0;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _currentYear = now.year;
    _currentMonth = now.month;

    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      if (_tabController.indexIsChanging) {
        setState(() {
          _currentTabIndex = _tabController.index;
        });
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  // ページ切り替え時にAppBarのタイトルを更新
  void _onPageChanged(int index) {
    final d = DateTime(
      DateTime.now().year,
      DateTime.now().month + (index - 1000),
    );
    setState(() {
      _currentYear = d.year;
      _currentMonth = d.month;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: Text(
          '$_currentYear年 $_currentMonth月',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'カレンダー', icon: Icon(Icons.calendar_month)),
            Tab(text: '円グラフ', icon: Icon(Icons.pie_chart)),
          ],
        ),
      ),
      body: PageView.builder(
        controller: _pageController,
        onPageChanged: _onPageChanged,
        itemBuilder: (context, index) {
          final d = DateTime(
            DateTime.now().year,
            DateTime.now().month + (index - 1000),
          );
          return MonthPage(
            year: d.year,
            month: d.month,
            tabIndex: _currentTabIndex,
          );
        },
      ),
    );
  }
}

class MonthPage extends StatefulWidget {
  final int year;
  final int month;
  final int tabIndex; // 0: カレンダー, 1: グラフ

  const MonthPage({
    super.key,
    required this.year,
    required this.month,
    required this.tabIndex,
  });

  @override
  State<MonthPage> createState() => _MonthPageState();
}

class _MonthPageState extends State<MonthPage> {
  List<TransactionItem> _history = [];
  List<CategoryTag> _expenseList = [];
  final TransactionRepository _repository = TransactionRepository();
  final SettingsRepository _settingsRepository = SettingsRepository();

  // 日付ごとのスクロール位置を特定するためのキー
  final Map<int, GlobalKey> _dayKeys = {};

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
        // 対象月でフィルタリングし、日付の新しい順にソート
        _history = allItems.where((i) {
          return i.date.year == widget.year && i.date.month == widget.month;
        }).toList();
        _history.sort((a, b) => b.date.compareTo(a.date));

        _expenseList = expenses;
      });
    }
  }

  void _scrollToDate(int day) {
    final key = _dayKeys[day];
    if (key != null && key.currentContext != null) {
      Scrollable.ensureVisible(
        key.currentContext!,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
        alignment: 0.0,
      );
    }
  }

  // 編集・削除ダイアログ
  void _showEditDialog(TransactionItem item) {
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
    int total = _history.fold(0, (s, i) => s + i.amount);

    return SingleChildScrollView(
      padding: const EdgeInsets.only(bottom: 50),
      child: Column(
        children: [
          // 共通: 合計カード（タップで詳細へ）
          _buildTotalCard(total),

          // タブによって表示を切り替え
          // アニメーション付きで切り替えるとリッチに見える
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            child: widget.tabIndex == 0
                ? _buildCalendarView()
                : _buildGraphView(),
          ),

          const Divider(height: 1),

          // 共通: 日別トランザクションリスト
          // 「どちらのタブでも下には同じように履歴が並んでいる」という要望に対応
          _buildTransactionList(),
        ],
      ),
    );
  }

  Widget _buildTotalCard(int total) {
    return Material(
      color: Colors.blue.shade50,
      child: InkWell(
        onTap: () {
          // 合計タップで詳細画面へ遷移
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) =>
                  SummaryDetailScreen(year: widget.year, month: widget.month),
            ),
          );
        },
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 20),
          child: Stack(
            children: [
              Center(
                child: Column(
                  children: [
                    const Text(
                      '合計支出',
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '¥ $total',
                          style: const TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                        const Padding(
                          padding: EdgeInsets.only(bottom: 6, left: 5),
                          child: Icon(
                            Icons.arrow_forward_ios,
                            size: 14,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                    const Text(
                      'タップして詳細を見る',
                      style: TextStyle(fontSize: 10, color: Colors.blueGrey),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // --- カレンダー表示 ---
  Widget _buildCalendarView() {
    final daysInMonth = DateTime(widget.year, widget.month + 1, 0).day;
    final firstWeekday = DateTime(widget.year, widget.month, 1).weekday;
    final int emptyCount = (firstWeekday == 7) ? 0 : firstWeekday;
    final hasDataDays = _history.map((e) => e.date.day).toSet();

    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: const [
              Text('日', style: TextStyle(color: Colors.red, fontSize: 12)),
              Text('月', style: TextStyle(color: Colors.black, fontSize: 12)),
              Text('火', style: TextStyle(color: Colors.black, fontSize: 12)),
              Text('水', style: TextStyle(color: Colors.black, fontSize: 12)),
              Text('木', style: TextStyle(color: Colors.black, fontSize: 12)),
              Text('金', style: TextStyle(color: Colors.black, fontSize: 12)),
              Text('土', style: TextStyle(color: Colors.blue, fontSize: 12)),
            ],
          ),
          const SizedBox(height: 5),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: emptyCount + daysInMonth,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              childAspectRatio: 1.2,
            ),
            itemBuilder: (context, index) {
              if (index < emptyCount) {
                return const SizedBox.shrink();
              }
              final day = index - emptyCount + 1;
              final hasData = hasDataDays.contains(day);

              return GestureDetector(
                onTap: hasData ? () => _scrollToDate(day) : null,
                child: Container(
                  margin: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    color: hasData ? Colors.orange.shade50 : Colors.transparent,
                    borderRadius: BorderRadius.circular(8),
                    border: hasData
                        ? Border.all(color: Colors.orange.shade200)
                        : null,
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        '$day',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: hasData
                              ? FontWeight.bold
                              : FontWeight.normal,
                          color: hasData ? Colors.black87 : Colors.grey,
                        ),
                      ),
                      if (hasData)
                        Container(
                          margin: const EdgeInsets.only(top: 2),
                          width: 4,
                          height: 4,
                          decoration: const BoxDecoration(
                            color: Colors.orange,
                            shape: BoxShape.circle,
                          ),
                        ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  // --- グラフ表示 ---
  Widget _buildGraphView() {
    int total = _history.fold(0, (s, i) => s + i.amount);

    // 費目ごとの集計
    final expenseSums = <String, int>{};
    for (var item in _history) {
      expenseSums[item.expense] =
          (expenseSums[item.expense] ?? 0) + item.amount;
    }
    final sortedEntries = expenseSums.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    List<PieChartSectionData> sections = [];
    if (total > 0) {
      sections = sortedEntries.map((e) {
        final percentage = (e.value / total) * 100;
        Color color = Colors.grey;
        try {
          color = _expenseList.firstWhere((t) => t.label == e.key).color;
        } catch (_) {}
        return PieChartSectionData(
          color: color,
          value: e.value.toDouble(),
          title: '${percentage.toStringAsFixed(0)}%',
          radius: 50,
          titleStyle: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        );
      }).toList();
    } else {
      sections = [
        PieChartSectionData(
          color: Colors.grey.shade200,
          value: 1,
          title: '',
          radius: 50,
        ),
      ];
    }

    return Container(
      width: double.infinity,
      color: Colors.white,
      padding: const EdgeInsets.symmetric(vertical: 20),
      // カレンダーと高さを近づけると切り替え時のガタつきが減る
      constraints: const BoxConstraints(minHeight: 300),
      child: Column(
        children: [
          SizedBox(
            height: 200,
            child: PieChart(
              PieChartData(
                sections: sections,
                centerSpaceRadius: 40,
                sectionsSpace: 2,
                borderData: FlBorderData(show: false),
              ),
            ),
          ),
          const SizedBox(height: 10),
          const Text(
            "※費目ごとの詳細は合計金額をタップ",
            style: TextStyle(fontSize: 11, color: Colors.grey),
          ),
        ],
      ),
    );
  }

  // --- トランザクションリスト ---
  Widget _buildTransactionList() {
    if (_history.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(30),
        child: Text('データがありません', style: TextStyle(color: Colors.grey)),
      );
    }

    final grouped = <int, List<TransactionItem>>{};
    for (var item in _history) {
      if (!grouped.containsKey(item.date.day)) {
        grouped[item.date.day] = [];
      }
      grouped[item.date.day]!.add(item);
    }

    final sortedDays = grouped.keys.toList()..sort((a, b) => b.compareTo(a));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: sortedDays.map((day) {
        final items = grouped[day]!;
        if (!_dayKeys.containsKey(day)) {
          _dayKeys[day] = GlobalKey();
        }

        final dayTotal = items.fold(0, (sum, i) => sum + i.amount);
        final dateObj = items.first.date;
        const weekDays = ["月", "火", "水", "木", "金", "土", "日"];
        final weekStr = weekDays[dateObj.weekday - 1];

        return Container(
          key: _dayKeys[day],
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                color: Colors.grey.shade100,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${dateObj.month}/$day ($weekStr)',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.black54,
                      ),
                    ),
                    Text(
                      '¥$dayTotal',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                  ],
                ),
              ),
              ...items.map((item) {
                final paymentStr =
                    (item.payment.isEmpty ||
                        item.payment == 'デフォルト' ||
                        item.payment == '現金')
                    ? ''
                    : '${item.payment}';

                return ListTile(
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 0,
                  ),
                  dense: true,
                  leading: _buildCategoryIcon(item.expense),
                  title: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        item.expense,
                        style: const TextStyle(fontWeight: FontWeight.w500),
                      ),
                      Text(
                        '¥${item.amount}',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                  subtitle: (item.memo.isNotEmpty || paymentStr.isNotEmpty)
                      ? Padding(
                          padding: const EdgeInsets.only(top: 2),
                          child: Text(
                            [
                              paymentStr,
                              item.memo,
                            ].where((s) => s.isNotEmpty).join(' / '),
                            style: const TextStyle(fontSize: 11),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        )
                      : null,
                  onTap: () => _showEditDialog(item),
                );
              }),
              const Divider(height: 1),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildCategoryIcon(String expenseLabel) {
    Color color = Colors.grey;
    try {
      color = _expenseList.firstWhere((t) => t.label == expenseLabel).color;
    } catch (_) {}
    return Container(
      width: 10,
      height: 10,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }
}
