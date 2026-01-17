import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../../repositories/gacha_repository.dart';
import '../../models/gacha_item.dart';

class GachaGameTab extends StatefulWidget {
  const GachaGameTab({super.key});

  @override
  State<GachaGameTab> createState() => _GachaGameTabState();
}

class _GachaGameTabState extends State<GachaGameTab>
    with AutomaticKeepAliveClientMixin {
  final GachaRepository _repository = GachaRepository();
  int _credits = 0;
  Map<String, int> _itemCounts = {};
  List<GachaItem> _allItems = [];
  bool _isLoading = true;

  static const int _maxLevel = 10;
  // 1回あたりの消費ポイント
  static const int _costPerSpin = 1;

  @override
  bool get wantKeepAlive => true; // タブ切り替え時に状態を維持

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

  void _showRateDialog() {
    final availableItems = _allItems.where((item) {
      final int count = _itemCounts[item.id] ?? 0;
      final int level = item.getStage(count);
      return level < _maxLevel;
    }).toList();

    final int totalAvailable = availableItems.length;

    if (totalAvailable == 0) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text("提供割合"),
          content: const Text("全てのキャラクターが最大レベルです。\n排出対象はありません。"),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("閉じる"),
            ),
          ],
        ),
      );
      return;
    }

    final double rate = 100.0 / totalAvailable;
    final String rateString = rate.toStringAsFixed(2);

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: const Text(
            "提供割合",
            style: TextStyle(fontWeight: FontWeight.bold),
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
                    final int count = _itemCounts[item.id] ?? 0;
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
      },
    );
  }

  Future<void> _spinGacha() async {
    if (_credits < _costPerSpin) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    final item = await _repository.drawItem();
    await Future.delayed(const Duration(seconds: 1));

    if (!mounted) return;
    Navigator.pop(context);

    if (item == null) {
      _showCompleteDialog();
      return;
    }

    final success = await _repository.consumeCredits(_costPerSpin);
    if (!success) return;

    final newCount = await _repository.unlockItem(item.id);
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

  // ▼▼ 省略されていた履歴ダイアログを復活 ▼▼
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

  // ▼▼ 結果ダイアログ（履歴ダイアログへのリンクを含む） ▼▼
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

              Container(
                constraints: const BoxConstraints(maxHeight: 80), // 高さを制限
                width: double.maxFinite, // 横幅を確保して中央揃えを維持
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
    super.build(context);

    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final int spins = _credits;
    final int maxLevelItems = _itemCounts.entries
        .where((e) => e.value >= _maxLevel)
        .length;
    final int totalItems = _allItems.length;
    final double completeRate = totalItems > 0 ? maxLevelItems / totalItems : 0;
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
                          "ガチャチケット",
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
                              " 枚",
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
                          : (spins > 0 ? "ガチャを回す (1枚消費)" : "入力をするとチケットが貰えます"),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        "※ガチャは完全無料です。課金要素はありません。",
                        style: TextStyle(fontSize: 10, color: Colors.grey),
                      ),
                    ],
                  ),
                ),
                if (!isAllComplete)
                  Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Align(
                      alignment: Alignment.centerRight,
                      child: TextButton.icon(
                        onPressed: _showRateDialog,
                        icon: const Icon(
                          Icons.info_outline,
                          size: 16,
                          color: Colors.grey,
                        ),
                        label: const Text(
                          "提供割合",
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey,
                            decoration: TextDecoration.underline,
                          ),
                        ),
                        style: TextButton.styleFrom(
                          padding: EdgeInsets.zero,
                          minimumSize: const Size(0, 0),
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
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
                    // デバッグモード(kDebugMode)の時だけロングプレスで強制アンロック
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
