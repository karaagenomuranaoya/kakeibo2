import 'package:flutter/material.dart';
import '../models/transaction_item.dart';
import '../utils/app_date_utils.dart';

class TransactionTile extends StatelessWidget {
  final TransactionItem item;
  final Color categoryColor;
  // ▼▼ 追加: カテゴリアイコンを受け取る ▼▼
  final IconData? categoryIcon;
  // ▼▼ 追加: カテゴリ名（ID管理移行に伴い、表示名を外部から受け取る） ▼▼
  final String? categoryName;
  final VoidCallback? onTap;
  final bool showDate;

  const TransactionTile({
    super.key,
    required this.item,
    required this.categoryColor,
    this.categoryIcon,
    this.categoryName,
    this.onTap,
    this.showDate = true,
  });

  @override
  Widget build(BuildContext context) {
    final List<String> details = [];

    if (item.payment.isNotEmpty &&
        item.payment != '記録しない' &&
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
            child: Text.rich(
              TextSpan(
                children: [
                  // カテゴリ名
                  TextSpan(
                    text: categoryName ?? item.expense,
                    style: const TextStyle(
                      fontWeight: FontWeight.w500,
                      fontSize: 14, // 必要に応じて調整
                    ),
                  ),
                  // メモがある場合のみ追加
                  if (subtitleText.isNotEmpty)
                    TextSpan(
                      text: ' ($subtitleText)',
                      style: const TextStyle(
                        fontWeight: FontWeight.w200,
                        fontSize: 10, // 必要に応じて調整
                      ),
                    ),
                ],
              ),
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
          ),

          Text(
            '¥${item.amount}',
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
        ],
      ),

      trailing: onTap != null
          ? const Icon(Icons.chevron_right, size: 16, color: Colors.grey)
          : null,
      onTap: onTap,
    );
  }
}
