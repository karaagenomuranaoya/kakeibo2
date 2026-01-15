import 'package:flutter/material.dart';
import '../../repositories/settings_repository.dart';
import 'category_manage_screen.dart';
import 'developer_tips_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final SettingsRepository _repository = SettingsRepository();
  bool _isGachaEnabled = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final enabled = await _repository.loadGachaEnabled();
    setState(() {
      _isGachaEnabled = enabled;
    });
  }

  Future<void> _toggleGacha(bool value) async {
    setState(() {
      _isGachaEnabled = value;
    });
    await _repository.saveGachaEnabled(value);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('設定')),
      body: ListView(
        children: [
          // カテゴリ管理
          ListTile(
            leading: const Icon(Icons.category),
            title: const Text('カテゴリ・カード管理'),
            subtitle: const Text('費目やカードの追加・編集・並び替え'),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const CategoryManageScreen(),
                ),
              );
            },
          ),
          const Divider(),

          // ▼▼ 追加: ガチャ機能のオンオフ ▼▼
          SwitchListTile(
            secondary: const Icon(Icons.star, color: Colors.orange),
            title: const Text('おまけガチャ機能'),
            subtitle: const Text('入力ごとのポイント付与とガチャタブの表示'),
            value: _isGachaEnabled,
            activeColor: Colors.orange,
            onChanged: _toggleGacha,
          ),
          const Divider(),

          // 管理人の独り言
          ListTile(
            leading: const Icon(Icons.tips_and_updates, color: Colors.blue),
            title: const Text('管理人の独り言 & Tips'),
            subtitle: const Text('使い方や開発の裏話など'),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const DeveloperTipsScreen(),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
