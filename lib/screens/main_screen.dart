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
  // データ更新を管理するためのバージョン番号
  int _dataVersion = 0;

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

  // 設定から戻ってきた時などにデータを更新する
  void _refreshData() {
    setState(() {
      _dataVersion++;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Quick Kakeibo')),
      // 設定変更後にデータを更新するためのコールバックを渡す
      drawer: AppDrawer(onDataChanged: _refreshData),
      body: TabBarView(
        controller: _tabController,
        // スワイプで移動できないようにしたければ physics: NeverScrollableScrollPhysics() を追加
        children: [
          // 1. 入力タブ
          // dataVersionを渡すことで、変更があったときに再読み込みさせる
          InputTab(dataVersion: _dataVersion),

          // 2. レポートタブ
          const MonthlyHistoryScreen(),

          // 3. ガチャタブ
          const GachaScreen(),
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
