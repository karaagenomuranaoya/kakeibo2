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

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);

    _tabController.addListener(() {
      if (!context.mounted) return;
      // タブ移動時はキーボードを閉じる（これはUXとして自然なので残す）
      if (_tabController.indexIsChanging) {
        FocusScope.of(context).unfocus();
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Quick Kakeibo')),
      // onDrawerChangedの処理は不要になったため削除
      // ドロワーを開いたからといって、フォーカスをどうこうする必要はない。
      // なぜなら、そもそも「勝手にフォーカスが当たる機能」を捨てたから。
      drawer: AppDrawer(onDataChanged: _refreshData),

      // 画面全体のタップでキーボードを閉じるのは便利な機能なので残す
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
            InputTab(dataVersion: _dataVersion),

            // 2. レポートタブ
            const MonthlyHistoryScreen(),

            // 3. ガチャタブ
            const GachaScreen(),
          ],
        ),
      ),
      bottomNavigationBar: Material(
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
