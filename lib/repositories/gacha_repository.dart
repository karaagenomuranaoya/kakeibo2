import 'package:shared_preferences/shared_preferences.dart';

class GachaItem {
  final String id;
  final String imagePath;
  final String name;
  final String description;

  const GachaItem({
    required this.id,
    required this.imagePath,
    required this.name,
    required this.description,
  });
}

class GachaRepository {
  static const String _creditKey = 'gacha_credits';
  static const String _collectionKey = 'gacha_collection';

  // アイテムデータ（説明は適当に生成）
  final List<GachaItem> items = [
    const GachaItem(
      id: '1',
      imagePath: 'assets/images/image1.png',
      name: '伝説の家計簿',
      description: 'これを持っているだけで、なぜか無駄遣いが減るという伝説の書物。',
    ),
    const GachaItem(
      id: '2',
      imagePath: 'assets/images/image2.png',
      name: '黄金の貯金箱',
      description: '500円玉を入れると、中で増えている気がする不思議な貯金箱。',
    ),
    const GachaItem(
      id: '3',
      imagePath: 'assets/images/image3.png',
      name: '古代のレシート',
      description: '紀元前のスーパーマーケットのレシート。卵が意外と高い。',
    ),
  ];

  // クレジットを取得
  Future<int> getCredits() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_creditKey) ?? 0;
  }

  // クレジットを加算 (1回入力で1ポイント)
  Future<int> addCredit() async {
    final prefs = await SharedPreferences.getInstance();
    int current = prefs.getInt(_creditKey) ?? 0;
    current++;
    await prefs.setInt(_creditKey, current);
    return current;
  }

  // クレジットを消費 (ガチャ1回で3ポイント)
  Future<bool> consumeCredits(int amount) async {
    final prefs = await SharedPreferences.getInstance();
    int current = prefs.getInt(_creditKey) ?? 0;
    if (current >= amount) {
      await prefs.setInt(_creditKey, current - amount);
      return true;
    }
    return false;
  }

  // 獲得済みアイテムIDリストを取得
  Future<List<String>> getCollection() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList(_collectionKey) ?? [];
  }

  // アイテムを獲得済みに追加
  Future<void> unlockItem(String id) async {
    final prefs = await SharedPreferences.getInstance();
    final List<String> current = prefs.getStringList(_collectionKey) ?? [];
    if (!current.contains(id)) {
      current.add(id);
      await prefs.setStringList(_collectionKey, current);
    }
  }
}
