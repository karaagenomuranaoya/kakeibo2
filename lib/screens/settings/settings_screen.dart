import 'package:flutter/material.dart';
import 'category_manage_screen.dart';
import 'developer_tips_screen.dart'; // 新規追加

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

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
          // 管理人の独り言 (旧: お気に入り設定の場所)
          ListTile(
            leading: const Icon(Icons.tips_and_updates, color: Colors.orange),
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
