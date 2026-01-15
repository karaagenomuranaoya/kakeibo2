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
  bool _isCategoryLongPressEnabled = true;
  // ▼▼ 追加: 入力画面でのカード表示設定 ▼▼
  bool _showCardOnInput = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final gacha = await _repository.loadGachaEnabled();
    final catLongPress = await _repository.loadCategoryLongPressEnabled();
    final showCard = await _repository.loadShowCardOnInput(); // 追加
    setState(() {
      _isGachaEnabled = gacha;
      _isCategoryLongPressEnabled = catLongPress;
      _showCardOnInput = showCard;
    });
  }

  Future<void> _toggleGacha(bool value) async {
    setState(() {
      _isGachaEnabled = value;
    });
    await _repository.saveGachaEnabled(value);
  }

  Future<void> _toggleCategoryLongPress(bool value) async {
    setState(() {
      _isCategoryLongPressEnabled = value;
    });
    await _repository.saveCategoryLongPressEnabled(value);
  }

  // ▼▼ 追加: 設定切り替え処理 ▼▼
  Future<void> _toggleShowCardOnInput(bool value) async {
    setState(() {
      _showCardOnInput = value;
    });
    await _repository.saveShowCardOnInput(value);
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

          // カテゴリ長押し設定
          SwitchListTile(
            secondary: const Icon(Icons.touch_app, color: Colors.blueGrey),
            title: const Text('カテゴリ長押しで履歴へ'),
            subtitle: const Text('入力画面のカテゴリを長押しして詳細へ移動'),
            value: _isCategoryLongPressEnabled,
            activeColor: Colors.blue,
            onChanged: _toggleCategoryLongPress,
          ),
          const Divider(),

          // ▼▼ 追加: カード表示設定 ▼▼
          SwitchListTile(
            secondary: const Icon(Icons.credit_card, color: Colors.purple),
            title: const Text('入力画面にカード選択を表示'),
            subtitle: const Text('オフにしても履歴データは消えません。\n入力画面から隠してシンプルにする機能です。'),
            isThreeLine: true,
            value: _showCardOnInput,
            activeColor: Colors.purple,
            onChanged: _toggleShowCardOnInput,
          ),
          const Divider(),

          // ガチャ機能のオンオフ
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
