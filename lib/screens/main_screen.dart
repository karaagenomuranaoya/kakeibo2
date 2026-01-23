import 'package:flutter/material.dart';
import '../repositories/settings_repository.dart';
import '../services/input_service.dart';
import '../repositories/gacha_repository.dart';
import '../widgets/app_drawer.dart';
import 'input_tab.dart';
import 'monthly_report_screen.dart';
import 'payment_screen.dart';
import 'graph_screen.dart'; // 追加
import 'gacha_screen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});
  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> with TickerProviderStateMixin {
  late TabController _tabController;
  final SettingsRepository _settingsRepository = SettingsRepository();
  final GachaRepository _gachaRepository = GachaRepository();
  final InputService _inputService = InputService();

  int _dataVersion = 0;
  int _gachaDataVersion = 0;
  bool _isTabBarVisible = true;
  bool _isGachaEnabled = true;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    // 初期化時はとりあえず長さ3で作成（ロード後に再設定されます）
    _tabController = TabController(length: 3, vsync: this);

    _gachaDataVersion = _inputService.gachaDataVersionNotifier.value;
    _inputService.gachaDataVersionNotifier.addListener(
      _onGachaDataVersionChanged,
    );
    _loadSettings();
    _gachaRepository.checkInitialBonus();
  }

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

    // ガチャONなら4タブ、OFFなら3タブ
    int length = _isGachaEnabled ? 5 : 4;

    // インデックスが範囲外にならないよう調整
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
    _inputService.gachaDataVersionNotifier.removeListener(
      _onGachaDataVersionChanged,
    );
    super.dispose();
  }

  void _onGachaDataVersionChanged() {
    setState(() {
      _gachaDataVersion = _inputService.gachaDataVersionNotifier.value;
    });
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
            // 1. 入力タブ
            InputTab(
              dataVersion: _dataVersion,
              inputService: _inputService,
              onTabBarVisibilityChanged: _setTabBarVisible,
            ),
            // 2. レポート(カレンダー)タブ
            MonthlyHistoryScreen(dataVersion: _dataVersion),

            // 3. 支払いタブ
            PaymentScreen(dataVersion: _dataVersion),

            // 4. グラフタブ (新規追加)
            GraphScreen(dataVersion: _dataVersion),

            // 5. コレクションタブ (設定ON時のみ)
            if (_isGachaEnabled) GachaScreen(dataVersion: _gachaDataVersion),
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
                  label: 'カレンダー',
                ),

                const NavigationDestination(
                  icon: Icon(Icons.payment_outlined),
                  selectedIcon: Icon(Icons.payment),
                  label: '支払い',
                ),
                // グラフタブのアイコンを追加
                const NavigationDestination(
                  icon: Icon(Icons.pie_chart_outline),
                  selectedIcon: Icon(Icons.pie_chart),
                  label: 'グラフ',
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
