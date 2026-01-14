import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class AmountInputArea extends StatelessWidget {
  final DateTime selectedDate;
  final TextEditingController amountController;
  final FocusNode amountFocusNode;
  final TextEditingController memoController;
  final FocusNode memoFocusNode;
  final VoidCallback onDateTap;
  final VoidCallback onAmountTap;

  const AmountInputArea({
    super.key,
    required this.selectedDate,
    required this.amountController,
    required this.amountFocusNode,
    required this.memoController,
    required this.memoFocusNode,
    required this.onDateTap,
    required this.onAmountTap,
  });

  String _getDayOfWeek(DateTime date) {
    const weekDays = ["月", "火", "水", "木", "金", "土", "日"];
    return weekDays[date.weekday - 1];
  }

  @override
  Widget build(BuildContext context) {
    final dateStr = DateFormat('MM/dd').format(selectedDate);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // 日付選択ボタン
        GestureDetector(
          onTap: onDateTap,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.blue.shade100),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.calendar_today, size: 14, color: Colors.blue),
                const SizedBox(width: 8),
                Text(
                  "$dateStr (${_getDayOfWeek(selectedDate)})",
                  style: const TextStyle(
                    color: Colors.blue,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 15),

        // 金額入力フィールド
        GestureDetector(
          onTap: onAmountTap,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              const Text(
                "¥",
                style: TextStyle(
                  fontSize: 56,
                  fontWeight: FontWeight.bold,
                  color: Colors.black54,
                ),
              ),
              const SizedBox(width: 10),
              IntrinsicWidth(
                child: TextField(
                  controller: amountController,
                  focusNode: amountFocusNode,
                  readOnly: true, // カスタムキーボードを使用するためreadOnly
                  showCursor: true,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 56,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                    height: 1.0,
                  ),
                  decoration: const InputDecoration(
                    hintText: '0',
                    hintStyle: TextStyle(color: Colors.black12),
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),

        // メモ入力フィールド
        Container(
          width: 240,
          padding: const EdgeInsets.symmetric(horizontal: 10),
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            borderRadius: BorderRadius.circular(8),
          ),
          child: TextField(
            controller: memoController,
            focusNode: memoFocusNode,
            textAlign: TextAlign.center,
            decoration: const InputDecoration(
              hintText: 'メモを入力...',
              isDense: true,
              contentPadding: EdgeInsets.symmetric(vertical: 8),
              border: InputBorder.none,
              hintStyle: TextStyle(fontSize: 12, color: Colors.grey),
              prefixIcon: Icon(Icons.edit, size: 14, color: Colors.grey),
              prefixIconConstraints: BoxConstraints(minWidth: 24),
            ),
            style: const TextStyle(fontSize: 13),
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => memoFocusNode.unfocus(),
          ),
        ),
      ],
    );
  }
}
