import 'package:flutter_test/flutter_test.dart';
import 'package:atsumeru_kakeibo/utils/simple_calculator.dart';

void main() {
  group('SimpleCalculator Tests', () {
    test('Basic addition', () {
      expect(SimpleCalculator.calculate('100+200'), '300');
    });

    test('Basic subtraction', () {
      expect(SimpleCalculator.calculate('300-100'), '200');
    });

    test('Basic multiplication', () {
      expect(SimpleCalculator.calculate('10x20'), '200');
    });

    test('Basic division', () {
      expect(SimpleCalculator.calculate('200÷2'), '100');
    });

    test('Order of operations (Multiplication priority)', () {
      // 100 + 2 * 50 = 200 (not 5100)
      expect(SimpleCalculator.calculate('100+2x50'), '200');
    });

    test('Order of operations (Division priority)', () {
      // 100 - 50 / 2 = 75 (not 25)
      expect(SimpleCalculator.calculate('100-50÷2'), '75');
    });

    test('Decimal rounding (Round half up)', () {
      // 10 / 3 = 3.333... -> 3
      expect(SimpleCalculator.calculate('10÷3'), '3');
      // 2 / 3 = 0.666... -> 1
      expect(SimpleCalculator.calculate('2÷3'), '1');
    });

    test('Handle commas in input', () {
      expect(SimpleCalculator.calculate('1,000+2,000'), '3000');
    });

    test('Handle trailing operator', () {
      expect(SimpleCalculator.calculate('100+'), '100');
      expect(SimpleCalculator.calculate('100x'), '100');
    });

    test('Zero division should return 0', () {
      expect(SimpleCalculator.calculate('100÷0'), '0');
    });

    test('Negative numbers at start', () {
      expect(SimpleCalculator.calculate('-100+200'), '100');
    });

    test('Complex expression', () {
      // 100 + 200 - 50 * 2 / 4
      // = 300 - 100 / 4
      // = 300 - 25
      // = 275
      expect(SimpleCalculator.calculate('100+200-50x2÷4'), '275');
    });

    test('Empty string', () {
      expect(SimpleCalculator.calculate(''), '');
    });
  });
}
