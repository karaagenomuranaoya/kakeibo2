import 'package:flutter/material.dart';
import '../../models/category_tag.dart';
import '../../models/transaction_item.dart';
import '../transaction_tile.dart'; // 既存のTransactionTileをインポート

/// 日ごとのトランザクションリスト
class DailyTransactionList extends StatelessWidget {
  final List<TransactionItem> history;
  final List<CategoryTag> expenseTags;
  final Map<int, GlobalKey> dayKeys;
  final Function(TransactionItem item) onTransactionTap;

  const DailyTransactionList({
    super.key,
    required this.history,
    required this.expenseTags,
    required this.dayKeys,
    required this.onTransactionTap,
  });

  @override
  Widget build(BuildContext context) {
    if (history.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(30),
        child: Center(
          child: Text('データがありません', style: TextStyle(color: Colors.grey)),
        ),
      );
    }

    // 日ごとにグループ化
    final grouped = <int, List<TransactionItem>>{};
    for (var item in history) {
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
        // 親から渡されたキーマップに登録
        if (!dayKeys.containsKey(day)) {
          dayKeys[day] = GlobalKey();
        }

        final dayTotal = items.fold(0, (sum, i) => sum + i.amount);
        final dateObj = items.first.date;
        final weekStr = weekDays[dateObj.weekday - 1];

        return Container(
          key: dayKeys[day],
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
                IconData? icon;

                try {
                  final tag = expenseTags.firstWhere(
                    (t) => t.label == item.expense,
                  );
                  color = tag.color;
                  icon = tag.displayIcon;
                } catch (_) {}

                return TransactionTile(
                  item: item,
                  categoryColor: color,
                  categoryIcon: icon,
                  showDate: false,
                  onTap: () => onTransactionTap(item),
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
