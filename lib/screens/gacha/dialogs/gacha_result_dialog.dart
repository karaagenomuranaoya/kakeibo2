import 'package:flutter/material.dart';
import '../../../models/gacha_item.dart';
import 'gacha_history_dialog.dart';

class GachaResultDialog extends StatelessWidget {
  final GachaItem item;
  final int count;

  const GachaResultDialog({super.key, required this.item, required this.count});

  static const int _maxLevel = 10;

  void _showHistoryDialog(BuildContext context, int level) {
    showDialog(
      context: context,
      builder: (context) => GachaHistoryDialog(item: item, maxLevel: level),
    );
  }

  @override
  Widget build(BuildContext context) {
    final int level = item.getStage(count);
    final bool isNew = count == 1;
    final bool isMax = level == _maxLevel;

    String title = "LEVEL UP!!";
    Color titleColor = Colors.orange;

    if (isNew) {
      title = "NEW GET!!";
      titleColor = Colors.redAccent;
    } else if (isMax) {
      title = "MAX EVOLUTION!!";
      titleColor = Colors.purpleAccent;
    }

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              title,
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.bold,
                color: titleColor,
                fontStyle: FontStyle.italic,
              ),
            ),
            const SizedBox(height: 30),
            GestureDetector(
              onTap: () => _showHistoryDialog(context, level),
              child: Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.grey.shade100,
                  border: Border.all(
                    color: item.getColor(count).withOpacity(0.5),
                    width: 4,
                  ),
                ),
                child: Icon(
                  item.iconData,
                  size: 60,
                  color: item.getColor(count),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              item.getName(count),
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            Text(
              "No.${item.id}",
              style: const TextStyle(
                fontSize: 14,
                color: Colors.grey,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 5),
            Text(
              "Lv.$level / $_maxLevel",
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.blueGrey,
              ),
            ),
            const SizedBox(height: 10),
            Container(
              constraints: const BoxConstraints(maxHeight: 80),
              width: double.maxFinite,
              child: SingleChildScrollView(
                child: Text(
                  item.getDescription(count),
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.grey, fontSize: 14),
                ),
              ),
            ),
            const SizedBox(height: 20),
            if (!isMax) ...[
              LinearProgressIndicator(
                value: level / _maxLevel,
                minHeight: 10,
                backgroundColor: Colors.grey.shade200,
                color: item.getColor(count),
                borderRadius: BorderRadius.circular(5),
              ),
              const SizedBox(height: 5),
              Text(
                "あと ${_maxLevel - level}枚で最大進化",
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
              const SizedBox(height: 20),
            ],
            OutlinedButton.icon(
              onPressed: () => _showHistoryDialog(context, level),
              icon: const Icon(Icons.history_edu),
              label: const Text("進化の記録を見る"),
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('閉じる'),
            ),
          ],
        ),
      ),
    );
  }
}
