import 'package:flutter/material.dart';

class GachaHeader extends StatelessWidget {
  final int ticketCount;
  final VoidCallback onRatePressed;
  final Key? ticketKey;

  const GachaHeader({
    super.key,
    required this.ticketCount,
    required this.onRatePressed,
    this.ticketKey,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.orange.shade50.withOpacity(0.5),
        border: Border(bottom: BorderSide(color: Colors.orange.shade100)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Container(
            key: ticketKey,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.orange.shade200),
              boxShadow: [
                BoxShadow(
                  color: Colors.orange.withOpacity(0.1),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                Icon(
                  Icons.confirmation_number,
                  size: 18,
                  color: Colors.orange.shade800,
                ),
                const SizedBox(width: 6),
                const Text(
                  "所持チケット:",
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.brown,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(width: 4),
                Text(
                  "$ticketCount枚",
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.deepOrange,
                  ),
                ),
              ],
            ),
          ),
          TextButton.icon(
            onPressed: onRatePressed,
            icon: const Icon(Icons.info_outline, size: 16, color: Colors.grey),
            label: const Text(
              "提供割合",
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
            style: TextButton.styleFrom(visualDensity: VisualDensity.compact),
          ),
        ],
      ),
    );
  }
}
