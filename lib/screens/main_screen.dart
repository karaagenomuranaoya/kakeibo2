import 'package:flutter/material.dart';
import '../repositories/settings_repository.dart';
// ▼▼ 追加: リポジトリのインポート ▼▼
import '../repositories/gacha_repository.dart';
import '../widgets/app_drawer.dart';
import 'input_tab.dart';
import 'monthly_report_screen.dart';
import 'gacha_screen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});
  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> with TickerProviderStateMixin {
  late TabController _tabController;
  final SettingsRepository _settingsRepository = SettingsRepository();
  // ▼▼ 追加 ▼▼
  final GachaRepository _gachaRepository = GachaRepository();

  int _dataVersion = 0;
  bool _isTabBarVisible = true;
  bool _isGachaEnabled = true;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadSettings();
    // ▼▼ 追加: 初回ボーナスチェックを実行 ▼▼
    _gachaRepository.checkInitialBonus();
  }

  // ... 以下、変更なし ...
  Future<void> _loadSettings() async {
    try {
      final enabled = await _settingsRepository.loadGachaEnabled();
      if (mounted) {
        setState(() {
          _isGachaEnabled = enabled;
          _isLoading = false;
          _setupTabController();
        });
      }
    } catch (e) {
      debugPrint('Settings load error: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _setupTabController() {
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

  void _refreshData() async {
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
            InputTab(
              dataVersion: _dataVersion,
              onTabBarVisibilityChanged: _setTabBarVisible,
            ),
            const MonthlyHistoryScreen(),
            // ▼▼ 修正: ガチャ画面に dataVersion を渡す ▼▼
            if (_isGachaEnabled) GachaScreen(dataVersion: _dataVersion),
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
