import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../models/category_tag.dart';
import '../models/transaction_item.dart';
import '../repositories/settings_repository.dart';
import '../repositories/transaction_repository.dart';
import '../screens/transaction_edit_screen.dart';
import 'monthly_report/daily_transaction_list.dart';

class BarChartTab extends StatefulWidget {
  final int? dataVersion;

  const BarChartTab({super.key, this.dataVersion});

  @override
  State<BarChartTab> createState() => _BarChartTabState();
}

class _BarChartTabState extends State<BarChartTab> {
  final TransactionRepository _repository = TransactionRepository();
  final SettingsRepository _settingsRepository = SettingsRepository();

  List<TransactionItem> _allTransactions = [];
  List<CategoryTag> _expenseTags = [];
  Map<String, CategoryTag> _tagMap = {};

  bool _isMonthly = false; // false: 日ごと, true: 月ごと
  int _touchedIndex = -1; // 選択中のインデックス

  // 集計データ
  List<DateTime> _sortedKeys = []; // 日付または月のリスト (昇順)
  Map<DateTime, Map<String, double>> _groupedData =
      {}; // Key -> (CategoryId -> Amount)
  Map<DateTime, List<TransactionItem>> _groupedItems =
      {}; // Key -> List<TransactionItem>

  double _maxTotalY = 0;

  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void didUpdateWidget(covariant BarChartTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.dataVersion != widget.dataVersion) {
      _loadData();
    }
  }

  Future<void> _loadData() async {
    final transactions = await _repository.getAllTransactions();
    final tags = await _settingsRepository.loadExpenseTags();

    if (mounted) {
      setState(() {
        _allTransactions = transactions;
        _expenseTags = tags;
        _tagMap = {
          for (var t in tags) t.id: t,
          for (var t in tags) t.label: t, // 旧データ互換用
        };
        _processData();
        _isLoading = false;
      });
    }
  }

  void _processData() {
    _groupedData.clear();
    _groupedItems.clear();
    _sortedKeys.clear();

    if (_allTransactions.isEmpty) {
      // トランザクションがない場合でも、今日・明日くらいは表示する
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final tomorrow = today.add(const Duration(days: 1));

      if (_isMonthly) {
        _sortedKeys.add(DateTime(now.year, now.month));
      } else {
        _sortedKeys.add(today);
        _sortedKeys.add(tomorrow);
      }
    } else {
      // データがある範囲を特定
      DateTime minDate = DateTime(2100, 1, 1);
      DateTime maxDate = DateTime(2000, 1, 1);

      for (var item in _allTransactions) {
        if (item.date.isBefore(minDate)) minDate = item.date;
        if (item.date.isAfter(maxDate)) maxDate = item.date;
      }

      // 開始日と終了日を正規化
      DateTime startDate;
      DateTime endDate;
      final now = DateTime.now();

      if (_isMonthly) {
        startDate = DateTime(minDate.year, minDate.month);
        // 月次の場合、最大データがある月または今月まで
        DateTime dataMax = DateTime(maxDate.year, maxDate.month);
        DateTime thisMonth = DateTime(now.year, now.month);
        endDate = dataMax.isAfter(thisMonth) ? dataMax : thisMonth;
      } else {
        startDate = DateTime(minDate.year, minDate.month, minDate.day);
        // 日次の場合、最大データがある日または明日まで
        DateTime dataMax = DateTime(maxDate.year, maxDate.month, maxDate.day);
        DateTime tomorrow = DateTime(
          now.year,
          now.month,
          now.day,
        ).add(const Duration(days: 1));
        endDate = dataMax.isAfter(tomorrow) ? dataMax : tomorrow;
      }

      // 範囲内の全ての日付/月を生成
      DateTime current = startDate;
      while (!current.isAfter(endDate)) {
        _sortedKeys.add(current);
        if (_isMonthly) {
          // 次の月へ
          current = DateTime(current.year, current.month + 1);
        } else {
          // 次の日へ
          current = current.add(const Duration(days: 1));
        }
      }
    }

    // データのマッピング
    for (var item in _allTransactions) {
      DateTime key;
      if (_isMonthly) {
        key = DateTime(item.date.year, item.date.month);
      } else {
        key = DateTime(item.date.year, item.date.month, item.date.day);
      }

      // 範囲外のデータ（もしあれば）は無視するが、ロジック上含まれるはず
      if (!_groupedData.containsKey(key)) {
        _groupedData[key] = {};
      }
      if (!_groupedItems.containsKey(key)) {
        _groupedItems[key] = [];
      }

      _groupedItems[key]!.add(item);

      String catId = item.expenseId ?? item.expense;
      if (item.expenseId == null) {
        final tag = _tagMap[item.expense];
        if (tag != null) {
          catId = tag.id;
        }
      }

      _groupedData[key]![catId] =
          (_groupedData[key]![catId] ?? 0) + item.amount;
    }

    // 最大値を計算
    _maxTotalY = 0;
    for (var key in _sortedKeys) {
      double sum = 0;
      if (_groupedData.containsKey(key)) {
        for (var amount in _groupedData[key]!.values) {
          sum += amount;
        }
      }
      if (sum > _maxTotalY) {
        _maxTotalY = sum;
      }
    }
    if (_maxTotalY == 0) _maxTotalY = 1000;

    // デフォルトで最新（右端）を選択
    // ユーザー操作で選択済みのインデックスがある場合、それが有効なら維持したいが、
    // 配列が変わるのでインデックスはずれる。日付で追跡するのが良いが、
    // ここではシンプルに常に右端（最新）を選択にする（要件「右から...」の視点に合わせて）
    // もしユーザーが「動かせない」と言ったのが「リロードされるたびに右端に戻る」という意味なら修正が必要だが、
    // 今回の修正は初期化時とタブ切り替え時のみなのでOKのはず。
    if (_sortedKeys.isNotEmpty) {
      _touchedIndex = _sortedKeys.length - 1;
    } else {
      _touchedIndex = -1;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    List<TransactionItem> selectedItems = [];
    if (_touchedIndex >= 0 && _touchedIndex < _sortedKeys.length) {
      final key = _sortedKeys[_touchedIndex];
      selectedItems = _groupedItems[key] ?? [];
      selectedItems.sort((a, b) => b.date.compareTo(a.date));
    }

    return Column(
      children: [
        // 切り替えボタン
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: SegmentedButton<bool>(
            segments: const [
              ButtonSegment<bool>(value: false, label: Text('日ごと')),
              ButtonSegment<bool>(value: true, label: Text('月ごと')),
            ],
            selected: {_isMonthly},
            onSelectionChanged: (Set<bool> newSelection) {
              setState(() {
                _isMonthly = newSelection.first;
                _processData();
              });
            },
            showSelectedIcon: false,
          ),
        ),

        // グラフエリア
        Container(
          height: 300, // 高さを少し増やす
          padding: const EdgeInsets.only(top: 20, bottom: 10),
          child: _sortedKeys.isEmpty
              ? const Center(child: Text("データがありません"))
              : SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  reverse: true, // 右側が初期位置
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    // 幅を調整: 棒の幅(32) + 余白(20) = 52px
                    width: _sortedKeys.length * 52.0 + 20,
                    child: BarChart(
                      BarChartData(
                        alignment: BarChartAlignment.start,
                        groupsSpace: 20,
                        maxY: _maxTotalY * 1.2,
                        barTouchData: BarTouchData(
                          handleBuiltInTouches: false, // 自前で制御するためfalse
                          touchCallback:
                              (FlTouchEvent event, barTouchResponse) {
                                if (event is! FlTapUpEvent ||
                                    barTouchResponse == null ||
                                    barTouchResponse.spot == null) {
                                  return;
                                }
                                setState(() {
                                  _touchedIndex = barTouchResponse
                                      .spot!
                                      .touchedBarGroupIndex;
                                });
                              },
                          touchTooltipData: BarTouchTooltipData(
                            getTooltipColor: (_) => Colors.transparent,
                            tooltipPadding: EdgeInsets.zero,
                            tooltipMargin: 8,
                            getTooltipItem: (group, groupIndex, rod, rodIndex) {
                              return BarTooltipItem(
                                '${rod.toY.toInt()}円',
                                TextStyle(
                                  color:
                                      (_touchedIndex == -1 ||
                                          groupIndex == _touchedIndex)
                                      ? Colors.black
                                      : Colors.grey.withOpacity(0.5),
                                  fontWeight: FontWeight.bold,
                                  fontSize: 10,
                                ),
                              );
                            },
                          ),
                        ),
                        titlesData: FlTitlesData(
                          show: true,
                          topTitles: const AxisTitles(
                            sideTitles: SideTitles(showTitles: false),
                          ),
                          rightTitles: const AxisTitles(
                            sideTitles: SideTitles(showTitles: false),
                          ),
                          leftTitles: const AxisTitles(
                            sideTitles: SideTitles(showTitles: false),
                          ),
                          bottomTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              getTitlesWidget: (double value, TitleMeta meta) {
                                final index = value.toInt();
                                if (index < 0 || index >= _sortedKeys.length)
                                  return const SizedBox.shrink();
                                final key = _sortedKeys[index];
                                final text = _isMonthly
                                    ? "${key.year}/${key.month}" // 年も表示した方が分かりやすい
                                    : "${key.month}/${key.day}";
                                return SideTitleWidget(
                                  axisSide: meta.axisSide,
                                  child: Text(
                                    text,
                                    style: const TextStyle(fontSize: 10),
                                  ),
                                );
                              },
                              reservedSize: 30,
                            ),
                          ),
                        ),
                        borderData: FlBorderData(show: false),
                        gridData: const FlGridData(show: false),
                        barGroups: List.generate(_sortedKeys.length, (index) {
                          final key = _sortedKeys[index];
                          final data = _groupedData[key] ?? {};

                          double currentY = 0;
                          final rods = <BarChartRodStackItem>[];

                          bool isSelected = index == _touchedIndex;
                          double opacity = isSelected ? 1.0 : 0.3;

                          for (var tag in _expenseTags) {
                            double amount = data[tag.id] ?? 0;
                            if (amount == 0 && data.containsKey(tag.label)) {
                              amount = data[tag.label]!;
                            }
                            if (amount > 0) {
                              rods.add(
                                BarChartRodStackItem(
                                  currentY,
                                  currentY + amount,
                                  tag.color.withOpacity(opacity),
                                ),
                              );
                              currentY += amount;
                            }
                          }

                          data.forEach((k, v) {
                            bool isKnown = _expenseTags.any(
                              (t) => t.id == k || t.label == k,
                            );
                            if (!isKnown) {
                              rods.add(
                                BarChartRodStackItem(
                                  currentY,
                                  currentY + v,
                                  Colors.grey.withOpacity(opacity),
                                ),
                              );
                              currentY += v;
                            }
                          });

                          return BarChartGroupData(
                            x: index,
                            barRods: [
                              BarChartRodData(
                                toY: currentY > 0 ? currentY : 0,
                                rodStackItems: rods,
                                width: 32, // 太くした
                                borderRadius: BorderRadius.zero,
                                backDrawRodData: BackgroundBarChartRodData(
                                  show: true, // 常に表示してタッチ領域を確保（データ0の日も）
                                  toY: _maxTotalY * 1.2,
                                  color: index == _touchedIndex
                                      ? Colors.grey.withOpacity(0.1)
                                      : Colors.transparent,
                                ),
                              ),
                            ],
                            showingTooltipIndicators: [0],
                          );
                        }),
                      ),
                    ),
                  ),
                ),
        ),

        // 凡例 (Legend)
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: _expenseTags.map((tag) {
              return Padding(
                padding: const EdgeInsets.only(right: 12),
                child: Row(
                  children: [
                    Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: tag.color,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(tag.label, style: const TextStyle(fontSize: 12)),
                  ],
                ),
              );
            }).toList(),
          ),
        ),

        const Divider(height: 1),

        // リスト表示
        Expanded(
          child: SingleChildScrollView(
            // オーバーフロー防止のために追加
            child: DailyTransactionList(
              history: selectedItems,
              expenseTags: _expenseTags,
              dayKeys: {},
              onTransactionTap: (item) async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => TransactionEditScreen(item: item),
                  ),
                );
                _loadData();
              },
            ),
          ),
        ),
      ],
    );
  }
}
