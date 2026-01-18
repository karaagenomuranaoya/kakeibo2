import 'package:flutter/material.dart';
import '../../models/transaction_item.dart';

/// カレンダー表示用ウィジェット
class CalendarView extends StatelessWidget {
  final int year;
  final int month;
  final List<TransactionItem> history;
  final Function(int day) onDateTap;

  const CalendarView({
    super.key,
    required this.year,
    required this.month,
    required this.history,
    required this.onDateTap,
  });

  @override
  Widget build(BuildContext context) {
    final daysInMonth = DateTime(year, month + 1, 0).day;
    final firstWeekday = DateTime(year, month, 1).weekday;
    // DateTime.weekdayは 月=1...日=7
    // カレンダーの開始を「日曜日」とする場合、日曜(7)の扱いに注意が必要ですが
    // 既存コードは「日月火水木金土」のヘッダー順で、
    // emptyCount = firstWeekday % 7 としているので、
    // 日曜(7)なら0(ズレなし)、月曜(1)なら1つズレる...という「日曜始まり」ロジックになっています。
    final int emptyCount = firstWeekday % 7;

    final hasDataDays = history.map((e) => e.date.day).toSet();

    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Column(
        children: [
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              Text('日', style: TextStyle(color: Colors.red, fontSize: 12)),
              Text('月', style: TextStyle(color: Colors.black, fontSize: 12)),
              Text('火', style: TextStyle(color: Colors.black, fontSize: 12)),
              Text('水', style: TextStyle(color: Colors.black, fontSize: 12)),
              Text('木', style: TextStyle(color: Colors.black, fontSize: 12)),
              Text('金', style: TextStyle(color: Colors.black, fontSize: 12)),
              Text('土', style: TextStyle(color: Colors.blue, fontSize: 12)),
            ],
          ),
          const SizedBox(height: 5),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: emptyCount + daysInMonth,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              childAspectRatio: 1.2,
            ),
            itemBuilder: (context, index) {
              if (index < emptyCount) {
                return const SizedBox.shrink();
              }
              final day = index - emptyCount + 1;
              final hasData = hasDataDays.contains(day);

              return GestureDetector(
                onTap: hasData ? () => onDateTap(day) : null,
                child: Container(
                  margin: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    color: hasData ? Colors.orange.shade50 : Colors.transparent,
                    borderRadius: BorderRadius.circular(8),
                    border: hasData
                        ? Border.all(color: Colors.orange.shade200)
                        : null,
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        '$day',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: hasData
                              ? FontWeight.bold
                              : FontWeight.normal,
                          color: hasData ? Colors.black87 : Colors.grey,
                        ),
                      ),
                      if (hasData)
                        Container(
                          margin: const EdgeInsets.only(top: 2),
                          width: 4,
                          height: 4,
                          decoration: const BoxDecoration(
                            color: Colors.orange,
                            shape: BoxShape.circle,
                          ),
                        ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
