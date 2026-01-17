import 'package:flutter/material.dart';
import 'gacha/gacha_game_tab.dart';
import 'gacha/bonus_tab.dart';

class GachaScreen extends StatelessWidget {
  const GachaScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const TabBar(
            labelColor: Colors.orange,
            unselectedLabelColor: Colors.grey,
            indicatorColor: Colors.orange,
            tabs: [
              Tab(text: 'ガチャ', icon: Icon(Icons.star)),
              Tab(text: 'ボーナス', icon: Icon(Icons.calendar_month)),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            GachaGameTab(), // 従来のガチャ画面
            BonusTab(), // 新しいボーナス画面
          ],
        ),
      ),
    );
  }
}
