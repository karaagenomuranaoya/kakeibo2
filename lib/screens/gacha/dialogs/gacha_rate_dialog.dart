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
    // 1. 通常の排出対象（Lv10未満）を抽出
    List<GachaItem> availableItems = allItems.where((item) {
      final int count = itemCounts[item.id] ?? 0;
      return count < _maxLevel;
    }).toList();

    bool isCompleteMode = false;

    // 2. もし排出対象がなければ（全キャラLv10以上）、殿堂入りモードとして全キャラを対象にする
    if (availableItems.isEmpty && allItems.isNotEmpty) {
      availableItems = List.from(allItems);
      isCompleteMode = true;
    }

    final int totalAvailable = availableItems.length;

    // 万が一データが0件の場合のガード
    if (totalAvailable == 0) {
      return AlertDialog(
        title: const Text("提供割合"),
        content: const Text("排出対象となるキャラクターがいません。"),
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

    // モードによる色の切り替え
    final Color themeColor = isCompleteMode ? Colors.purple : Colors.orange;
    final Color bgColor = isCompleteMode
        ? Colors.purple.shade50
        : Colors.orange.shade50;
    final Color borderColor = isCompleteMode
        ? Colors.purple.shade200
        : Colors.orange.shade200;
    final String titleText = isCompleteMode ? "提供割合 (殿堂入り中)" : "提供割合";

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Text(
        titleText,
        style: const TextStyle(fontWeight: FontWeight.bold),
      ),
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
                  color: bgColor,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: borderColor),
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
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: themeColor,
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
              if (isCompleteMode)
                const Text(
                  "・全キャラクターが最大レベルに到達しました！\n・現在は殿堂入りモードとして、全てのキャラクターが排出対象です。\n・Lv.10を超えて獲得すると色が変化します。",
                  style: TextStyle(fontSize: 12, color: Colors.purple),
                )
              else
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

                // 殿堂入り中は「Lv.11」などもそのまま表示、通常時は最大10
                final int displayLevel = isCompleteMode
                    ? count
                    : item.getStage(count);

                final bool isUnobtained = count == 0;
                // 色計算（Lv11以降の色変化を反映）
                final Color itemColor = item.getColor(count);

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
                          border: isCompleteMode && !isUnobtained
                              ? Border.all(
                                  color: itemColor.withOpacity(0.5),
                                  width: 1.5,
                                )
                              : null,
                        ),
                        child: Icon(
                          item.iconData,
                          size: 20,
                          color: isUnobtained
                              ? Colors.grey.shade400
                              : itemColor,
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
                              : (isCompleteMode
                                    ? Colors.purple.shade50
                                    : Colors.blueGrey.shade50),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isUnobtained
                                ? Colors.red.shade200
                                : Colors.transparent,
                            width: 1,
                          ),
                        ),
                        child: Text(
                          isUnobtained ? "未所持" : "現在 Lv.$displayLevel",
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: isUnobtained
                                ? Colors.red
                                : (isCompleteMode
                                      ? Colors.purple
                                      : Colors.blueGrey.shade700),
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
