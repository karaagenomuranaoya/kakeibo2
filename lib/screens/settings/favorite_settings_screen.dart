import 'package:flutter/material.dart';
import '../../models/category_tag.dart';
import '../../repositories/settings_repository.dart';

class FavoriteSettingsScreen extends StatefulWidget {
  const FavoriteSettingsScreen({super.key});

  @override
  State<FavoriteSettingsScreen> createState() => _FavoriteSettingsScreenState();
}

class _FavoriteSettingsScreenState extends State<FavoriteSettingsScreen> {
  final SettingsRepository _repository = SettingsRepository();
  List<String> _currentFavorites = [];

  // 動的リスト
  List<CategoryTag> _expenseList = [];
  List<CategoryTag> _cardList = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final list = await _repository.loadFavorites();
    final expenses = await _repository.loadExpenseTags();
    final cards = await _repository.loadCardTags();

    setState(() {
      _currentFavorites = List<String>.from(list);
      _expenseList = expenses;
      _cardList = cards;
    });
  }

  Future<void> _toggleFavorite(String key) async {
    setState(() {
      if (_currentFavorites.contains(key)) {
        _currentFavorites.remove(key);
      } else {
        _currentFavorites.add(key);
      }
    });
    await _repository.saveFavorites(_currentFavorites);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('お気に入り設定')),
      body: ListView(
        padding: const EdgeInsets.only(bottom: 30),
        children: [
          _buildSectionHeader('費目ショートカット'),
          // const を削除
          _buildCheckTile(
              CategoryTag(label: 'デフォルト', color: Colors.blueGrey), 'expense'),
          // 動的リストを展開
          ..._expenseList.map((tag) => _buildCheckTile(tag, 'expense')),

          const Divider(),

          _buildSectionHeader('支払い方法ショートカット'),
          _buildCheckTile(
              CategoryTag(label: 'デフォルト', color: Colors.grey), 'payment'),
          _buildCheckTile(
              CategoryTag(label: '現金', color: Colors.grey), 'payment'),
          ..._cardList.map((tag) => _buildCheckTile(tag, 'payment')),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 5),
      child: Text(
        title,
        style:
            TextStyle(color: Colors.blue.shade800, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildCheckTile(CategoryTag tag, String type) {
    final key = '$type:${tag.label}';
    final isChecked = _currentFavorites.contains(key);

    return CheckboxListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
      title: Row(
        children: [
          Icon(
            type == 'payment' ? Icons.payment : Icons.label,
            color: tag.color,
            size: 20,
          ),
          const SizedBox(width: 10),
          Text(tag.label),
        ],
      ),
      value: isChecked,
      onChanged: (bool? value) => _toggleFavorite(key),
      activeColor: Colors.blue,
    );
  }
}
