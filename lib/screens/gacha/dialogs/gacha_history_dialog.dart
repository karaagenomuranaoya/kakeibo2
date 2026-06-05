import 'package:flutter/material.dart';
import '../../../models/gacha_item.dart';

class GachaHistoryDialog extends StatelessWidget {
  final GachaItem item;
  final int maxLevel;

  const GachaHistoryDialog({
    super.key,
    required this.item,
    required this.maxLevel,
  });

  static const int _systemMaxLevel = 10;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                Text(
                  "No.${item.id}",
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.grey,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  "${item.baseName}の進化記録",
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Flexible(
            child: SizedBox(
              width: double.maxFinite,
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: maxLevel > _systemMaxLevel
                    ? _systemMaxLevel
                    : maxLevel,
                itemBuilder: (context, index) {
                  final level = index + 1;
                  return ListTile(
                    leading: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade50,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: item.getColor(level).withOpacity(0.5),
                          width: 2,
                        ),
                      ),
                      child: Icon(
                        item.iconData,
                        color: item.getColor(level),
                        size: 20,
                      ),
                    ),
                    title: Text(
                      item.getName(level),
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text(
                      item.getDescription(level),
                      style: const TextStyle(fontSize: 12),
                    ),
                    trailing: Text(
                      "Lv.$level",
                      style: const TextStyle(
                        color: Colors.grey,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
          const Divider(height: 1),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("閉じる"),
          ),
        ],
      ),
    );
  }
}
