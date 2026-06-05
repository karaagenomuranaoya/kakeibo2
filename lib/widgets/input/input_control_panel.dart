import 'package:flutter/material.dart';

// カード選択ロジックは PaymentSelector に移動しました。
// ここは「保存ボタン」「取り消しボタン」などのアクションパネルとして機能します。
class InputControlPanel extends StatelessWidget {
  final VoidCallback onSave;
  final VoidCallback? onUndo;
  final bool showUndo;

  const InputControlPanel({
    super.key,
    required this.onSave,
    this.onUndo,
    this.showUndo = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // 保存ボタン
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: onSave,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
            child: const Text(
              '保存',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
          ),
        ),

        // 直前の入力を取り消すボタン
        if (showUndo && onUndo != null)
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: SizedBox(
              height: 30,
              child: TextButton.icon(
                onPressed: onUndo,
                icon: const Icon(Icons.undo, size: 16, color: Colors.grey),
                label: const Text(
                  '前回の入力を取り消す',
                  style: TextStyle(color: Colors.grey, fontSize: 12),
                ),
                style: TextButton.styleFrom(
                  padding: EdgeInsets.zero,
                  visualDensity: VisualDensity.compact,
                ),
              ),
            ),
          ),

        // 下部の余白確保（FABやホームバー対策）
        const SizedBox(height: 10),
      ],
    );
  }
}
