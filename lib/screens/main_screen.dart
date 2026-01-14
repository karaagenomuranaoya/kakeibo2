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
  int _dataVersion = 0;
  bool _isTabBarVisible = true; // タブバーの表示状態

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);

    _tabController.addListener(() {
      if (!context.mounted) return;
      if (_tabController.indexIsChanging) {
        FocusScope.of(context).unfocus();
        // タブ切り替え時は必ずタブバーを表示状態に戻す
        if (!_isTabBarVisible) {
          setState(() {
            _isTabBarVisible = true;
          });
        }
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _refreshData() {
    setState(() {
      _dataVersion++;
    });
  }

  // InputTabから呼び出してタブバーを隠すための関数
  void _setTabBarVisible(bool visible) {
    if (_isTabBarVisible != visible) {
      setState(() {
        _isTabBarVisible = visible;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Quick Kakeibo')),
      drawer: AppDrawer(onDataChanged: _refreshData),
      // ▼▼ 変更点: OSキーボードが出ても画面サイズを変えない（押し上げない）設定 ▼▼
      // これにより、カスタムキーボードが常に画面最下部に固定され「どっしり」構えるようになります。
      resizeToAvoidBottomInset: false,

      body: GestureDetector(
        onTap: () {
          FocusScope.of(context).unfocus();
        },
        behavior: HitTestBehavior.translucent,
        child: TabBarView(
          controller: _tabController,
          physics: const ClampingScrollPhysics(),
          children: [
            // 1. 入力タブ
            InputTab(
              dataVersion: _dataVersion,
              onTabBarVisibilityChanged: _setTabBarVisible,
            ),

            // 2. レポートタブ
            const MonthlyHistoryScreen(),

            // 3. ガチャタブ
            const GachaScreen(),
          ],
        ),
      ),
      // タブバーの表示制御
      bottomNavigationBar: _isTabBarVisible
          ? Material(
              color: Colors.white,
              elevation: 10,
              child: SafeArea(
                child: TabBar(
                  controller: _tabController,
                  isScrollable: false,
                  indicatorColor: Colors.blue,
                  labelColor: Colors.blue,
                  unselectedLabelColor: Colors.grey,
                  onTap: (_) => FocusScope.of(context).unfocus(),
                  tabs: const [
                    Tab(icon: Icon(Icons.edit), text: '入力'),
                    Tab(icon: Icon(Icons.calendar_month), text: 'レポート'),
                    Tab(
                      icon: Icon(Icons.star, color: Colors.orange),
                      text: 'ガチャ',
                    ),
                  ],
                ),
              ),
            )
          : null,
    );
  }
}
