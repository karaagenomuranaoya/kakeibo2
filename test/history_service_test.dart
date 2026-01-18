import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:atsumeru_kakeibo/services/history_service.dart';
import 'package:atsumeru_kakeibo/repositories/transaction_repository.dart';
import 'package:atsumeru_kakeibo/models/transaction_item.dart';

void main() {
  setUp(() async {
    // 毎回データをリセット
    SharedPreferences.setMockInitialValues({});
    // リポジトリのキャッシュもクリア
    final repo = TransactionRepository();
    await repo.getAllTransactions(forceReload: true);
  });

  // テストデータを作成するヘルパー関数
  Future<void> addSampleData() async {
    final repo = TransactionRepository();

    // 1. 1月の食費 (現金)
    await repo.addTransaction(
      TransactionItem(
        amount: 1000,
        expense: '食費',
        payment: '現金',
        date: DateTime(2025, 1, 15),
      ),
    );

    // 2. 1月の交通費 (カード: 翌月2/27払い)
    await repo.addTransaction(
      TransactionItem(
        amount: 500,
        expense: '交通費',
        payment: 'メインカード',
        date: DateTime(2025, 1, 20),
        paymentDate: DateTime(2025, 2, 27), // 2月払い
      ),
    );

    // 3. 2月の食費 (現金)
    await repo.addTransaction(
      TransactionItem(
        amount: 2000,
        expense: '食費',
        payment: '現金',
        date: DateTime(2025, 2, 10),
      ),
    );
  }

  group('履歴サービスのフィルタリングテスト', () {
    test('月ごとのデータ取得が正しいか', () async {
      await addSampleData();
      final service = HistoryService();

      // 1月のデータを取得
      final janList = await service.getMonthlyTransactions(
        year: 2025,
        month: 1,
      );
      // 1月は「食費」と「交通費」の2件あるはず
      expect(janList.length, 2);

      // 2月のデータを取得
      final febList = await service.getMonthlyTransactions(
        year: 2025,
        month: 2,
      );
      // 2月は「食費」の1件だけ
      expect(febList.length, 1);
      expect(febList.first.amount, 2000);
    });

    test('費目で絞り込みができるか', () async {
      await addSampleData();
      final service = HistoryService();

      // 1月の中で「食費」だけを検索
      // viewMode: 0 (利用日基準)
      final foodList = await service.getFilteredTransactions(
        filterKey: 'expense',
        filterValue: '食費',
        year: 2025,
        month: 1,
        viewMode: 0,
      );

      expect(foodList.length, 1);
      expect(foodList.first.expense, '食費');
      expect(foodList.first.amount, 1000);

      // 1月の中で「交通費」だけを検索
      final transportList = await service.getFilteredTransactions(
        filterKey: 'expense',
        filterValue: '交通費',
        year: 2025,
        month: 1,
        viewMode: 0,
      );
      expect(transportList.length, 1);
      expect(transportList.first.expense, '交通費');
    });

    test('【重要】利用日モード(0) と 支払日モード(1) の違い', () async {
      await addSampleData();
      final service = HistoryService();

      // データのおさらい:
      // 「交通費500円」は、利用日: 1/20, 支払日: 2/27

      // --- ケース1: 1月を表示 ---

      // モード0(利用日)で1月を見る -> 交通費は「1月に使った」ので表示されるはず
      final janMode0 = await service.getFilteredTransactions(
        filterKey: 'expense',
        filterValue: '交通費', // 絞り込み条件は何でもいいが特定しやすくするため指定
        year: 2025,
        month: 1,
        viewMode: 0,
      );
      expect(janMode0.length, 1, reason: '利用日基準なら1月にいるはず');

      // モード1(支払日)で1月を見る -> 支払いは2月なので、1月には表示されないはず
      final janMode1 = await service.getFilteredTransactions(
        filterKey: 'expense',
        filterValue: '交通費',
        year: 2025,
        month: 1,
        viewMode: 1,
      );
      expect(janMode1.length, 0, reason: '支払日基準なら1月にはいないはず');

      // --- ケース2: 2月を表示 ---

      // モード0(利用日)で2月を見る -> 利用は1月なので表示されない
      final febMode0 = await service.getFilteredTransactions(
        filterKey: 'expense',
        filterValue: '交通費',
        year: 2025,
        month: 2,
        viewMode: 0,
      );
      expect(febMode0.length, 0, reason: '利用日基準なら2月にはいないはず');

      // モード1(支払日)で2月を見る -> 支払いは2月なので表示されるはず！
      final febMode1 = await service.getFilteredTransactions(
        filterKey: 'expense',
        filterValue: '交通費',
        year: 2025,
        month: 2,
        viewMode: 1,
      );
      expect(febMode1.length, 1, reason: '支払日基準なら2月に出てくるはず');
      expect(febMode1.first.amount, 500);
    });
  });
}
//flutter test test/history_service_test.dart