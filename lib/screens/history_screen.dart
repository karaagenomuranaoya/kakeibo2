import 'package:flutter/material.dart';
import '../models/category_tag.dart';
import '../services/history_service.dart';
import '../widgets/card_settings_dialog.dart';
// ▼ 作成したファイルをインポート
import 'history_monthly_page.dart';

class HistoryScreen extends StatefulWidget {
  final String filterValue;
  final String filterKey; // 'expense' or 'payment'
  final Color? color;
  final int? year; // 指定年月がある場合
  final int? month;
  final DateTime? initialDate; // カレンダーから遷移した場合の初期表示位置

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
  int _viewMode = 0; // 0:利用履歴, 1:引き落とし予定
  bool _showTab = false; // クレカ等の場合のみタブを表示
  CategoryTag? _currentCardTag;

  late PageController _pageController;
  final HistoryService _historyService = HistoryService();

  @override
  void initState() {
    super.initState();
    _setupPageController();
    _checkIfCardType();
  }

  void _setupPageController() {
    int initialPage = 1000;
    if (widget.initialDate != null) {
      final now = DateTime.now();
      final diff =
          (widget.initialDate!.year - now.year) * 12 +
          (widget.initialDate!.month - now.month);
      initialPage = 1000 + diff;
    }
    _pageController = PageController(initialPage: initialPage);
  }

  Future<void> _checkIfCardType() async {
    if (widget.filterKey == 'payment' && widget.filterValue != '現金') {
      final card = await _historyService.getCardTagByLabel(widget.filterValue);
      if (card != null && mounted) {
        setState(() {
          _currentCardTag = card;
          _showTab = card.closingDay != null;
          if (!_showTab) _viewMode = 0;
        });
      }
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
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
    // 特定の年月指定モード（カレンダーからの遷移ではなく、レポートからのドリルダウン等）の場合
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
                // 年月固定モード
                ? HistoryMonthlyPage(
                    year: widget.year!,
                    month: widget.month!,
                    filterValue: widget.filterValue,
                    filterKey: widget.filterKey,
                    color: widget.color ?? Colors.blue,
                    viewMode: _viewMode,
                    showNavButtons: false,
                    service: _historyService,
                  )
                // スワイプ可能なページビューモード
                : PageView.builder(
                    controller: _pageController,
                    itemBuilder: (context, index) {
                      final now = DateTime.now();
                      final targetDate = DateTime(
                        now.year,
                        now.month + (index - 1000),
                      );
                      return HistoryMonthlyPage(
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
                        service: _historyService,
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
