import 'package:flutter_test/flutter_test.dart';
import 'package:atsumeru_kakeibo/utils/simple_calculator.dart'; // パスは適宜調整

void main() {
  group('SimpleCalculator Tests', () {
    // 基本的な計算
    test('足し算: 100+200 = 300', () {
      expect(SimpleCalculator.calculate('100+200'), '300');
    });

    test('引き算: 500-100 = 400', () {
      expect(SimpleCalculator.calculate('500-100'), '400');
    });

    test('掛け算: 50x3 = 150', () {
      expect(SimpleCalculator.calculate('50x3'), '150');
    });

    test('引き算と掛け算の優先順位', () {
      // 家計簿の入力順としてどう処理されるか確認
      expect(SimpleCalculator.calculate('100+20x3'), '160');
    });

    // 家計簿アプリ特有の仕様（整数・四捨五入）
    test('割り算(割り切れる): 100÷2 = 50', () {
      expect(SimpleCalculator.calculate('100÷2'), '50');
    });

    test('割り算(四捨五入): 100÷3 = 33 (33.33...)', () {
      expect(SimpleCalculator.calculate('100÷3'), '33');
    });

    test('割り算(四捨五入): 200÷3 = 67 (66.66...)', () {
      // これが失敗すると、金額が1円ずれるバグになります
      expect(SimpleCalculator.calculate('200÷3'), '67');
    });

    // エッジケース（異常系）
    test('空文字の場合は空文字を返す', () {
      expect(SimpleCalculator.calculate(''), '');
    });

    test('末尾が演算子のままなら削除して計算: 100+ => 100', () {
      expect(SimpleCalculator.calculate('100+'), '100');
    });

    test('カンマが含まれていても計算できる: 1,000+2,000 => 3000', () {
      expect(SimpleCalculator.calculate('1,000+2,000'), '3000');
    });
  });
}
//flutter test test/simple_calculator_test.dart