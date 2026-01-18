import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_application_1/repositories/gacha_repository.dart';
import 'package:flutter_application_1/data/gacha_data.dart';

void main() {
  setUp(() {
    // 毎回データをリセット
    SharedPreferences.setMockInitialValues({});
  });

  group('ガチャシステムのロジックテスト', () {
    test('クレジット（チケット）の追加と消費ができるか', () async {
      final repo = GachaRepository();

      // 初期値は0（またはボーナスで3だが、mockなので0スタート）
      expect(await repo.getCredits(), 0);

      // 1枚追加
      await repo.addCredit();
      expect(await repo.getCredits(), 1);

      // 1枚消費
      final success = await repo.consumeCredits(1);
      expect(success, true);
      expect(await repo.getCredits(), 0);

      // 足りない時に消費しようとするとfalse
      final fail = await repo.consumeCredits(1);
      expect(fail, false);
    });

    test('アイテムを獲得するとカウントが増えるか', () async {
      final repo = GachaRepository();
      // 最初のモンスターID（例: 'm001'）を使う
      final targetId = GachaData.monsters.first.id;

      // まだ持っていない
      var counts = await repo.getItemCounts();
      expect(counts[targetId] ?? 0, 0);

      // 1回獲得
      await repo.unlockItem(targetId);

      // 1個持っているはず
      counts = await repo.getItemCounts();
      expect(counts[targetId], 1);
    });

    test('【重要】Lv10未満のキャラがいる場合、Lv10（カンスト）のキャラは排出されない', () async {
      final repo = GachaRepository();
      final monsters = GachaData.monsters;

      // テスト用に、最初の1体以外をすべてLv10にする
      // (最初の1体だけが排出候補になるはず)
      final targetItem = monsters[0]; // これだけLv0
      final maxedItem = monsters[1]; // これはLv10にする

      // 無理やりリポジトリ経由で連打してLv10にするのは大変なので
      // SharedPreferencesに直接書き込んで状態を作る（裏技）
      final Map<String, int> fakeData = {};
      for (var m in monsters) {
        if (m.id == targetItem.id) continue; // ターゲットは0のまま
        fakeData[m.id] = 10; // それ以外はLv10
      }

      // 保存処理をエミュレート
      // (SharedPreferencesにJSON文字列として保存する)
      // 注意: GachaRepositoryの内部キーを知っている必要がある
      // '_countsKey' は private だが文字列は 'gacha_counts_v2' とわかっているとする
      // ※ 本来はRepositoryにデバッグ用メソッドを作るのが行儀が良いが、テストでは直接埋め込むことも多い
      final prefs = await SharedPreferences.getInstance();
      // JSONエンコードが必要なため、簡易的な書き込み
      // ここではGachaRepositoryの_loadCountsが読める形式で保存
      // キー名のマッピング: {"m001": 10, ...}
      String jsonString = '{';
      fakeData.forEach((key, value) {
        jsonString += '"$key": $value,';
      });
      // 最後のカンマを取る処理（簡易実装）
      jsonString = jsonString.substring(0, jsonString.length - 1) + '}';

      await prefs.setString('gacha_counts_v2', jsonString);

      // テスト実行：100回引いても、必ず「targetItem」が出るはず
      // なぜなら他は全員Lv10で排出対象外だから。
      for (int i = 0; i < 50; i++) {
        final result = await repo.drawItem();
        expect(result, isNotNull);
        expect(result!.id, targetItem.id, reason: 'Lv10未満のキャラが優先されるはず');
      }
    });

    test('【重要】全員Lv10になったら、殿堂入りモードで全員が排出対象になる', () async {
      final repo = GachaRepository();
      final monsters = GachaData.monsters;

      // 全員Lv10にするデータを作る
      String jsonContent = '{';
      for (int i = 0; i < monsters.length; i++) {
        jsonContent += '"${monsters[i].id}": 10';
        if (i < monsters.length - 1) jsonContent += ',';
      }
      jsonContent += '}';

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('gacha_counts_v2', jsonContent);

      // この状態で引く
      // 誰が出るかはランダムだが、「nullではない（候補なしにならない）」ことを確認
      // かつ、Lv10のキャラが出てくることを確認
      final result = await repo.drawItem();

      expect(result, isNotNull, reason: '殿堂入りモードなら引けるはず');

      // 出たアイテムの所持数を確認（10個持っているはず）
      final counts = await repo.getItemCounts();
      expect(counts[result!.id], 10);
    });
  });
}
//flutter test test/gacha_repository_test.dart