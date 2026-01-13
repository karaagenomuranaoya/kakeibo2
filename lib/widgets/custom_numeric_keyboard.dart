import 'package:flutter/material.dart';

class CustomNumericKeyboard extends StatelessWidget {
  final Function(String) onNumberTap;
  final VoidCallback onBackspace;
  final VoidCallback onClear;
  final VoidCallback onDone;

  const CustomNumericKeyboard({
    super.key,
    required this.onNumberTap,
    required this.onBackspace,
    required this.onClear,
    required this.onDone,
  });

  @override
  Widget build(BuildContext context) {
    // ▼▼ 変更: 280 -> 230 に変更してコンパクト化 ▼▼
    const double height = 230;

    return Container(
      height: height,
      color: Colors.grey.shade100,
      padding: const EdgeInsets.all(6),
      child: Row(
        // ... 中身は変更なし ...
        children: [
          Expanded(
            flex: 3,
            child: Column(
              children: [
                _buildRow(['7', '8', '9']),
                _buildRow(['4', '5', '6']),
                _buildRow(['1', '2', '3']),
                _buildRow(['0', '00', '.']),
              ],
            ),
          ),
          const SizedBox(width: 6),
          Expanded(
            flex: 1,
            child: Column(
              children: [
                Expanded(
                  child: _buildActionButton(
                    icon: Icons.backspace,
                    color: Colors.blueGrey.shade200,
                    onTap: onBackspace,
                    onLongPress: onClear,
                  ),
                ),
                const SizedBox(height: 6),
                Expanded(
                  flex: 2,
                  child: _buildActionButton(
                    icon: Icons.check,
                    label: '決定',
                    color: Colors.blue,
                    textColor: Colors.white,
                    onTap: onDone,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ... _buildRow などは変更なし ...
  Widget _buildRow(List<String> keys) {
    return Expanded(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: keys.map((key) {
          return Expanded(
            child: Padding(
              padding: const EdgeInsets.all(2),
              child: ElevatedButton(
                onPressed: () => onNumberTap(key),
                style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.zero,
                  backgroundColor: Colors.white,
                  surfaceTintColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  elevation: 1,
                ),
                child: Text(
                  key,
                  style: const TextStyle(fontSize: 24, color: Colors.black87),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildActionButton({
    IconData? icon,
    String? label,
    required Color color,
    Color textColor = Colors.black,
    required VoidCallback onTap,
    VoidCallback? onLongPress,
  }) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: onTap,
        onLongPress: onLongPress,
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          padding: EdgeInsets.zero,
          elevation: 1,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (icon != null)
              Icon(icon, color: textColor, size: 24), // アイコン少し小さく
            if (label != null)
              Text(
                label,
                style: TextStyle(
                    color: textColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 14), // フォント少し小さく
              ),
          ],
        ),
      ),
    );
  }
}
