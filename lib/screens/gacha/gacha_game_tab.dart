import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tutorial_coach_mark/tutorial_coach_mark.dart';
import '../../repositories/gacha_repository.dart';
import '../../models/gacha_item.dart';

// ▼▼▼ 新規作成したダイアログをインポート ▼▼▼
import 'dialogs/gacha_rate_dialog.dart';
import 'dialogs/gacha_result_dialog.dart';
import 'dialogs/gacha_complete_dialog.dart';
// ▲▲▲ インポートここまで ▲▲▲

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
  static const int _costPerSpin = 1;

  final GlobalKey _ticketKey = GlobalKey();
  final GlobalKey _spinButtonKey = GlobalKey();
  final GlobalKey _headerKey = GlobalKey();

  bool _pendingTutorialPhase2 = false;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  // --- チュートリアル関連メソッド (変更なし) ---
  Future<void> _checkTutorialPhase1() async {
    final prefs = await SharedPreferences.getInstance();
    final bool isShown = prefs.getBool('is_gacha_tutorial_shown_v1') ?? false;

    if (!isShown && mounted && _credits > 0) {
      _showTutorialPhase1();
      _pendingTutorialPhase2 = true;
    }
  }

  Future<void> _completeTutorial() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('is_gacha_tutorial_shown_v1', true);
  }

  void _showTutorialPhase1() {
    TutorialCoachMark(
      targets: [
        TargetFocus(
          identify: "gacha_intro",
          keyTarget: _headerKey,
          alignSkip: Alignment.topRight,
          shape: ShapeLightFocus.RRect,
          radius: 12,
          contents: [
            TargetContent(
              align: ContentAlign.bottom,
              builder: (context, controller) {
                return Column(
                  mainAxisSize: MainAxisSize.min,
                  children: const [
                    Icon(
                      Icons.collections_bookmark,
                      size: 60,
                      color: Colors.orange,
                    ),
                    SizedBox(height: 20),
                    Text(
                      "コレクション画面へようこそ",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        fontSize: 24,
                      ),
                    ),
                    SizedBox(height: 10),
                    Text(
                      "ここではガチャと入力日数ボーナスで\nキャラクターを集められます。",
                      style: TextStyle(color: Colors.white, fontSize: 16),
                      textAlign: TextAlign.center,
                    ),
                  ],
                );
              },
            ),
          ],
        ),
        TargetFocus(
          identify: "ticket_info",
          keyTarget: _ticketKey,
          alignSkip: Alignment.bottomRight,
          shape: ShapeLightFocus.RRect,
          radius: 12,
          contents: [
            TargetContent(
              align: ContentAlign.bottom,
              builder: (context, controller) {
                return Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text(
                      "ガチャチケット",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        fontSize: 20,
                      ),
                    ),
                    SizedBox(height: 10),
                    Text(
                      "チケットは本来、入力で1日5枚まで\n手に入るのですが...",
                      style: TextStyle(color: Colors.white, fontSize: 16),
                    ),
                  ],
                );
              },
            ),
          ],
        ),
        TargetFocus(
          identify: "spin_button",
          keyTarget: _spinButtonKey,
          alignSkip: Alignment.topRight,
          shape: ShapeLightFocus.RRect,
          radius: 4,
          contents: [
            TargetContent(
              align: ContentAlign.top,
              builder: (context, controller) {
                return Column(
                  mainAxisSize: MainAxisSize.min,
                  children: const [
                    Text(
                      "今はお試し用のが3枚あるので、\n早速回してみましょう！",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        fontSize: 18,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: 10),
                    Icon(Icons.arrow_downward, color: Colors.white, size: 40),
                  ],
                );
              },
            ),
          ],
        ),
      ],
      colorShadow: Colors.black,
      textSkip: "スキップ",
      paddingFocus: 10,
      opacityShadow: 0.8,
      onSkip: () {
        _completeTutorial();
        return true;
      },
      onFinish: () => _completeTutorial(),
    ).show(context: context);
  }

  Future<void> _showTutorialPhase2() async {
    if (!mounted) return;
    await _completeTutorial();

    TutorialCoachMark(
      targets: [
        TargetFocus(
          identify: "gacha_explain_evolution",
          keyTarget: _headerKey,
          alignSkip: Alignment.topRight,
          shape: ShapeLightFocus.RRect,
          contents: [
            TargetContent(
              align: ContentAlign.bottom,
              builder: (context, controller) {
                return Column(
                  mainAxisSize: MainAxisSize.min,
                  children: const [
                    Icon(
                      Icons.auto_awesome,
                      size: 60,
                      color: Colors.yellowAccent,
                    ),
                    SizedBox(height: 20),
                    Text(
                      "進化とストーリー",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        fontSize: 22,
                      ),
                    ),
                    SizedBox(height: 10),
                    Text(
                      "ガチャではさまざまなキャラクターが手に入ります。\n同じのが出ると進化してどんどん強くなっていきます。\n\n暇があれば詳細のテキストも読んでみてください。",
                      style: TextStyle(color: Colors.white, fontSize: 16),
                      textAlign: TextAlign.center,
                    ),
                  ],
                );
              },
            ),
          ],
        ),
        TargetFocus(
          identify: "gacha_explain_icon",
          keyTarget: _headerKey,
          alignSkip: Alignment.topRight,
          shape: ShapeLightFocus.RRect,
          contents: [
            TargetContent(
              align: ContentAlign.bottom,
              builder: (context, controller) {
                return Column(
                  mainAxisSize: MainAxisSize.min,
                  children: const [
                    Icon(
                      Icons.category,
                      size: 60,
                      color: Colors.lightBlueAccent,
                    ),
                    SizedBox(height: 20),
                    Text(
                      "アイコンとして使う",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        fontSize: 22,
                      ),
                    ),
                    SizedBox(height: 10),
                    Text(
                      "出たキャラクターは、\nカテゴリ編集画面でアイコンとして使えます。\n\nお気に入りのキャラで家計簿を彩ってください！",
                      style: TextStyle(color: Colors.white, fontSize: 16),
                      textAlign: TextAlign.center,
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ],
      colorShadow: Colors.black,
      textSkip: "完了",
      paddingFocus: 10,
      opacityShadow: 0.8,
    ).show(context: context);
  }
  // --- チュートリアルここまで ---

  Future<void> _loadData() async {
    await _repository.checkInitialBonus();
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

      WidgetsBinding.instance.addPostFrameCallback((_) {
        _checkTutorialPhase1();
      });
    }
  }

  // ▼▼▼ リファクタリング: メソッドの中身をシンプルに ▼▼▼
  void _showRateDialog() {
    showDialog(
      context: context,
      builder: (context) =>
          GachaRateDialog(allItems: _allItems, itemCounts: _itemCounts),
    );
  }

  Future<void> _spinGacha() async {
    await _completeTutorial();

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
      await _showResultDialog(item, newCount);

      if (_pendingTutorialPhase2) {
        _pendingTutorialPhase2 = false;
        await Future.delayed(const Duration(milliseconds: 300));
        _showTutorialPhase2();
      }
    }
  }

  // ▼▼▼ リファクタリング: メソッドの中身をシンプルに ▼▼▼
  void _showCompleteDialog() {
    showDialog(
      context: context,
      builder: (context) => const GachaCompleteDialog(),
    );
  }

  // ▼▼▼ リファクタリング: メソッドの中身をシンプルに ▼▼▼
  Future<void> _showResultDialog(GachaItem item, int count) {
    return showDialog(
      context: context,
      builder: (context) => GachaResultDialog(item: item, count: count),
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
    final bool isAllComplete = maxLevelItems == totalItems && totalItems > 0;

    return Scaffold(
      backgroundColor: Colors.yellow.shade50,
      body: Column(
        children: [
          Container(
            key: _headerKey,
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
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    key: _spinButtonKey,
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
                Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Container(
                        key: _ticketKey,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.orange.shade50,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.orange.shade200),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.confirmation_number,
                              size: 16,
                              color: Colors.orange.shade800,
                            ),
                            const SizedBox(width: 4),
                            const Text(
                              "×",
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.brown,
                              ),
                            ),
                            const SizedBox(width: 2),
                            Text(
                              "$_credits",
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.brown,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (!isAllComplete)
                        TextButton.icon(
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
                    ],
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
