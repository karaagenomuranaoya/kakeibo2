import 'package:flutter_test/flutter_test.dart';
import 'package:atsumeru_kakeibo/utils/app_date_utils.dart';

void main() {
  group('AppDateUtils Tests', () {
    test('formatMonthDayWeek returns correct format', () {
      // 2024年1月1日は月曜日
      final monday = DateTime(2024, 1, 1);
      expect(AppDateUtils.formatMonthDayWeek(monday), '1/1 (月)');

      // 2024年1月7日は日曜日
      final sunday = DateTime(2024, 1, 7);
      expect(AppDateUtils.formatMonthDayWeek(sunday), '1/7 (日)');

      // 2024年12月31日は火曜日
      final endOfYear = DateTime(2024, 12, 31);
      expect(AppDateUtils.formatMonthDayWeek(endOfYear), '12/31 (火)');
    });

    test('formatDateTime returns correct format', () {
      // 通常の時間
      final date1 = DateTime(2024, 1, 15, 14, 30);
      expect(AppDateUtils.formatDateTime(date1), '1/15 14:30');

      // 分が1桁の場合は0埋めされるか確認
      final date2 = DateTime(2024, 5, 5, 9, 5);
      expect(AppDateUtils.formatDateTime(date2), '5/5 9:05');

      // 分が0の場合
      final date3 = DateTime(2024, 10, 10, 23, 0);
      expect(AppDateUtils.formatDateTime(date3), '10/10 23:00');
    });
  });
}
