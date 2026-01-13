import 'package:flutter/material.dart';
import 'favorite_settings_screen.dart';
import 'category_manage_screen.dart'; // 追加

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
          // お気に入り設定 (既存のまま)
          ListTile(
            leading: const Icon(Icons.star_border),
            title: const Text('お気に入り設定 (廃止済み機能)'),
            subtitle: const Text('※現在はタブバー固定のため使用されません'),
            // もし完全廃止ならこのListTileごと消してもOKですが、
            // サイドバーで使うかもしれないので残しておきます
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const FavoriteSettingsScreen(),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
