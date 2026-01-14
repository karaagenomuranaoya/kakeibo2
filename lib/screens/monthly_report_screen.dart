import 'package:flutter/material.dart';
import '../models/category_tag.dart';
import '../models/transaction_item.dart';
import '../repositories/transaction_repository.dart';
import '../repositories/settings_repository.dart';
import '../widgets/monthly_report_components.dart';
import '../widgets/transaction_tile.dart';
// ▼▼ ここに黄色い波線が出る場合、上の「transaction_edit_dialog.dart」が作成されていません ▼▼
import '../widgets/transaction_edit_dialog.dart';
import 'summary_detail_screen.dart';

class MonthlyHistoryScreen extends StatefulWidget {
  const MonthlyHistoryScreen({super.key});
  @override
  State<MonthlyHistoryScreen> createState() => _MonthlyHistoryScreenState();
}

class _MonthlyHistoryScreenState extends State<MonthlyHistoryScreen>
    with SingleTickerProviderStateMixin {
  final PageController _pageController = PageController(initialPage: 1000);
  late TabController _tabController;

  late int _currentYear;
  late int _currentMonth;
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
  final int tabIndex;

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
  List<CategoryTag> _expenseTags = [];
  final TransactionRepository _repository = TransactionRepository();
  final SettingsRepository _settingsRepository = SettingsRepository();
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
        _history = allItems.where((i) {
          return i.date.year == widget.year && i.date.month == widget.month;
        }).toList();
        _history.sort((a, b) => b.date.compareTo(a.date));
        _expenseTags = expenses;
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

  @override
  Widget build(BuildContext context) {
    final int total = _history.fold(0, (s, i) => s + i.amount);

    return SingleChildScrollView(
      padding: const EdgeInsets.only(bottom: 50),
      child: Column(
        children: [
          _buildTotalCard(total),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            child: widget.tabIndex == 0
                ? CalendarView(
                    year: widget.year,
                    month: widget.month,
                    history: _history,
                    onDateTap: _scrollToDate,
                  )
                : GraphView(history: _history, expenseTags: _expenseTags),
          ),
          const Divider(height: 1),
          _buildDailyList(),
        ],
      ),
    );
  }

  Widget _buildTotalCard(int total) {
    return Material(
      color: Colors.blue.shade50,
      child: InkWell(
        onTap: () {
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
      ),
    );
  }

  Widget _buildDailyList() {
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
    const weekDays = ["月", "火", "水", "木", "金", "土", "日"];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: sortedDays.map((day) {
        final items = grouped[day]!;
        if (!_dayKeys.containsKey(day)) {
          _dayKeys[day] = GlobalKey();
        }

        final dayTotal = items.fold(0, (sum, i) => sum + i.amount);
        final dateObj = items.first.date;
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
                Color color = Colors.grey;
                try {
                  color = _expenseTags
                      .firstWhere((t) => t.label == item.expense)
                      .color;
                } catch (_) {}

                return TransactionTile(
                  item: item,
                  categoryColor: color,
                  showDate: false,
                  onTap: () {
                    showDialog(
                      context: context,
                      builder: (context) => TransactionEditDialog(
                        item: item,
                        // ▼▼▼ 型エラー対策として { _load(); } で囲みました ▼▼▼
                        onSuccess: () {
                          _load();
                        },
                      ),
                    );
                  },
                );
              }),
              const Divider(height: 1),
            ],
          ),
        );
      }).toList(),
    );
  }
}
