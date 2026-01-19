import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

// アプリ内のクラスをインポート（パスは適宜調整してください）
import 'package:atsumeru_kakeibo/models/gacha_item.dart';
import 'package:atsumeru_kakeibo/repositories/gacha_repository.dart';

void main() {
  // テスト用のダミーアイテム作成
  const testItem = GachaItem(
    id: 'test_monster_001',
    rarity: 1,
    weight: 100,
    iconData: Icons.star,
    baseName: 'スライム',
    descriptions: ['説明1', '説明2', '説明3'],
  );

  group('GachaItem Model Logic Tests', () {
    test('所持数に応じたステージ（レベル）計算が正しいか', () {
      // 未所持
      expect(testItem.getStage(0), 0);
      // 1個所持 -> Lv1
      expect(testItem.getStage(1), 1);
      // 5個所持 -> Lv5
      expect(testItem.getStage(5), 5);
      // 10個所持 -> Lv10 (カンスト)
      expect(testItem.getStage(10), 10);
      // 11個所持 -> Lv10 (表示用ステージは10で止まる仕様)
      expect(testItem.getStage(11), 10);
      expect(testItem.getStage(100), 10);
    });

    test('所持数に応じて名前（称号）が正しく付くか', () {
      // 未所持
      expect(testItem.getName(0), '???');

      // Lv1: 迷子の
      expect(testItem.getName(1), contains('迷子の'));
      expect(testItem.getName(1), contains('スライム'));

      // Lv5: 熟練の
      expect(testItem.getName(5), contains('熟練の'));

      // Lv10: 伝説の
      expect(testItem.getName(10), contains('伝説の'));
    });

    test('所持数に応じて色が正しく返るか', () {
      // 未所持 -> グレー
      expect(testItem.getColor(0), Colors.grey);

      // Lv1 -> 定義された色 (Colors.greyだけどstageColors[0]の方)
      // Lv10 -> Colors.amber
      expect(testItem.getColor(10), Colors.amber);

      // Lv11以上（殿堂入り） -> 固定色ではなく計算された色が返るはず
      final colorLv11 = testItem.getColor(11);
      final colorLv12 = testItem.getColor(12);

      // 殿堂入り後は色が変化していることを確認
      expect(colorLv11, isNot(colorLv12));
      expect(colorLv11, isNot(Colors.grey));
    });
  });

  group('GachaRepository Integration Tests', () {
    late GachaRepository repository;

    setUp(() async {
      // SharedPreferencesのモック初期化（空のデータで開始）
      SharedPreferences.setMockInitialValues({});
      repository = GachaRepository();
    });

    test('アイテムをアンロック(獲得)するとカウントが増えるか', () async {
      // 初期状態は0
      var counts = await repository.getItemCounts();
      expect(counts['test_monster_001'], null); // または 0

      // 1回獲得処理を実行 (IDは実在するもの、あるいはモックで通るもの)
      // ※ここではリポジトリのロジック確認のため、任意のIDでテストします
      final newCount = await repository.unlockItem('test_monster_001');

      expect(newCount, 1);

      // 保存されているか確認
      counts = await repository.getItemCounts();
      expect(counts['test_monster_001'], 1);
    });

    test('クレジット(チケット)の消費が正しく行われるか', () async {
      // 初期クレジットをセット (setMockInitialValuesで直接値を注入)
      SharedPreferences.setMockInitialValues({'gacha_credits': 10});

      // 現在のクレジット確認
      expect(await repository.getCredits(), 10);

      // 3枚消費してみる
      final success = await repository.consumeCredits(3);

      expect(success, true);
      expect(await repository.getCredits(), 7); // 10 - 3 = 7
    });

    test('クレジット不足時は消費できないこと', () async {
      SharedPreferences.setMockInitialValues({'gacha_credits': 2});

      // 3枚消費しようとする
      final success = await repository.consumeCredits(3);

      expect(success, false);
      expect(await repository.getCredits(), 2); // 減っていないこと
    });
  });
}

//flutter test test/gacha_logic_test.dart
