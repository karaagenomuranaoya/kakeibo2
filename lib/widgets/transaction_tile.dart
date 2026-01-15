import 'package:flutter/material.dart';
import '../models/transaction_item.dart';
import '../utils/app_date_utils.dart';

class TransactionTile extends StatelessWidget {
  final TransactionItem item;
  final Color categoryColor;
  // ▼▼ 追加: カテゴリアイコンを受け取る ▼▼
  final IconData? categoryIcon;
  final VoidCallback? onTap;
  final bool showDate;

  const TransactionTile({
    super.key,
    required this.item,
    required this.categoryColor,
    this.categoryIcon, // 追加
    this.onTap,
    this.showDate = true,
  });

  @override
  Widget build(BuildContext context) {
    final List<String> details = [];

    if (item.payment.isNotEmpty &&
        item.payment != '現金' &&
        item.payment != 'デフォルト') {
      details.add(item.payment);
    }
    if (item.memo.isNotEmpty) {
      details.add(item.memo);
    }

    final String subtitleText = details.join(' / ');
    final String dateText = showDate
        ? AppDateUtils.formatDateTime(item.date)
        : "";

    return ListTile(
      dense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
      leading: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // ▼▼ 変更: アイコンを表示（なければラベルアイコン） ▼▼
          Icon(categoryIcon ?? Icons.label, color: categoryColor),
        ],
      ),
      title: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              item.expense,
              style: const TextStyle(fontWeight: FontWeight.w500),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Text(
            '¥${item.amount}',
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
        ],
      ),
      subtitle: (subtitleText.isNotEmpty || dateText.isNotEmpty)
          ? Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Row(
                children: [
                  if (showDate) ...[
                    Text(dateText, style: const TextStyle(fontSize: 11)),
                    if (subtitleText.isNotEmpty)
                      const Text(
                        '  |  ',
                        style: TextStyle(color: Colors.grey, fontSize: 10),
                      ),
                  ],
                  if (subtitleText.isNotEmpty)
                    Expanded(
                      child: Text(
                        subtitleText,
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey.shade700,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                ],
              ),
            )
          : null,
      trailing: onTap != null
          ? const Icon(Icons.chevron_right, size: 16, color: Colors.grey)
          : null,
      onTap: onTap,
    );
  }
}
