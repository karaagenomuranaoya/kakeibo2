import 'package:flutter/material.dart';
import '../models/category_tag.dart';
import '../repositories/settings_repository.dart';
import '../widgets/app_drawer.dart';
import 'input_tab.dart';
import 'monthly_report_screen.dart';
import 'history_screen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});
  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> with TickerProviderStateMixin {
  final SettingsRepository _settingsRepository = SettingsRepository();
  List<Map<String, dynamic>> _favoriteTabs = [];
  bool _isLoading = true;
  TabController? _tabController;

  @override
  void initState() {
    super.initState();
    _loadFavorites();
  }

  @override
  void dispose() {
    _tabController?.dispose();
    super.dispose();
  }

  Future<void> _loadFavorites() async {
    final favStrings = await _settingsRepository.loadFavorites();
    final List<Map<String, dynamic>> items = [];

    for (var str in favStrings) {
      final parts = str.split(':');
      if (parts.length != 2) continue;
      final type = parts[0];
      final label = parts[1];

      CategoryTag? tag;
      if (type == 'expense') {
        if (label == 'デフォルト') {
          tag = const CategoryTag('デフォルト', Colors.blueGrey);
        } else {
          tag = expenseTags.firstWhere(
            (t) => t.label == label,
            orElse: () => CategoryTag(label, Colors.grey),
          );
        }
      } else {
        if (label == 'デフォルト') {
          tag = const CategoryTag('デフォルト', Colors.grey);
        } else {
          tag = paymentTags.firstWhere(
            (t) => t.label == label,
            orElse: () => CategoryTag(label, Colors.grey),
          );
        }
      }

      items.add({'label': tag.label, 'type': type, 'color': tag.color});
    }

    if (mounted) {
      setState(() {
        _favoriteTabs = items;
        _isLoading = false;
        final totalTabs = 2 + _favoriteTabs.length;
        int initialIndex = _tabController?.index ?? 0;
        if (initialIndex >= totalTabs) initialIndex = 0;

        _tabController?.dispose();
        _tabController = TabController(
          length: totalTabs,
          vsync: this,
          initialIndex: initialIndex,
        );
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading || _tabController == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Quick Kakeibo')),
      drawer: AppDrawer(onFavoritesUpdated: () => _loadFavorites()),
      body: TabBarView(
        controller: _tabController,
        children: [
          const InputTab(),
          const MonthlyHistoryScreen(),
          ..._favoriteTabs.map((fav) {
            return HistoryScreen(
              filterValue: fav['label'],
              filterKey: fav['type'],
              color: fav['color'],
            );
          }),
        ],
      ),
      bottomNavigationBar: Material(
        color: Colors.white,
        elevation: 10,
        child: SafeArea(
          child: TabBar(
            controller: _tabController,
            isScrollable: true,
            tabAlignment: TabAlignment.start,
            indicatorColor: Colors.blue,
            labelColor: Colors.blue,
            unselectedLabelColor: Colors.grey,
            tabs: [
              const Tab(icon: Icon(Icons.edit), text: '入力'),
              const Tab(icon: Icon(Icons.calendar_month), text: 'レポート'),
              ..._favoriteTabs.map((fav) {
                return Tab(
                  icon: Icon(
                    fav['type'] == 'payment'
                        ? Icons.payment
                        : Icons.local_offer,
                    color: fav['color'],
                  ),
                  text: fav['label'],
                );
              }),
            ],
          ),
        ),
      ),
    );
  }
}
