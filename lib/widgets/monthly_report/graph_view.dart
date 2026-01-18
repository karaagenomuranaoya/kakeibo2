import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../models/category_tag.dart';
import '../../models/transaction_item.dart';

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
                IconData icon = Icons.label;

                try {
                  final tag = expenseTags.firstWhere((t) => t.label == e.key);
                  color = tag.color;
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
