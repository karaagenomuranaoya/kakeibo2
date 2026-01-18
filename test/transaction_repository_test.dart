import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:atsumeru_kakeibo/repositories/transaction_repository.dart';
import 'package:atsumeru_kakeibo/models/transaction_item.dart';

void main() {
  setUp(() async {
    // 1. ディスク（SharedPreferences）を空にする
    SharedPreferences.setMockInitialValues({});

    // 2. 【ここが修正ポイント】
    // メモリ（シングルトンのキャッシュ）も空にするために、
    // 空になったディスクから強制的に読み込み直させる
    final repo = TransactionRepository();
    await repo.getAllTransactions(forceReload: true);
  });

  test('データを追加して、正しく保存・読み込みができるか', () async {
    final repo = TransactionRepository();

    final newItem = TransactionItem(
      amount: 1500,
      expense: '食費',
      payment: '現金',
      date: DateTime(2025, 1, 1),
      memo: 'ラーメン',
    );

    await repo.addTransaction(newItem);

    final list = await repo.getAllTransactions(forceReload: true);

    expect(list.length, 1, reason: 'データが1件あるはず');
    expect(list.first.amount, 1500);
    expect(list.first.memo, 'ラーメン');
  });

  test('削除ができるか', () async {
    final repo = TransactionRepository();

    // データを1つ追加
    final item = TransactionItem(
      amount: 500,
      expense: 'おやつ',
      payment: '現金',
      date: DateTime.now(),
    );
    await repo.addTransaction(item);

    // 追加直後の確認
    var list = await repo.getAllTransactions();
    // ここで前回のエラー（2件になっていた）が解消され、1件になるはず
    expect(list.length, 1, reason: '初期状態は1件のはず');

    final idToDelete = list.first.id;

    // 削除を実行
    await repo.deleteTransaction(idToDelete);

    // 再確認
    list = await repo.getAllTransactions(forceReload: true);
    expect(list.length, 0, reason: '削除後は0件になるはず');
  });
}
//flutter test test/transaction_repository_test.dart