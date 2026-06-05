import 'package:flutter/material.dart';

class GachaActionPanel extends StatelessWidget {
  final bool isAllComplete;
  final int ticketCount;
  final VoidCallback? onSpin;
  final Key? buttonKey;

  const GachaActionPanel({
    super.key,
    required this.isAllComplete,
    required this.ticketCount,
    required this.onSpin,
    this.buttonKey,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 30),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
        borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              key: buttonKey,
              onPressed: onSpin,
              style: ElevatedButton.styleFrom(
                backgroundColor: isAllComplete
                    ? Colors.deepPurple
                    : Colors.orange,
                foregroundColor: Colors.white,
                disabledBackgroundColor: Colors.grey.shade200,
                disabledForegroundColor: Colors.grey,
                elevation: (onSpin != null) ? 4 : 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: Text(
                isAllComplete
                    ? "殿堂入りガチャを回す"
                    : (ticketCount > 0 ? "ガチャを回す (1枚消費)" : "チケットが足りません"),
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            "※入力をすると1日最大5枚までチケットを獲得できます",
            style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
          ),
        ],
      ),
    );
  }
}
