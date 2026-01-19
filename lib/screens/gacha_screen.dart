import 'package:flutter/material.dart';
import 'gacha/gacha_game_tab.dart';

class GachaScreen extends StatelessWidget {
  // ▼▼ 追加: 更新通知を受け取る変数 ▼▼
  final int dataVersion;

  // ▼▼ 修正: コンストラクタで dataVersion を受け取るように変更 ▼▼
  const GachaScreen({super.key, this.dataVersion = 0});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'コレクション',
          style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.2),
        ),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
      ),
      // ▼▼ 修正: 中身のタブにも dataVersion を渡す ▼▼
      body: GachaGameTab(dataVersion: dataVersion),
    );
  }
}
