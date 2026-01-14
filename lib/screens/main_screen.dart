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
  bool _isTabBarVisible = true; // タブバーの表示状態管理

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);

    _tabController.addListener(() {
      if (!context.mounted) return;
      // タブ切り替え開始時にキーボードを閉じてタブバーを再表示
      if (_tabController.indexIsChanging) {
        FocusScope.of(context).unfocus();
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

  // ドロワーや設定画面からの戻りでデータをリフレッシュさせるためのバージョン管理
  void _refreshData() {
    setState(() {
      _dataVersion++;
    });
  }

  // InputTabから呼ばれる、タブバー表示切替コールバック
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
      appBar: AppBar(
        title: const Text(
          'Quick Kakeibo',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
      drawer: AppDrawer(onDataChanged: _refreshData),

      // カスタムキーボードが下から出てくるときに、
      // Scaffoldのbodyをリサイズせず（押し上げず）、上に重ねて表示する設定。
      // これにより、画面全体のレイアウト崩れを防ぎます。
      resizeToAvoidBottomInset: false,

      body: GestureDetector(
        onTap: () {
          // 画面背景タップでフォーカスを外す
          FocusScope.of(context).unfocus();
        },
        behavior: HitTestBehavior.translucent,
        child: TabBarView(
          controller: _tabController,
          // スワイプでのタブ切り替えを無効化（誤操作防止 & キーボード制御簡易化のため）
          // 必要であれば physics: const ClampingScrollPhysics() に戻してください
          physics: const NeverScrollableScrollPhysics(),
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
      // _isTabBarVisible が false のときは null にして非表示にする
      bottomNavigationBar: _isTabBarVisible
          ? NavigationBar(
              selectedIndex: _tabController.index,
              onDestinationSelected: (index) {
                _tabController.animateTo(index);
                setState(() {}); // NavigationBarの表示更新用
              },
              destinations: const [
                NavigationDestination(
                  icon: Icon(Icons.edit_outlined),
                  selectedIcon: Icon(Icons.edit),
                  label: '入力',
                ),
                NavigationDestination(
                  icon: Icon(Icons.calendar_month_outlined),
                  selectedIcon: Icon(Icons.calendar_month),
                  label: 'レポート',
                ),
                NavigationDestination(
                  icon: Icon(Icons.star_outline, color: Colors.orange),
                  selectedIcon: Icon(Icons.star, color: Colors.orange),
                  label: 'ガチャ',
                ),
              ],
            )
          : null,
    );
  }
}
