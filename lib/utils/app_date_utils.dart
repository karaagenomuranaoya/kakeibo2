import 'package:intl/intl.dart';

class AppDateUtils {
  static const List<String> _weekDays = ["月", "火", "水", "木", "金", "土", "日"];

  /// 例: 1/15 (月)
  static String formatMonthDayWeek(DateTime date) {
    return "${date.month}/${date.day} (${_weekDays[date.weekday - 1]})";
  }

  /// 例: 1/15 14:30
  static String formatDateTime(DateTime date) {
    return "${date.month}/${date.day} ${date.hour}:${date.minute.toString().padLeft(2, '0')}";
  }

  /// 例: 2023年 10月
  static String formatYearMonth(int year, int month) {
    return "$year年 $month月";
  }

  /// 指定した年月の日数を取得
  static int getDaysInMonth(int year, int month) {
    return DateTime(year, month + 1, 0).day;
  }
}
