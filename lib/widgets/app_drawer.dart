import 'package:flutter/material.dart';
import '../models/category_tag.dart';
import '../repositories/settings_repository.dart';
import '../screens/history_screen.dart';
import '../screens/settings/settings_screen.dart';

class AppDrawer extends StatefulWidget {
  // MainScreenから渡される更新用コールバック
  final VoidCallback? onDataChanged;

  const AppDrawer({super.key, this.onDataChanged});

  @override
  State<AppDrawer> createState() => _AppDrawerState();
}

class _AppDrawerState extends State<AppDrawer> {
  final SettingsRepository _settingsRepository = SettingsRepository();
  List<CategoryTag> _expenseList = [];
  List<CategoryTag> _cardList = [];

  @override
  void initState() {
    super.initState();
    _loadTags();
  }

  Future<void> _loadTags() async {
    final expenses = await _settingsRepository.loadExpenseTags();
    final cards = await _settingsRepository.loadCardTags();
    if (mounted) {
      setState(() {
        _expenseList = expenses;
        _cardList = cards;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: Column(
        children: [
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                const DrawerHeader(
                  decoration: BoxDecoration(color: Colors.blue),
                  child: Text(
                    'メニュー',
                    style: TextStyle(color: Colors.white, fontSize: 24),
                  ),
                ),

                // ▼▼ 月別レポートへのリンクを削除しました ▼▼
                _buildSectionHeader("費目別 履歴"),
                ..._expenseList.map(
                  (tag) => _buildFilterTile(context, tag, 'expense'),
                ),
                const Divider(),
                _buildSectionHeader("支払い方法別 履歴"),
                _buildFilterTile(
                  context,
                  CategoryTag(label: '現金', color: Colors.grey),
                  'payment',
                ),
                ..._cardList.map(
                  (tag) => _buildFilterTile(context, tag, 'payment'),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.settings),
            title: const Text('設定'),
            onTap: () async {
              Navigator.pop(context);
              await Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SettingsScreen()),
              );
              // 設定から戻ってきたらタグ情報を再読み込み
              _loadTags();
              // MainScreenにも通知
              widget.onDataChanged?.call();
            },
          ),
          SizedBox(height: MediaQuery.of(context).padding.bottom + 10),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 16, top: 10, bottom: 5),
      child: Text(
        title,
        style: const TextStyle(color: Colors.grey, fontSize: 12),
      ),
    );
  }

  Widget _buildFilterTile(
    BuildContext context,
    CategoryTag tag,
    String filterKey,
  ) {
    return ListTile(
      leading: Icon(
        filterKey == 'payment' ? Icons.payment : Icons.label,
        color: tag.color,
      ),
      title: Text(tag.label),
      onTap: () {
        Navigator.pop(context);
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => HistoryScreen(
              filterValue: tag.label,
              filterKey: filterKey,
              color: tag.color,
            ),
          ),
        );
      },
    );
  }
}
