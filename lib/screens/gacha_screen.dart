import 'package:flutter/foundation.dart'; // ▼▼ kDebugModeのために追加 ▼▼
import 'package:flutter/material.dart';
import '../repositories/gacha_repository.dart';
import '../models/gacha_item.dart';

class GachaScreen extends StatefulWidget {
  const GachaScreen({super.key});

  @override
  State<GachaScreen> createState() => _GachaScreenState();
}

class _GachaScreenState extends State<GachaScreen> {
  final GachaRepository _repository = GachaRepository();
  int _credits = 0;
  Map<String, int> _itemCounts = {};
  List<GachaItem> _allItems = [];
  bool _isLoading = true;

  static const int _maxLevel = 10;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final credits = await _repository.getCredits();
    final counts = await _repository.getItemCounts();
    final items = await _repository.getItems();

    if (mounted) {
      setState(() {
        _credits = credits;
        _itemCounts = Map.from(counts);
        _allItems = items;
        _isLoading = false;
      });
    }
  }

  Future<void> _spinGacha() async {
    if (_credits < 3) return;

    // ローディング表示
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    // 抽選処理 (まだ消費しない)
    final item = await _repository.drawItem();

    // 演出のため少し待つ
    await Future.delayed(const Duration(seconds: 1));

    if (!mounted) return;
    Navigator.pop(context); // ローディングを閉じる

    // コンプリート済みの場合
    if (item == null) {
      _showCompleteDialog();
      return;
    }

    // 消費処理
    final success = await _repository.consumeCredits(3);
    if (!success) {
      // 万が一消費できなかった場合
      return;
    }

    // 保存処理
    final newCount = await _repository.unlockItem(item.id);

    // 画面更新
    await _loadData();

    if (mounted) {
      _showResultDialog(item, newCount);
    }
  }

  void _showCompleteDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("コンプリート！"),
        content: const Text(
          "全てのキャラクターが最大レベルに到達しました！\nこれ以上ガチャを引くことはできません。\n\n次回のアップデートをお楽しみに！",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("OK"),
          ),
        ],
      ),
    );
  }

  void _showHistoryDialog(GachaItem item, int maxLevel) {
    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
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
                    itemCount: maxLevel > _maxLevel ? _maxLevel : maxLevel,
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
      },
    );
  }

  void _showResultDialog(GachaItem item, int count) {
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

    showDialog(
      context: context,
      builder: (context) => Dialog(
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
                onTap: () => _showHistoryDialog(item, level),
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
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
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
              Text(
                item.getDescription(count),
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.grey, fontSize: 14),
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
                onPressed: () => _showHistoryDialog(item, level),
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
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final int spins = _credits ~/ 3;
    final double progress = (_credits % 3) / 3.0;

    final int maxLevelItems = _itemCounts.entries
        .where((e) => e.value >= _maxLevel)
        .length;
    final int totalItems = _allItems.length;
    final double completeRate = totalItems > 0 ? maxLevelItems / totalItems : 0;
    // 全コンプリート判定
    final bool isAllComplete = maxLevelItems == totalItems && totalItems > 0;

    return Scaffold(
      backgroundColor: Colors.yellow.shade50,
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 30),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: const BorderRadius.vertical(
                bottom: Radius.circular(30),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "クレジット",
                          style: TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              "$_credits",
                              style: const TextStyle(
                                fontSize: 32,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const Text(
                              " pt",
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        const Text(
                          "伝説到達率",
                          style: TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                        Text(
                          "$maxLevelItems / $totalItems (${(completeRate * 100).toStringAsFixed(0)}%)",
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 15),
                LinearProgressIndicator(
                  value: spins > 0 ? 1.0 : progress,
                  backgroundColor: Colors.grey.shade200,
                  color: Colors.orange,
                  minHeight: 8,
                  borderRadius: BorderRadius.circular(4),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: spins > 0 ? _spinGacha : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isAllComplete
                          ? Colors.grey
                          : Colors.orange,
                      foregroundColor: Colors.white,
                      disabledBackgroundColor: Colors.grey.shade300,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      elevation: spins > 0 ? 4 : 0,
                    ),
                    child: Text(
                      isAllComplete
                          ? "コンプリート済み"
                          : (spins > 0
                                ? "ガチャを回す (3pt)"
                                : "あと ${3 - (_credits % 3)} 回入力でガチャ"),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: GridView.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                  childAspectRatio: 0.8,
                ),
                itemCount: _allItems.length,
                itemBuilder: (context, index) {
                  final item = _allItems[index];
                  final int count = _itemCounts[item.id] ?? 0;
                  final int level = item.getStage(count);
                  final bool isUnlocked = count > 0;
                  final Color itemColor = item.getColor(count);

                  return GestureDetector(
                    onTap: isUnlocked
                        ? () => _showResultDialog(item, count)
                        : null,
                    // ▼▼ 修正: kDebugModeの時だけ有効にする ▼▼
                    onLongPress: kDebugMode
                        ? () async {
                            final newCount = await _repository.unlockItem(
                              item.id,
                            );
                            await _loadData();
                            if (mounted) {
                              _showResultDialog(item, newCount);
                            }
                          }
                        : null,
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(15),
                        border: Border.all(
                          color: isUnlocked
                              ? itemColor.withOpacity(0.5)
                              : Colors.grey.shade200,
                          width: level == _maxLevel ? 3 : 1.5,
                        ),
                        boxShadow: [
                          if (isUnlocked)
                            BoxShadow(
                              color: itemColor.withOpacity(0.1),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                        ],
                      ),
                      child: Stack(
                        children: [
                          Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Expanded(
                                child: Center(
                                  child: isUnlocked
                                      ? Icon(
                                          item.iconData,
                                          size: 40,
                                          color: itemColor,
                                        )
                                      : Icon(
                                          Icons.lock,
                                          size: 30,
                                          color: Colors.grey.shade300,
                                        ),
                                ),
                              ),
                              if (isUnlocked)
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                  ),
                                  child: Column(
                                    children: [
                                      Text(
                                        "Lv.$level",
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                          color: itemColor,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      ClipRRect(
                                        borderRadius: BorderRadius.circular(2),
                                        child: LinearProgressIndicator(
                                          value: level / _maxLevel,
                                          minHeight: 4,
                                          backgroundColor: Colors.grey.shade100,
                                          color: itemColor,
                                        ),
                                      ),
                                    ],
                                  ),
                                )
                              else
                                const Text(
                                  "???",
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              const SizedBox(height: 10),
                            ],
                          ),
                          Positioned(
                            top: 8,
                            left: 8,
                            child: Text(
                              "No.${item.id}",
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: isUnlocked
                                    ? Colors.grey.shade500
                                    : Colors.grey.shade300,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
