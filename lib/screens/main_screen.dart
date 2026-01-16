import 'package:flutter/material.dart';
import '../repositories/settings_repository.dart';
import '../widgets/app_drawer.dart';
import 'input_tab.dart';
import 'monthly_report_screen.dart';
import 'gacha_screen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});
  @override
  State<MainScreen> createState() => _MainScreenState();
}

// ▼▼ 修正箇所: SingleTickerProviderStateMixin を TickerProviderStateMixin に変更 ▼▼
class _MainScreenState extends State<MainScreen> with TickerProviderStateMixin {
  late TabController _tabController;
  final SettingsRepository _settingsRepository = SettingsRepository();

  int _dataVersion = 0;
  bool _isTabBarVisible = true;
  bool _isGachaEnabled = true; // ガチャの有効状態（デフォルトON）
  bool _isLoading = true; // 設定読み込み中フラグ

  @override
  void initState() {
    super.initState();
    // 初期化時は仮でコントローラーを作成し、すぐに設定を読み込む
    _tabController = TabController(length: 3, vsync: this);
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    try {
      final enabled = await _settingsRepository.loadGachaEnabled();
      if (mounted) {
        setState(() {
          _isGachaEnabled = enabled;
          _isLoading = false;
          // 設定に合わせてコントローラーを作り直す
          _setupTabController();
        });
      }
    } catch (e) {
      debugPrint('Settings load error: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
          // エラー時もデフォルト設定で続行
        });
      }
    }
  }

  void _setupTabController() {
    // 現在のインデックスを保持（範囲外になる場合は0に戻す）
    int newIndex = _tabController.index;
    int length = _isGachaEnabled ? 3 : 2;
    if (newIndex >= length) newIndex = 0;

    _tabController.dispose();
    _tabController = TabController(
      length: length,
      vsync: this,
      initialIndex: newIndex,
    );

    _tabController.addListener(() {
      if (!context.mounted) return;
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

  // ドロワーや設定画面からの戻りでデータをリフレッシュ
  void _refreshData() async {
    // ガチャ設定が変わっている可能性があるので再読み込み
    await _loadSettings();
    setState(() {
      _dataVersion++;
    });
  }

  void _setTabBarVisible(bool visible) {
    if (_isTabBarVisible != visible) {
      setState(() {
        _isTabBarVisible = visible;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // 読み込み中はローディングを表示
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'あつめる家計簿',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
      drawer: AppDrawer(onDataChanged: _refreshData),
      resizeToAvoidBottomInset: false,
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        behavior: HitTestBehavior.translucent,
        child: TabBarView(
          controller: _tabController,
          physics: const NeverScrollableScrollPhysics(),
          children: [
            // 1. 入力タブ
            InputTab(
              dataVersion: _dataVersion,
              onTabBarVisibilityChanged: _setTabBarVisible,
            ),

            // 2. レポートタブ
            const MonthlyHistoryScreen(),

            // 3. ガチャタブ (有効な場合のみ)
            if (_isGachaEnabled) const GachaScreen(),
          ],
        ),
      ),
      bottomNavigationBar: _isTabBarVisible
          ? NavigationBar(
              selectedIndex: _tabController.index,
              onDestinationSelected: (index) {
                _tabController.animateTo(index);
                setState(() {});
              },
              destinations: [
                const NavigationDestination(
                  icon: Icon(Icons.edit_outlined),
                  selectedIcon: Icon(Icons.edit),
                  label: '入力',
                ),
                const NavigationDestination(
                  icon: Icon(Icons.calendar_month_outlined),
                  selectedIcon: Icon(Icons.calendar_month),
                  label: 'レポート',
                ),
                // ガチャが有効な場合のみ表示
                if (_isGachaEnabled)
                  const NavigationDestination(
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
