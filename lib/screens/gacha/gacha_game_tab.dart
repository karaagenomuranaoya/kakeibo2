import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tutorial_coach_mark/tutorial_coach_mark.dart';
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
  static const int _costPerSpin = 1;

  final GlobalKey _ticketKey = GlobalKey(); // チケット表示場所の目印
  final GlobalKey _spinButtonKey = GlobalKey(); // ガチャボタンの目印
  // ▼▼▼ 追加: ヘッダー（上部エリア）全体の目印 ▼▼▼
  final GlobalKey _headerKey = GlobalKey();
  // ▲▲▲ 追加ここまで ▲▲▲

  bool _pendingTutorialPhase2 = false; // 「結果画面の後に続きを表示する」フラグ

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  // ▼▼▼ チュートリアル Phase 1 (導入〜回すまで) ▼▼▼
  Future<void> _checkTutorialPhase1() async {
    final prefs = await SharedPreferences.getInstance();
    final bool isShown = prefs.getBool('is_gacha_tutorial_shown_v1') ?? false;

    // まだ表示しておらず、かつチケットがある(初回ボーナス等)場合のみ実行
    if (!isShown && mounted && _credits > 0) {
      _showTutorialPhase1();
      // Phase1が終わったら、ガチャを回した後にPhase2を表示するよう予約
      _pendingTutorialPhase2 = true;
    }
  }

  Future<void> _completeTutorial() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('is_gacha_tutorial_shown_v1', true);
    // _pendingTutorialPhase2 = false; // ← 削除（Phase 2の予約フラグは消さない）
  }

  void _showTutorialPhase1() {
    TutorialCoachMark(
      targets: [
        // 1. ガチャタブ全体の導入
        TargetFocus(
          identify: "gacha_intro",
          // ▼▼▼ 修正: null ではなくヘッダーを指定してエラー回避 ▼▼▼
          keyTarget: _headerKey,
          alignSkip: Alignment.topRight,
          shape: ShapeLightFocus.RRect, // ヘッダーの形に合わせて四角く光らせる
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
        // 2. チケットの説明
        TargetFocus(
          identify: "ticket_info",
          keyTarget: _ticketKey, // チケット部分をハイライト
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
        // 3. ガチャボタンへ誘導
        TargetFocus(
          identify: "spin_button",
          keyTarget: _spinButtonKey, // ボタン部分をハイライト
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
      // ▼▼▼ 追加: 最後まで見終わった時も保存する ▼▼▼
      onFinish: () => _completeTutorial(),
      // ▲▲▲ 追加ここまで ▲▲▲
      onSkip: () {
        _completeTutorial();
        return true;
      },
    ).show(context: context);
  }
  // ▲▲▲ Phase 1 ここまで ▲▲▲

  // ▼▼▼ チュートリアル Phase 2 (結果画面後の解説) ▼▼▼
  Future<void> _showTutorialPhase2() async {
    if (!mounted) return;
    await _completeTutorial();

    TutorialCoachMark(
      targets: [
        // 1. 進化とテキストについて
        TargetFocus(
          identify: "gacha_explain_evolution",
          // ▼▼▼ 修正: null ではなくヘッダーを指定 ▼▼▼
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
        // 2. アイコン利用について
        TargetFocus(
          identify: "gacha_explain_icon",
          // ▼▼▼ 修正: null ではなくヘッダーを指定 ▼▼▼
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
  // ▲▲▲ Phase 2 ここまで ▲▲▲

  Future<void> _loadData() async {
    // データ取得前にボーナス付与を確実に実行
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

      // UIの描画完了を待ってからチュートリアルチェック
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _checkTutorialPhase1();
      });
    }
  }

  // （... _showRateDialog, _showCompleteDialog, _showHistoryDialog, _showResultDialog は変更なし ...）
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
    // ▼▼▼ 追加: ボタンを押したら強制的に導入完了扱いにする ▼▼▼
    await _completeTutorial();
    // ▲▲▲ 追加ここまで ▲▲▲
    if (_credits < _costPerSpin) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    final item = await _repository.drawItem();
    await Future.delayed(const Duration(seconds: 1));

    if (!mounted) return;
    Navigator.pop(context); // ローディングを閉じる

    if (item == null) {
      _showCompleteDialog();
      return;
    }

    final success = await _repository.consumeCredits(_costPerSpin);
    if (!success) return;

    final newCount = await _repository.unlockItem(item.id);
    await _loadData();

    if (mounted) {
      // ダイアログが閉じるのを待つ
      await _showResultDialog(item, newCount);

      // Phase 1 からの続きがあれば Phase 2 を実行
      if (_pendingTutorialPhase2) {
        _pendingTutorialPhase2 = false;
        // 少し間を置いてから表示すると自然です
        await Future.delayed(const Duration(milliseconds: 300));
        _showTutorialPhase2();
      }
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

  Future<void> _showResultDialog(GachaItem item, int count) {
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

    return showDialog(
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
    final bool isAllComplete = maxLevelItems == totalItems && totalItems > 0;

    return Scaffold(
      backgroundColor: Colors.yellow.shade50,
      body: Column(
        children: [
          Container(
            // ▼▼▼ 追加: キーを設定してチュートリアルのターゲットにする ▼▼▼
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
                // ... (以下のヘッダーコンテンツは変更なし) ...
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
                      // 左側：チケット所持数表示
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

                      // 右側：提供割合ボタン
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
