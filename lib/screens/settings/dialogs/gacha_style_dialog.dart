import 'package:flutter/material.dart';
import '../../../models/gacha_item.dart';

class GachaStyleDialog extends StatelessWidget {
  final GachaItem item;
  final int currentCount;

  const GachaStyleDialog({
    super.key,
    required this.item,
    required this.currentCount,
  });

  @override
  Widget build(BuildContext context) {
    // 所持数を最大レベルとする
    final int maxLevel = currentCount;

    return AlertDialog(
      title: Text('${item.baseName}のスタイル選択'),
      content: SizedBox(
        width: double.maxFinite,
        child: SingleChildScrollView(
          child: Wrap(
            spacing: 12,
            runSpacing: 12,
            alignment: WrapAlignment.center,
            children: List.generate(maxLevel, (index) {
              final level = index + 1;
              final color = item.getColor(level);

              return GestureDetector(
                onTap: () {
                  // 選択された色を返して閉じる
                  Navigator.pop(context, color);
                },
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        border: Border.all(color: color, width: 2),
                      ),
                      child: Icon(item.iconData, color: color, size: 28),
                    ),
                    const SizedBox(height: 4),
                    Text("Lv.$level", style: const TextStyle(fontSize: 10)),
                  ],
                ),
              );
            }),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text("キャンセル"),
        ),
      ],
    );
  }
}
