import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../../models/transaction_item.dart';

/// 棒グラフ表示用ウィジェット（横スクロール対応版）
class DailyBarChart extends StatelessWidget {
  final int year;
  final int month;
  final List<TransactionItem> history;
  final Function(int day) onDateTap;

  const DailyBarChart({
    super.key,
    required this.year,
    required this.month,
    required this.history,
    required this.onDateTap,
  });

  @override
  Widget build(BuildContext context) {
    final daysInMonth = DateTime(year, month + 1, 0).day;

    // データ集計
    final Map<int, int> dailyTotals = {};
    for (var item in history) {
      dailyTotals[item.date.day] =
          (dailyTotals[item.date.day] ?? 0) + item.amount;
    }

    int maxAmount = 0;
    if (dailyTotals.isNotEmpty) {
      maxAmount = dailyTotals.values.reduce((a, b) => a > b ? a : b);
    }
    final double maxY = maxAmount == 0 ? 1000 : maxAmount * 1.2;

    // ★ここがポイント：1日あたりの幅を決める（例: 40px）
    // 31日あれば 1240px の幅になるので、余裕を持って表示できる
    const double barWidth = 40.0;
    final double chartWidth = daysInMonth * barWidth;

    return Container(
      height: 300,
      color: Colors.white,
      // パディングはスクロールビューの外ではなく、グラフの内側で調整したほうが安全
      padding: const EdgeInsets.symmetric(vertical: 24),

      // ▼▼▼ 横スクロールを追加 ▼▼▼
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Container(
          width: chartWidth, // 計算した幅をセット
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: BarChart(
            BarChartData(
              // spaceAround だと等間隔になるが、幅を指定したので start や center でもOK
              alignment: BarChartAlignment.center,
              maxY: maxY,
              barTouchData: BarTouchData(
                allowTouchBarBackDraw: true,
                touchTooltipData: BarTouchTooltipData(
                  fitInsideVertically: true,
                  getTooltipColor: (_) => Colors.blueGrey,
                  getTooltipItem: (group, groupIndex, rod, rodIndex) {
                    return BarTooltipItem(
                      '${group.x.toInt()}日\n¥${rod.toY.toInt()}',
                      const TextStyle(color: Colors.white),
                    );
                  },
                ),
                touchCallback: (FlTouchEvent event, barTouchResponse) {
                  if (event is FlTapUpEvent &&
                      barTouchResponse != null &&
                      barTouchResponse.spot != null) {
                    final day = barTouchResponse.spot!.touchedBarGroup.x
                        .toInt();
                    onDateTap(day);
                  }
                },
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
                      final day = value.toInt();
                      // 横幅が十分あるので、全ての日付を表示しても重ならない！
                      return Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          '$day',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.grey,
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
              gridData: const FlGridData(show: false),
              borderData: FlBorderData(show: false),

              // 棒の間隔や幅の設定
              groupsSpace: 20, // グループ間のスペース
              barGroups: List.generate(daysInMonth, (index) {
                final day = index + 1;
                final amount = dailyTotals[day] ?? 0;
                return BarChartGroupData(
                  x: day,
                  barRods: [
                    BarChartRodData(
                      toY: amount.toDouble(),
                      color: amount > 0 ? Colors.orange : Colors.grey.shade200,
                      // 幅があるので棒も太くできる
                      width: 12,
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(4),
                      ),
                      backDrawRodData: BackgroundBarChartRodData(
                        show: true,
                        toY: maxY,
                        color: Colors.grey.shade50,
                      ),
                    ),
                  ],
                );
              }),
            ),
          ),
        ),
      ),
    );
  }
}
