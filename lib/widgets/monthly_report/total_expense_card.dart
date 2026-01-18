import 'package:flutter/material.dart';

/// 合計金額表示カード
class TotalExpenseCard extends StatelessWidget {
  final int total;
  final VoidCallback onTap;

  const TotalExpenseCard({super.key, required this.total, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.blue.shade50,
      child: InkWell(
        onTap: onTap,
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
                  const Padding(
                    padding: EdgeInsets.only(bottom: 6, left: 5),
                    child: Icon(
                      Icons.arrow_forward_ios,
                      size: 14,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
              const Text(
                'タップして詳細を見る',
                style: TextStyle(fontSize: 10, color: Colors.blueGrey),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
