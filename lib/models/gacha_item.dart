class GachaItem {
  final String id;
  final int rarity;
  final int weight;

  // 第1形態
  final String name1;
  final String description1;
  // 第2形態
  final String name2;
  final String description2;
  // 第3形態 (最終)
  final String name3;
  final String description3;

  const GachaItem({
    required this.id,
    required this.rarity,
    required this.weight,
    required this.name1,
    required this.description1,
    required this.name2,
    required this.description2,
    required this.name3,
    required this.description3,
  });

  // 現在のステージを判定 (1, 2, 3)
  int getStage(int count) {
    if (count >= 10) return 3; // 10枚以上で最終形態
    if (count >= 5) return 2; // 5枚以上で第2形態
    return 1; // それ以外は初期
  }

  // 画像パス
  String getImagePath(int count) {
    final stage = getStage(count);
    return 'assets/images/gacha/$id-$stage.png';
  }

  // 名前
  String getName(int count) {
    final stage = getStage(count);
    if (stage == 3) return name3;
    if (stage == 2) return name2;
    return name1;
  }

  // 説明文
  String getDescription(int count) {
    final stage = getStage(count);
    if (stage == 3) return description3;
    if (stage == 2) return description2;
    return description1;
  }

  factory GachaItem.fromJson(Map<String, dynamic> json) {
    return GachaItem(
      id: json['id'] as String,
      rarity: json['rarity'] as int? ?? 1,
      weight: json['weight'] as int? ?? 10,
      name1: json['name_1'] as String? ?? '名前未設定',
      description1: json['description_1'] as String? ?? '',
      name2: json['name_2'] as String? ?? '名前未設定(進化)',
      description2: json['description_2'] as String? ?? '',
      // ▼▼ 追加: 第3形態の読み込み（なければ第2形態と同じにする） ▼▼
      name3:
          json['name_3'] as String? ?? json['name_2'] as String? ?? '名前未設定(最終)',
      description3:
          json['description_3'] as String? ??
          json['description_2'] as String? ??
          '',
    );
  }
}
