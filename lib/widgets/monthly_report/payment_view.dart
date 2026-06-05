import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart'; // 使っていませんがimportは維持
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
    // ============== ロジック部分はそのまま ==============
    int total = history.fold(0, (s, i) => s + i.amount);

    final idToTag = {for (var t in paymentTags) t.id: t};
    final labelToTag = {for (var t in paymentTags) t.label: t};

    final sums = <String, int>{};
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
        key = tag.id;
        keyToDisplayInfo[key] = tag;
      } else {
        key = item.payment;
      }

      sums[key] = (sums[key] ?? 0) + item.amount;
    }

    final sortedEntries = sums.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    // =================================================

    return Container(
      width: double.infinity,
      color: Colors.white, // 背景は白のまま
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
      child: Column(
        children: [
          if (total > 0)
            Column(
              children: sortedEntries.map((e) {
                final amount = e.value;
                final key = e.key;
                final percentage = (amount / total * 100).toStringAsFixed(1);
                final tag = keyToDisplayInfo[key];

                // ロジック維持: 表示対象外なら非表示
                if (tag == null || !tag.isManageablePayment) {
                  return const SizedBox.shrink();
                }

                String label = key;
                Color color = Colors.grey;
                IconData icon = Icons.label;
                String? paymentId;

                // 締め日・支払日のテキスト作成用
                String dateInfo = "";

                if (tag != null) {
                  label = tag.label;
                  color = tag.color;
                  icon = tag.displayIcon;
                  paymentId = tag.id;

                  // カード情報のテキスト生成
                  final List<String> parts = [];
                  if (tag.closingDay != null) {
                    final closeText = tag.closingDay == 99
                        ? "末日"
                        : "${tag.closingDay}日";
                    parts.add("$closeText締");
                  }
                  if (tag.paymentDay != null) {
                    final payText = tag.paymentDay == 99
                        ? "末日"
                        : "${tag.paymentDay}日";
                    // 翌月払いなどのオフセット情報を入れたければここにロジック追加
                    parts.add("$payText払");
                  }
                  dateInfo = parts.join(" / ");
                }

                // ▼▼▼ ここから見た目をリッチに変更 ▼▼▼
                return Container(
                  margin: const EdgeInsets.only(bottom: 12), // カード間の余白
                  decoration: BoxDecoration(
                    // グラデーションでリッチ感を出す
                    gradient: LinearGradient(
                      colors: [
                        color,
                        color.withOpacity(0.7), // 少し薄い色へ
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16), // カードらしい角丸
                    boxShadow: [
                      BoxShadow(
                        color: color.withOpacity(0.4),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () => onLegendTap?.call(label, color, paymentId),
                      borderRadius: BorderRadius.circular(16),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // 上段: アイコン + カード名 + 金額
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.2),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    icon,
                                    color: Colors.white,
                                    size: 20,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        label,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 14,
                                          fontWeight: FontWeight.bold,
                                          shadows: [
                                            Shadow(
                                              blurRadius: 2,
                                              color: Colors.black26,
                                              offset: Offset(0, 1),
                                            ),
                                          ],
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 4),
                                      // 締め日情報があればここに表示
                                      if (dateInfo.isNotEmpty)
                                        Text(
                                          dateInfo,
                                          style: TextStyle(
                                            color: Colors.white.withOpacity(
                                              0.9,
                                            ),
                                            fontSize: 11,
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text(
                                      '¥$amount',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 20,
                                        fontWeight: FontWeight.w800,
                                        shadows: [
                                          Shadow(
                                            blurRadius: 4,
                                            color: Colors.black26,
                                            offset: Offset(0, 2),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Text(
                                      '$percentage%',
                                      style: TextStyle(
                                        color: Colors.white.withOpacity(0.8),
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            // ここにチップ画像などを置くとさらにカードっぽくなりますが、
                            // とりあえずシンプルに余白のみ
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            )
          else
            const Center(
              child: Text('データがありません', style: TextStyle(color: Colors.grey)),
            ),
        ],
      ),
    );
  }
}
