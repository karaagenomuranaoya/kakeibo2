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
  final Function(String expense, Color color)? onLegendTap;

  const GraphView({
    super.key,
    required this.history,
    required this.expenseTags,
    this.onLegendTap,
  });

  @override
  Widget build(BuildContext context) {
    int total = history.fold(0, (s, i) => s + i.amount);

    final expenseSums = <String, int>{};
    for (var item in history) {
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
          color = expenseTags.firstWhere((t) => t.label == e.key).color;
        } catch (_) {}

        return PieChartSectionData(
          color: color,
          value: e.value.toDouble(),
          title: '${percentage.toStringAsFixed(0)}%',
          radius: 60,
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
          radius: 60,
        ),
      ];
    }

    return Container(
      width: double.infinity,
      color: Colors.white,
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
      child: Column(
        children: [
          SizedBox(
            height: 220,
            child: PieChart(
              PieChartData(
                sections: sections,
                centerSpaceRadius: 40,
                sectionsSpace: 2,
                borderData: FlBorderData(show: false),
              ),
            ),
          ),
          const SizedBox(height: 20),
          // 凡例エリア
          if (total > 0)
            Column(
              children: sortedEntries.map((e) {
                final amount = e.value;
                final percentage = (amount / total * 100).toStringAsFixed(1);

                Color color = Colors.grey;
                IconData icon = Icons.label; // デフォルト

                try {
                  final tag = expenseTags.firstWhere((t) => t.label == e.key);
                  color = tag.color;
                  // ▼▼ 変更: アイコンを取得 ▼▼
                  icon = tag.displayIcon;
                } catch (_) {}

                return Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () => onLegendTap?.call(e.key, color),
                    borderRadius: BorderRadius.circular(4),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        vertical: 8,
                        horizontal: 4,
                      ),
                      child: Row(
                        children: [
                          // ▼▼ 変更: アイコン表示 ▼▼
                          Icon(icon, color: color, size: 20),
                          const SizedBox(width: 8),
                          Text(
                            e.key,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const Spacer(),
                          Text(
                            '¥$amount',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(width: 10),
                          SizedBox(
                            width: 40,
                            child: Text(
                              '$percentage%',
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.grey,
                              ),
                              textAlign: TextAlign.right,
                            ),
                          ),
                          const SizedBox(width: 4),
                          const Icon(
                            Icons.chevron_right,
                            size: 16,
                            color: Colors.grey,
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }).toList(),
            )
          else
            const Text('データがありません', style: TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }
}
