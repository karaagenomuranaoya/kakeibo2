import 'package:flutter/material.dart';

/// 全画面黒背景のチュートリアル用オーバーレイ
/// ガチャ画面や入力画面など、アプリ全体で統一したデザインを使用するために分離
class TutorialOverlay extends StatelessWidget {
  final IconData iconData;
  final Color iconColor;
  final String title;
  final String description;
  final String? subDescription; // 「試しに回してみましょう」などの強調テキスト
  final VoidCallback onDismiss;

  const TutorialOverlay({
    super.key,
    required this.iconData,
    this.iconColor = Colors.orange,
    required this.title,
    required this.description,
    this.subDescription,
    required this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      type: MaterialType.transparency,
      child: GestureDetector(
        // 画面全体どこをタップしても閉じる
        onTap: onDismiss,
        child: Container(
          color: Colors.black.withOpacity(0.85), // 背景を暗く
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(iconData, size: 80, color: iconColor),
              const SizedBox(height: 30),
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  fontSize: 26,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              Text(
                description,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  height: 1.6,
                ),
                textAlign: TextAlign.center,
              ),
              if (subDescription != null) ...[
                const SizedBox(height: 40),
                Text(
                  subDescription!,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.orangeAccent,
                    fontSize: 20,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
              const SizedBox(height: 60),
              const Text(
                "(画面をタップして閉じる)",
                style: TextStyle(color: Colors.white54, fontSize: 14),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
