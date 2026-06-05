import 'package:flutter/material.dart';
import '../models/category_tag.dart';
import '../models/transaction_item.dart';
import '../repositories/transaction_repository.dart';
import '../repositories/settings_repository.dart';
import '../widgets/monthly_report_components.dart'; // TotalExpenseCard等のため
import '../widgets/monthly_report/payment_view.dart'; // グラフ表示用
import 'history_screen.dart';

class PaymentScreen extends StatefulWidget {
  final int? dataVersion;
  const PaymentScreen({super.key, this.dataVersion});

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  // 1000ヶ月分(前後約80年)のページングを可能にする設定
  final PageController _pageController = PageController(initialPage: 1000);

  late int _currentYear;
  late int _currentMonth;
  final GlobalKey _titleKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _currentYear = now.year;
    _currentMonth = now.month;
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  // ページ切り替え時の処理（年月更新）
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

  // 年月選択ダイアログ
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
      ),
      body: PageView.builder(
        controller: _pageController,
        onPageChanged: _onPageChanged,
        itemBuilder: (context, index) {
          final d = DateTime(
            DateTime.now().year,
            DateTime.now().month + (index - 1000),
          );
          // 各月のグラフページを表示
          return PaymentPage(
            year: d.year,
            month: d.month,
            dataVersion: widget.dataVersion,
          );
        },
      ),
    );
  }
}

class PaymentPage extends StatefulWidget {
  final int year;
  final int month;
  final int? dataVersion;

  const PaymentPage({
    super.key,
    required this.year,
    required this.month,
    this.dataVersion,
  });

  @override
  State<PaymentPage> createState() => _PaymentPageState();
}

class _PaymentPageState extends State<PaymentPage> {
  List<TransactionItem> _history = [];
  List<CategoryTag> _paymentTags = [];
  final TransactionRepository _repository = TransactionRepository();
  final SettingsRepository _settingsRepository = SettingsRepository();

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didUpdateWidget(covariant PaymentPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.dataVersion != widget.dataVersion) {
      _load();
    }
  }

  Future<void> _load() async {
    final allItems = await _repository.getAllTransactions();
    final payments = await _settingsRepository.loadCardTags();

    if (mounted) {
      setState(() {
        // 対象年月のデータのみ抽出
        _history = allItems.where((i) {
          return i.date.year == widget.year && i.date.month == widget.month;
        }).toList();
        _paymentTags = payments;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final int total = _history.fold(0, (s, i) => s + i.amount);

    return SingleChildScrollView(
      padding: const EdgeInsets.only(bottom: 50),
      child: Column(
        children: [
          // 合計金額カード
          TotalExpenseCard(total: total),
          const SizedBox(height: 10),
          // グラフビュー
          PaymentView(
            history: _history,
            paymentTags: _paymentTags,
            onLegendTap: (payment, color, paymentId) {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => HistoryScreen(
                    filterValue: payment,
                    filterId: paymentId,
                    filterKey: 'payment',
                    color: color,
                    initialDate: DateTime(widget.year, widget.month),
                    //initialDate: DateTime(widget.year, widget.month),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
