import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tutorial_coach_mark/tutorial_coach_mark.dart';
import '../models/category_tag.dart';
import '../models/transaction_item.dart';
import '../repositories/transaction_repository.dart';
import '../repositories/settings_repository.dart';
import '../widgets/monthly_report_components.dart';
import '../widgets/transaction_edit_dialog.dart';
import 'summary_detail_screen.dart';
import 'history_screen.dart';

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

  final GlobalKey _titleKey = GlobalKey();

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

  Future<void> _pickMonth() async {
    final DateTime now = DateTime.now();
    final DateTime current = DateTime(_currentYear, _currentMonth);

    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: current,
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
      initialDatePickerMode: DatePickerMode.year,
      helpText: '移動先の年月を選択',
    );

    if (picked != null) {
      final int diffMonths =
          (picked.year - now.year) * 12 + (picked.month - now.month);
      final int targetPage = 1000 + diffMonths;

      _pageController.jumpToPage(targetPage);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: GestureDetector(
          key: _titleKey,
          onTap: _pickMonth,
          child: Container(
            color: Colors.transparent,
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '$_currentYear年 $_currentMonth月',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(width: 4),
                const Icon(Icons.arrow_drop_down, size: 24),
              ],
            ),
          ),
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
          // 合計カードコンポーネント
          TotalExpenseCard(
            total: total,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => SummaryDetailScreen(
                    year: widget.year,
                    month: widget.month,
                  ),
                ),
              );
            },
          ),
          // カレンダー/グラフ切り替え
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            child: widget.tabIndex == 0
                ? CalendarView(
                    year: widget.year,
                    month: widget.month,
                    history: _history,
                    onDateTap: _scrollToDate,
                  )
                : GraphView(
                    history: _history,
                    expenseTags: _expenseTags,
                    onLegendTap: (expense, color) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => HistoryScreen(
                            filterValue: expense,
                            filterKey: 'expense',
                            color: color,
                            initialDate: DateTime(widget.year, widget.month),
                          ),
                        ),
                      );
                    },
                  ),
          ),
          const Divider(height: 1),
          // 日次リストコンポーネント
          DailyTransactionList(
            history: _history,
            expenseTags: _expenseTags,
            dayKeys: _dayKeys,
            onTransactionTap: (item) {
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
          ),
        ],
      ),
    );
  }
}
