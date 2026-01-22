import 'package:flutter/material.dart';

/// 合計金額表示カード
class TotalExpenseCard extends StatelessWidget {
  final int total;

  const TotalExpenseCard({super.key, required this.total});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.blue.shade50,
      child: InkWell(
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 20),
          child: Column(
            children: [
              const Text(
                '合計支出',
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '¥ $total',
                    style: const TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
