import 'package:flutter/material.dart';
import 'gacha/gacha_game_tab.dart';

class GachaScreen extends StatelessWidget {
  const GachaScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'コレクション',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            letterSpacing: 1.2, // 文字間隔を広げて高級感を出す
          ),
        ),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
      ),
      body: const GachaGameTab(),
    );
  }
}
