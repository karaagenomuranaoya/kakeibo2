import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:atsumeru_kakeibo/screens/gacha/gacha_game_tab.dart';
import 'package:atsumeru_kakeibo/screens/gacha/dialogs/gacha_complete_dialog.dart';
import 'package:atsumeru_kakeibo/repositories/gacha_repository.dart';
import 'package:atsumeru_kakeibo/data/gacha_data.dart';
import 'dart:convert';

void main() {
  group('ガチャコンプリートダイアログのテスト', () {
    // デバッグ用: コンプリートダイアログが直接表示できるかテスト
    testWidgets('コンプリートダイアログが直接表示できる', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (context) => const GachaCompleteDialog(),
                  );
                },
                child: const Text('ダイアログを表示'),
              ),
            ),
          ),
        ),
      );

      // ボタンをタップ
      await tester.tap(find.text('ダイアログを表示'));
      await tester.pumpAndSettle();

      // コンプリートダイアログが表示されているか確認
      final completeDialog = find.byType(GachaCompleteDialog);
      expect(completeDialog, findsOneWidget, reason: 'コンプリートダイアログが表示されていない');

      // タイトルが正しいか確認
      final title = find.text('🎉 コンプリート＆殿堂入り！');
      expect(title, findsOneWidget, reason: 'タイトルが見つからない');
    });

    // デバッグ用: コンプリート状態の判定ロジックをテスト
    test('コンプリート状態の判定ロジック', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final monsters = GachaData.monsters;

      // すべてのアイテムをLv10に設定
      final Map<String, int> counts = {};
      for (var monster in monsters) {
        counts[monster.id] = 10;
      }

      final jsonString = json.encode(counts);
      await prefs.setString('gacha_counts_v2', jsonString);

      final repo = GachaRepository();
      final itemCounts = await repo.getItemCounts();

      // すべてのアイテムがLv10か確認
      int maxLevelItems = 0;
      for (var entry in itemCounts.entries) {
        if (entry.value >= 10) {
          maxLevelItems++;
        }
      }

      final isAllComplete = maxLevelItems == monsters.length && monsters.isNotEmpty;
      expect(isAllComplete, isTrue, reason: 'すべてのアイテムがLv10であるべき');
    });

    testWidgets('全てのアイテムがLv10に達した時にコンプリートダイアログが表示される', (WidgetTester tester) async {
      // SharedPreferencesのモックを初期化
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();

      // すべてのアイテムを取得
      final monsters = GachaData.monsters;

      // すべてのアイテムをLv9に設定（最後の1つを10にする準備）
      // 最後のアイテムだけLv9のままにする
      final Map<String, int> counts = {};
      for (int i = 0; i < monsters.length - 1; i++) {
        counts[monsters[i].id] = 10; // 最後以外はLv10
      }
      counts[monsters.last.id] = 9; // 最後のアイテムはLv9

      // JSONエンコードして保存
      final jsonString = json.encode(counts);
      await prefs.setString('gacha_counts_v2', jsonString);

      // クレジットを1枚設定
      await prefs.setInt('gacha_credits', 1);

      // チュートリアルは既に表示済みにする
      await prefs.setBool('is_gacha_tutorial_shown', true);

      // GachaGameTabを表示
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: GachaGameTab(dataVersion: 0),
          ),
        ),
      );

      // データ読み込み完了を待つ
      await tester.pumpAndSettle(const Duration(seconds: 2));

      // ガチャをスピンするボタンを探してタップ
      // ボタンはGachaActionPanel内にある
      final spinButton = find.byType(ElevatedButton);
      expect(spinButton, findsWidgets, reason: 'スピンボタンが見つからない');

      // デバッグ: 初期状態を確認
      final initialCredits = await prefs.getInt('gacha_credits') ?? 0;
      print('DEBUG: 初期クレジット = $initialCredits');
      
      // スピンボタンをタップ（通常は最初のElevatedButtonがスピンボタン）
      print('DEBUG: スピンボタンをタップ');
      await tester.tap(spinButton.first);
      await tester.pump(); // 最初の更新

      // ローディングダイアログが表示されるのを待つ
      await tester.pump(const Duration(milliseconds: 100));
      
      // デバッグ: ローディングダイアログが表示されているか確認
      final loadingIndicator = find.byType(CircularProgressIndicator);
      print('DEBUG: ローディングダイアログ表示 = ${loadingIndicator.evaluate().isNotEmpty}');

      // ガチャ抽選の完了を待つ（非同期処理を待つ）
      // drawItem()で1秒の遅延があるので、それ以上待つ
      print('DEBUG: ガチャ抽選の完了を待つ...');
      await tester.pump(const Duration(seconds: 2)); // drawItem()の遅延（1秒）+ 余裕
      
      // 結果ダイアログが表示されるまで待つ（最大10秒）
      // _showResultDialog()がawait showDialog()で待っているので、結果ダイアログが表示されるまで待つ
      bool foundCloseButton = false;
      for (int i = 0; i < 20; i++) {
        // フレームを更新する
        await tester.pump(const Duration(milliseconds: 500));
        
        // デバッグ: 現在の状態を確認
        final dialog = find.byType(Dialog);
        final closeButton = find.text('閉じる');
        final errorSnack = find.textContaining('エラー');
        final currentLoading = find.byType(CircularProgressIndicator);
        
        print('DEBUG: ループ $i - Dialog: ${dialog.evaluate().length}, 閉じるボタン: ${closeButton.evaluate().isNotEmpty}, エラー: ${errorSnack.evaluate().isNotEmpty}, ローディング: ${currentLoading.evaluate().isNotEmpty}');
        
        // 結果ダイアログが表示されているか確認
        if (closeButton.evaluate().isNotEmpty) {
          foundCloseButton = true;
          print('DEBUG: 結果ダイアログが見つかりました');
          // 結果ダイアログの「閉じる」ボタンをタップ
          await tester.tap(closeButton);
          await tester.pump();
          break;
        }
        
        // エラーメッセージが表示されているか確認
        if (errorSnack.evaluate().isNotEmpty) {
          final errorText = (errorSnack.evaluate().first.widget as Text).data ?? '';
          print('DEBUG: エラーが発生: $errorText');
          fail('エラーが発生しました: $errorText');
        }
      }

      expect(foundCloseButton, isTrue, reason: '結果ダイアログの閉じるボタンが見つかりません。結果ダイアログが表示されていない可能性があります。\n'
          '考えられる原因:\n'
          '1. _spinGacha()内でエラーが発生している\n'
          '2. 非同期処理が完了していない\n'
          '3. drawItem()がnullを返している\n'
          '4. クレジットが不足している\n'
          '初期クレジット: $initialCredits');

      // 結果ダイアログが閉じるのを待つ
      print('DEBUG: 結果ダイアログを閉じました。コンプリートダイアログの表示を待ちます...');
      await tester.pumpAndSettle();

      // コンプリートダイアログが表示されるまで待つ
      // _showCompleteDialog内で300msの遅延があるので、それを考慮
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pumpAndSettle();

      // デバッグ: すべてのダイアログを確認
      final allDialogs = find.byType(Dialog);
      print('DEBUG: 現在表示されているダイアログ数: ${allDialogs.evaluate().length}');

      // コンプリートダイアログが表示されているか確認
      final completeDialog = find.byType(GachaCompleteDialog);
      print('DEBUG: コンプリートダイアログ: ${completeDialog.evaluate().isNotEmpty}');
      expect(completeDialog, findsOneWidget, reason: 'コンプリートダイアログが表示されていない');

      // ダイアログのタイトルが正しいか確認
      final title = find.text('🎉 コンプリート＆殿堂入り！');
      print('DEBUG: タイトルが見つかった: ${title.evaluate().isNotEmpty}');
      expect(title, findsOneWidget, reason: 'コンプリートダイアログのタイトルが見つからない');
    });

    testWidgets('一部のアイテムがLv10に達しても、全てがLv10でない場合はコンプリートダイアログが表示されない', (WidgetTester tester) async {
      // SharedPreferencesのモックを初期化
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();

      // すべてのアイテムを取得
      final monsters = GachaData.monsters;

      // すべてのアイテムをLv9に設定（まだコンプリートしていない状態）
      final Map<String, int> counts = {};
      for (int i = 0; i < monsters.length; i++) {
        counts[monsters[i].id] = 9; // すべてLv9
      }

      // JSONエンコードして保存
      final jsonString = json.encode(counts);
      await prefs.setString('gacha_counts_v2', jsonString);

      // クレジットを1枚設定
      await prefs.setInt('gacha_credits', 1);

      // チュートリアルは既に表示済みにする
      await prefs.setBool('is_gacha_tutorial_shown', true);

      // GachaGameTabを表示
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: GachaGameTab(dataVersion: 0),
          ),
        ),
      );

      // データ読み込み完了を待つ
      await tester.pumpAndSettle(const Duration(seconds: 2));

      // ガチャをスピンするボタンを探してタップ
      final spinButton = find.byType(ElevatedButton).first;
      await tester.tap(spinButton);
      await tester.pump();

      // ローディングダイアログが表示されるのを待つ
      await tester.pump(const Duration(milliseconds: 100));

      // ガチャ抽選の完了を待つ
      await tester.pump(const Duration(seconds: 2));

      // 結果ダイアログが表示されるまで待つ
      await tester.pumpAndSettle();

      // 結果ダイアログを閉じる（"閉じる"ボタンを探す）
      final closeButton = find.text('閉じる');
      if (closeButton.evaluate().isNotEmpty) {
        await tester.tap(closeButton);
        await tester.pump();
      }

      // 結果ダイアログが閉じるのを待つ
      await tester.pumpAndSettle();

      // コンプリートダイアログが表示されないことを確認
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pumpAndSettle();

      final completeDialog = find.byType(GachaCompleteDialog);
      expect(completeDialog, findsNothing, reason: 'コンプリートダイアログが表示されるべきではない');
    });
  });
}
// flutter test test/gacha_complete_dialog_test.dart
