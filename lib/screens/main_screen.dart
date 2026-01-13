import 'package:flutter/material.dart';
import '../widgets/app_drawer.dart';
import 'input_tab.dart';
import 'monthly_report_screen.dart';
import 'gacha_screen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});
  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    // タブは固定で3つ（入力、レポート、ガチャ）
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Quick Kakeibo')),
      drawer: const AppDrawer(), // お気に入り更新のコールバックは不要になったので引数なし
      body: TabBarView(
        controller: _tabController,
        // スワイプで移動できないようにしたければ physics: NeverScrollableScrollPhysics() を追加
        children: const [
          // 1. 入力タブ
          InputTab(),

          // 2. レポートタブ
          MonthlyHistoryScreen(),

          // 3. ガチャタブ
          GachaScreen(),
        ],
      ),
      bottomNavigationBar: Material(
        color: Colors.white,
        elevation: 10,
        child: SafeArea(
          child: TabBar(
            controller: _tabController,
            isScrollable: false, // falseにすると等間隔に広がる
            indicatorColor: Colors.blue,
            labelColor: Colors.blue,
            unselectedLabelColor: Colors.grey,
            tabs: const [
              Tab(
                icon: Icon(Icons.edit),
                text: '入力',
              ),
              Tab(
                icon: Icon(Icons.calendar_month),
                text: 'レポート',
              ),
              Tab(
                icon: Icon(Icons.star, color: Colors.orange),
                text: 'ガチャ',
              ),
            ],
          ),
        ),
      ),
    );
  }
}
