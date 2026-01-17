import 'package:flutter/material.dart';

class GachaCompleteDialog extends StatelessWidget {
  const GachaCompleteDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text("コンプリート！"),
      content: const Text(
        "全てのキャラクターが最大レベルに到達しました！\nこれ以上ガチャを引くことはできません。\n\n次回のアップデートをお楽しみに！",
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text("OK"),
        ),
      ],
    );
  }
}
