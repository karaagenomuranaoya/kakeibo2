import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:atsumeru_kakeibo/widgets/custom_number_keyboard.dart';

void main() {
  // テストを見やすくするためのヘルパー関数
  // キーボードを表示するだけの小さなアプリを作って表示させる
  Future<void> pumpKeyboard(
    WidgetTester tester, {
    required TextEditingController controller,
    VoidCallback? onSubmitted,
    VoidCallback? onSaveAndClose,
    VoidCallback? onClose,
    ValueChanged<String>? onChanged,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            // キーボードが表示される領域を確保（これがないとエラーになることがある）
            height: 400,
            child: CustomNumberKeyboard(
              controller: controller,
              onSubmitted: onSubmitted ?? () {},
              onSaveAndClose: onSaveAndClose,
              onClose: onClose ?? () {},
              onChanged: onChanged ?? (_) {},
            ),
          ),
        ),
      ),
    );
  }

  group('CustomNumberKeyboard Tests', () {
    testWidgets('数字をタップして入力できること', (WidgetTester tester) async {
      final controller = TextEditingController();

      await pumpKeyboard(tester, controller: controller);

      // "1", "2", "3" を順番にタップ
      await tester.tap(find.text('1'));
      await tester.pump(); // 画面更新待ち
      await tester.tap(find.text('2'));
      await tester.pump();
      await tester.tap(find.text('3'));
      await tester.pump();

      // コントローラーの値が "123" になっているか確認
      expect(controller.text, '123');
    });

    testWidgets('3桁ごとにカンマが入ること', (WidgetTester tester) async {
      final controller = TextEditingController();
      await pumpKeyboard(tester, controller: controller);

      // "1000" と入力
      await tester.tap(find.text('1'));
      await tester.tap(find.text('0'));
      await tester.tap(find.text('0'));
      await tester.tap(find.text('0'));
      await tester.pump();

      // "1,000" になっているはず
      expect(controller.text, '1,000');
    });

    testWidgets('ACボタンで全消去できること', (WidgetTester tester) async {
      final controller = TextEditingController(text: '12345');
      await pumpKeyboard(tester, controller: controller);

      // ACボタンをタップ
      await tester.tap(find.text('AC'));
      await tester.pump();

      expect(controller.text, '');
    });

    testWidgets('Delボタンで1文字消せること', (WidgetTester tester) async {
      final controller = TextEditingController(text: '123');
      await pumpKeyboard(tester, controller: controller);

      // Delボタンをタップ
      await tester.tap(find.text('Del'));
      await tester.pump();

      expect(controller.text, '12');
    });

    testWidgets('計算ロジック（＝ボタン）が正しく動くこと', (WidgetTester tester) async {
      // 10 + 20 を入力するシナリオ
      final controller = TextEditingController();
      await pumpKeyboard(tester, controller: controller);

      await tester.tap(find.text('1'));
      await tester.tap(find.text('0'));
      await tester.tap(find.text('+')); // 演算子
      await tester.tap(find.text('2'));
      await tester.tap(find.text('0'));
      await tester.pump();

      // 画面上のテキストは "10+20"
      expect(controller.text, '10+20');

      // 演算子が含まれている場合、右下のボタンは「＝」アイコンになるはず
      // Icons.calculate を探す
      final calcIcon = find.byIcon(Icons.calculate);
      expect(calcIcon, findsOneWidget);

      // 計算実行
      await tester.tap(calcIcon);
      await tester.pump();

      // 結果が "30" になっているか
      expect(controller.text, '30');
    });

    testWidgets('消費税ボタン（xを押した時だけ出る）のテスト', (WidgetTester tester) async {
      final controller = TextEditingController();
      await pumpKeyboard(tester, controller: controller);

      // まだ "x" を押してないので、ボタンは "0", "00" のはず
      expect(find.text('0'), findsOneWidget);
      expect(find.text('00'), findsOneWidget);
      expect(find.text('1.1'), findsNothing);

      // "100" "x" と入力
      await tester.tap(find.text('1'));
      await tester.tap(find.text('0'));
      await tester.tap(find.text('0'));
      await tester.tap(find.text('x'));
      await tester.pump();

      // ここでボタンが切り替わっているはず
      expect(find.text('1.1'), findsOneWidget); // 税10%ボタン
      expect(find.text('1.08'), findsOneWidget); // 税8%ボタン

      // "1.1" をタップ
      await tester.tap(find.text('1.1'));
      await tester.pump();

      // "100x1.1" になっているか
      expect(controller.text, '100x1.1');
    });

    testWidgets('保存して閉じるボタンのコールバック確認', (WidgetTester tester) async {
      bool isSaved = false;
      final controller = TextEditingController(text: '100'); // 最初から数字が入ってる

      await pumpKeyboard(
        tester,
        controller: controller,
        onSaveAndClose: () {
          isSaved = true;
        },
      );

      // "保存して閉じる" ボタンを探してタップ
      // テキストボタンなのでラベルで探す
      await tester.tap(find.text('保存'));

      expect(isSaved, isTrue);
    });
  });
}
//flutter test test/custom_number_keyboard_test.dart