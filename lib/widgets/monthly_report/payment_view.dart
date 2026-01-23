import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../models/category_tag.dart';
import '../../models/transaction_item.dart';

/// 円グラフ表示用ウィジェット
class PaymentView extends StatelessWidget {
  final List<TransactionItem> history;
  final List<CategoryTag> paymentTags;
  final Function(String payment, Color color, String? paymentId)? onLegendTap;

  const PaymentView({
    super.key,
    required this.history,
    required this.paymentTags,
    this.onLegendTap,
  });

  @override
  Widget build(BuildContext context) {
    int total = history.fold(0, (s, i) => s + i.amount);

    // ID -> Tag, Label -> Tag のMap作成
    final idToTag = {for (var t in paymentTags) t.id: t};
    final labelToTag = {for (var t in paymentTags) t.label: t};

    // 集計: キーは "ID" または "名前(IDなしの場合)"
    final sums = <String, int>{};
    // キーから表示情報を引くためのマップ
    final keyToDisplayInfo = <String, CategoryTag>{};

    for (var item in history) {
      String key;
      CategoryTag? tag;

      if (item.paymentId != null) {
        tag = idToTag[item.paymentId];
      }
      if (tag == null) {
        tag = labelToTag[item.payment];
      }

      if (tag != null) {
        key = tag.id; // IDで集計
        keyToDisplayInfo[key] = tag;
      } else {
        key = item.payment; // タグが見つからない場合は名前で集計
      }

      sums[key] = (sums[key] ?? 0) + item.amount;
    }

    final sortedEntries = sums.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return Container(
      width: double.infinity,
      color: Colors.white,
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
      child: Column(
        children: [
          // 凡例エリア
          if (total > 0)
            Column(
              children: sortedEntries.map((e) {
                final amount = e.value;
                final key = e.key;
                final percentage = (amount / total * 100).toStringAsFixed(1);
                final tag = keyToDisplayInfo[key];

                if (tag == null || !tag.isManageablePayment) {
                  return const SizedBox.shrink();
                }

                String label = key;
                Color color = Colors.grey;
                IconData icon = Icons.label;
                String? paymentId;

                if (tag != null) {
                  label = tag.label;
                  color = tag.color;
                  icon = tag.displayIcon;
                  paymentId = tag.id;
                }

                return Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () => onLegendTap?.call(label, color, paymentId),
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
                            label,
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
