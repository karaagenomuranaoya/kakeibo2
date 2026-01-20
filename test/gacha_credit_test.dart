import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:atsumeru_kakeibo/repositories/gacha_repository.dart';

void main() {
  late GachaRepository repository;

  setUp(() {
    // テストのたびにデータを空っぽにする
    SharedPreferences.setMockInitialValues({});
    repository = GachaRepository();
  });

  group('ガチャチケット獲得ロジックのテスト', () {
    test('1回追加すると、正しく増えて「追加成功(true)」が返る', () async {
      // 実行
      final (total, added) = await repository.addCredit();

      // 検証
      expect(added, isTrue, reason: '最初は必ずtrueが返るはず');
      expect(total, 1, reason: '所持数が0→1になるはず');
    });

    test('5回連続で追加でき、6回目は「追加失敗(false)」になる（1日上限テスト）', () async {
      // 5回まわす
      for (int i = 1; i <= 5; i++) {
        final (total, added) = await repository.addCredit();
        expect(added, isTrue, reason: '$i回目は追加できるはず');
        expect(total, i, reason: '所持数が$iになるはず');
      }

      // 運命の6回目
      final (limitTotal, limitAdded) = await repository.addCredit();

      expect(limitAdded, isFalse, reason: '6回目は制限にかかってfalseになるはず');
      expect(limitTotal, 5, reason: '所持数は5から増えないはず');
    });

    test('「日付が変わった」と認識されれば、回数がリセットされてまた追加できる', () async {
      // 状況再現:
      // 「今日のカウントは5回(満タン)」だが、
      // 「最後に保存した日付は昔(2000年)」という矛盾したデータをセットする
      // → これでaddCreditを呼べば、ロジックが正しければ「日付変更」とみなしてリセットするはず
      SharedPreferences.setMockInitialValues({
        'gacha_daily_count': 5,
        'gacha_credits': 10,
        'gacha_last_input_date': '2000-1-1',
      });

      // 実行
      final (total, added) = await repository.addCredit();

      // 検証
      expect(added, isTrue, reason: '日付が変わっていれば、カウント5でも追加できるはず');
      expect(total, 11, reason: '所持数は10→11になるはず');

      final prefs = await SharedPreferences.getInstance();
      expect(
        prefs.getInt('gacha_daily_count'),
        1,
        reason: '今日のカウントは1にリセットされているはず',
      );
    });
  });
}

//flutter test test/gacha_credit_test.dart
