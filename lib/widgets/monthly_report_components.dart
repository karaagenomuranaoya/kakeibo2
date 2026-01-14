import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../models/category_tag.dart';
import '../models/transaction_item.dart';

/// カレンダー表示用ウィジェット
class CalendarView extends StatelessWidget {
  final int year;
  final int month;
  final List<TransactionItem> history;
  final Function(int day) onDateTap;

  const CalendarView({
    super.key,
    required this.year,
    required this.month,
    required this.history,
    required this.onDateTap,
  });

  @override
  Widget build(BuildContext context) {
    final daysInMonth = DateTime(year, month + 1, 0).day;
    final firstWeekday = DateTime(year, month, 1).weekday;
    // DateTime.weekdayは 月=1 ... 日=7。カレンダーは日曜始まりとするなら調整が必要。
    // ここでは単純に 月曜始まり(0)〜日曜(6) ではなく、標準的なカレンダー(日曜左)に合わせる計算。
    // weekday: 1(Mon)..7(Sun). Sunday start: Sun=0, Mon=1...
    // empty slots = (weekday % 7). If 1st is Sun(7), 7%7=0 slots. If Mon(1), 1 slot.
    final int emptyCount = firstWeekday % 7;

    final hasDataDays = history.map((e) => e.date.day).toSet();

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
                onTap: hasData ? () => onDateTap(day) : null,
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
}

/// 円グラフ表示用ウィジェット
class GraphView extends StatelessWidget {
  final List<TransactionItem> history;
  final List<CategoryTag> expenseTags;

  const GraphView({
    super.key,
    required this.history,
    required this.expenseTags,
  });

  @override
  Widget build(BuildContext context) {
    int total = history.fold(0, (s, i) => s + i.amount);

    // 費目ごとの集計
    final expenseSums = <String, int>{};
    for (var item in history) {
      expenseSums[item.expense] =
          (expenseSums[item.expense] ?? 0) + item.amount;
    }
    // 金額順にソート
    final sortedEntries = expenseSums.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    List<PieChartSectionData> sections = [];
    if (total > 0) {
      sections = sortedEntries.map((e) {
        final percentage = (e.value / total) * 100;

        // 色を検索
        Color color = Colors.grey;
        try {
          color = expenseTags.firstWhere((t) => t.label == e.key).color;
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
      // データがない場合のグレー円
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
}
