import 'package:flutter/material.dart';
import '../../../models/gacha_item.dart';

class GachaRateDialog extends StatelessWidget {
  final List<GachaItem> allItems;
  final Map<String, int> itemCounts;

  const GachaRateDialog({
    super.key,
    required this.allItems,
    required this.itemCounts,
  });

  static const int _maxLevel = 10;

  @override
  Widget build(BuildContext context) {
    final availableItems = allItems.where((item) {
      final int count = itemCounts[item.id] ?? 0;
      final int level = item.getStage(count);
      return level < _maxLevel;
    }).toList();

    final int totalAvailable = availableItems.length;

    if (totalAvailable == 0) {
      return AlertDialog(
        title: const Text("提供割合"),
        content: const Text("全てのキャラクターが最大レベルです。\n排出対象はありません。"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("閉じる"),
          ),
        ],
      );
    }

    final double rate = 100.0 / totalAvailable;
    final String rateString = rate.toStringAsFixed(2);

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: const Text("提供割合", style: TextStyle(fontWeight: FontWeight.bold)),
      content: SizedBox(
        width: double.maxFinite,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.orange.shade200),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "現在の排出確率",
                      style: TextStyle(fontSize: 12, color: Colors.brown),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Text("全キャラ均等"),
                        const Spacer(),
                        Text(
                          "$rateString %",
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.orange,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                "【仕様について】",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              ),
              const SizedBox(height: 4),
              const Text(
                "・Lv.10(最大)に到達したキャラクターは排出されなくなります。\n・排出確率は、残りの排出対象キャラクター間で均等に分配されます。",
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
              const SizedBox(height: 16),
              Text(
                "排出対象一覧 ($totalAvailable種)",
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
              const Divider(),
              ...availableItems.map((item) {
                final int count = itemCounts[item.id] ?? 0;
                final int level = item.getStage(count);
                final bool isUnobtained = count == 0;
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Row(
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: isUnobtained
                              ? Colors.grey.shade200
                              : Colors.grey.shade100,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          item.iconData,
                          size: 20,
                          color: isUnobtained
                              ? Colors.grey.shade400
                              : Colors.grey,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          item.baseName,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: isUnobtained
                                ? Colors.black54
                                : Colors.black87,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: isUnobtained
                              ? Colors.red.shade50
                              : Colors.blueGrey.shade50,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isUnobtained
                                ? Colors.red.shade200
                                : Colors.transparent,
                            width: 1,
                          ),
                        ),
                        child: Text(
                          isUnobtained ? "未所持" : "現在 Lv.$level",
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: isUnobtained
                                ? Colors.red
                                : Colors.blueGrey.shade700,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text("閉じる"),
        ),
      ],
    );
  }
}
