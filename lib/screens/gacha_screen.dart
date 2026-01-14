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

  // 進化に必要な枚数定義
  static const int _evo2Count = 5; // 第2形態へ
  static const int _evo3Count = 10; // 第3形態へ

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

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );
    await Future.delayed(const Duration(seconds: 1));
    if (!mounted) return;
    Navigator.pop(context);

    final success = await _repository.consumeCredits(3);
    if (!success) return;

    final item = await _repository.drawItem();
    final newCount = await _repository.unlockItem(item.id);

    await _loadData();

    if (mounted) {
      _showResultDialog(item, newCount);
    }
  }

  void _showResultDialog(GachaItem item, int count) {
    final bool isNew = count == 1;
    final bool isEvo2 = count == _evo2Count;
    final bool isEvo3 = count == _evo3Count;
    final bool isMax = count > _evo3Count;

    String title = "GET!!";
    Color titleColor = Colors.orange;

    if (isNew) {
      title = "NEW GET!!";
      titleColor = Colors.redAccent;
    } else if (isEvo3) {
      title = "FINAL EVOLUTION!!"; // 最終進化
      titleColor = Colors.purpleAccent;
    } else if (isEvo2) {
      title = "EVOLUTION!!";
      titleColor = Colors.deepPurpleAccent;
    } else if (isMax) {
      title = "DUPLICATE";
      titleColor = Colors.grey;
    }

    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: titleColor,
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                height: 150,
                width: 150,
                child: Image.asset(
                  item.getImagePath(count),
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) {
                    return const Icon(
                      Icons.broken_image,
                      size: 80,
                      color: Colors.grey,
                    );
                  },
                ),
              ),
              const SizedBox(height: 10),
              _buildRarityBadge(item.rarity),
              const SizedBox(height: 10),
              Text(
                item.getName(count),
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                item.getDescription(count),
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 10),

              // --- ゲージ表示ロジック ---
              if (count < _evo2Count) ...[
                // Lv1 -> Lv2
                _buildProgressSection(count, _evo2Count, "進化"),
              ] else if (count < _evo3Count) ...[
                // Lv2 -> Lv3
                _buildProgressSection(
                  count - _evo2Count,
                  _evo3Count - _evo2Count,
                  "最終進化",
                  baseCount: _evo2Count,
                ),
              ] else if (isEvo3) ...[
                const SizedBox(height: 10),
                const Text(
                  "究極覚醒しました！",
                  style: TextStyle(
                    color: Colors.purple,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ] else ...[
                // Max後
                const SizedBox(height: 10),
                const Text("限界突破中！", style: TextStyle(color: Colors.grey)),
              ],

              const SizedBox(height: 20),
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

  Widget _buildProgressSection(
    int current,
    int max,
    String label, {
    int baseCount = 0,
  }) {
    return Column(
      children: [
        const SizedBox(height: 10),
        Text(
          "$labelまで",
          style: const TextStyle(fontSize: 12, color: Colors.grey),
        ),
        const SizedBox(height: 5),
        SizedBox(
          width: 150,
          child: LinearProgressIndicator(
            value: current / max,
            backgroundColor: Colors.grey.shade200,
            color: Colors.blue,
            minHeight: 10,
          ),
        ),
        Text(
          "${baseCount + current} / ${baseCount + max}",
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  Widget _buildRarityBadge(int rarity) {
    Color color;
    String label;
    switch (rarity) {
      case 5:
        color = Colors.purple;
        label = "UR";
        break;
      case 4:
        color = Colors.orange;
        label = "SSR";
        break;
      case 3:
        color = Colors.blue;
        label = "SR";
        break;
      case 2:
        color = Colors.green;
        label = "R";
        break;
      default:
        color = Colors.grey;
        label = "N";
        break;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  // --- 一覧画面のバッジ ---
  Widget _buildMiniBadge(int rarity) {
    Color color;
    String text;
    if (rarity == 5) {
      color = Colors.purple;
      text = "UR";
    } else if (rarity == 4) {
      color = Colors.orange;
      text = "SSR";
    } else {
      return const SizedBox.shrink();
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 8,
          fontWeight: FontWeight.bold,
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
    final int unlockedCount = _itemCounts.keys.length;
    final int totalItems = _allItems.length;
    final double completeRate = totalItems > 0 ? unlockedCount / totalItems : 0;

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
                          "収集率",
                          style: TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                        Text(
                          "$unlockedCount / $totalItems (${(completeRate * 100).toStringAsFixed(0)}%)",
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
                      backgroundColor: Colors.orange,
                      foregroundColor: Colors.white,
                      disabledBackgroundColor: Colors.grey.shade300,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: Text(
                      spins > 0
                          ? "ガチャを回す (3pt)"
                          : "あと ${3 - (_credits % 3)} 回入力でガチャ",
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
              padding: const EdgeInsets.all(10),
              child: GridView.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  crossAxisSpacing: 8,
                  mainAxisSpacing: 8,
                  childAspectRatio: 0.75,
                ),
                itemCount: _allItems.length,
                itemBuilder: (context, index) {
                  final item = _allItems[index];
                  final int count = _itemCounts[item.id] ?? 0;
                  final bool isUnlocked = count > 0;
                  final int stage = item.getStage(count); // 現在のステージ

                  return GestureDetector(
                    onTap: isUnlocked
                        ? () => _showResultDialog(item, count)
                        : null,
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          // ステージによって枠の色を変える
                          color: stage == 3
                              ? Colors.purple.shade200
                              : stage == 2
                              ? Colors.blue.shade200
                              : isUnlocked
                              ? Colors.orange.shade100
                              : Colors.grey.shade200,
                          width: stage >= 2 ? 3 : 2,
                        ),
                      ),
                      child: Stack(
                        children: [
                          Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Expanded(
                                child: Padding(
                                  padding: const EdgeInsets.all(8.0),
                                  child: isUnlocked
                                      ? Image.asset(
                                          item.getImagePath(count),
                                          fit: BoxFit.contain,
                                          errorBuilder: (c, e, s) => const Icon(
                                            Icons.broken_image,
                                            color: Colors.grey,
                                          ),
                                        )
                                      : Icon(
                                          Icons.help_outline,
                                          size: 40,
                                          color: Colors.grey.shade300,
                                        ),
                                ),
                              ),
                              // ゲージ (進化途中のみ表示)
                              if (isUnlocked && count < _evo3Count)
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 2,
                                  ),
                                  child: LinearProgressIndicator(
                                    // Lv1なら /5, Lv2なら (c-5)/5
                                    value: count < _evo2Count
                                        ? count / _evo2Count
                                        : (count - _evo2Count) /
                                              (_evo3Count - _evo2Count),
                                    minHeight: 4,
                                    backgroundColor: Colors.grey.shade200,
                                    color: Colors.blueAccent,
                                  ),
                                ),
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 4,
                                  horizontal: 2,
                                ),
                                color: isUnlocked
                                    ? Colors.orange.shade50
                                    : Colors.grey.shade100,
                                child: Text(
                                  isUnlocked ? item.getName(count) : "???",
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: isUnlocked
                                        ? Colors.black
                                        : Colors.grey,
                                  ),
                                  textAlign: TextAlign.center,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                          if (isUnlocked)
                            Positioned(
                              top: 4,
                              right: 4,
                              child: _buildMiniBadge(item.rarity),
                            ),
                          // 最終進化マーク
                          if (stage == 3)
                            const Positioned(
                              top: 4,
                              left: 4,
                              child: Icon(
                                Icons.auto_awesome,
                                color: Colors.purple,
                                size: 16,
                              ),
                            ),
                          // 第2形態マーク
                          if (stage == 2)
                            const Positioned(
                              top: 4,
                              left: 4,
                              child: Icon(
                                Icons.arrow_upward,
                                color: Colors.blue,
                                size: 16,
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
