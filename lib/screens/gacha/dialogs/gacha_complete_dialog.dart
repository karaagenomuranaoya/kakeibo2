import 'package:flutter/material.dart';

class GachaCompleteDialog extends StatelessWidget {
  const GachaCompleteDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text(
        "🎉 コンプリート＆殿堂入り！",
        style: TextStyle(fontWeight: FontWeight.bold, color: Colors.orange),
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            Text("おめでとうございます！\n全てのキャラクターが最大レベル(Lv.10)に到達しました。"),
            SizedBox(height: 16),
            Text("【殿堂入りモード解禁】", style: TextStyle(fontWeight: FontWeight.bold)),
            Text(
              "これからもチケットを使ってガチャを回すことができます。\n\nLv.11以降はフレーバーテキストはありませんが、キャラクターの色が無限に変化します。\nあなただけのカラーを集めてみてください！",
              style: TextStyle(fontSize: 13, color: Colors.black87),
            ),
            SizedBox(height: 12),
            Text(
              "※将来新しいキャラクターが追加された場合は、そのキャラたちをLv.10にするまで殿堂入りモードは一時お休みになります。",
              style: TextStyle(fontSize: 11, color: Colors.grey),
            ),
          ],
        ),
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
