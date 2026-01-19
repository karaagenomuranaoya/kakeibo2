import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../repositories/gacha_repository.dart';
import '../../models/gacha_item.dart';

import 'dialogs/gacha_rate_dialog.dart';
import 'dialogs/gacha_result_dialog.dart';
import 'dialogs/gacha_complete_dialog.dart';
import 'dialogs/gacha_tutorial_content.dart';

import 'widgets/gacha_header.dart';
import 'widgets/gacha_item_tile.dart';
import 'widgets/gacha_action_panel.dart';

class GachaGameTab extends StatefulWidget {
  // ▼▼ 追加: 親からバージョン番号を受け取る ▼▼
  final int dataVersion;

  // ▼▼ 修正: コンストラクタで dataVersion を受け取るように変更 ▼▼
  const GachaGameTab({super.key, this.dataVersion = 0});

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
  final GlobalKey _topBarKey = GlobalKey();
  final GlobalKey _gridKey = GlobalKey();

  bool _pendingTutorialPhase2 = false;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  // ▼▼ 追加: 親から更新通知(dataVersion変更)が来たらリロードする ▼▼
  @override
  void didUpdateWidget(covariant GachaGameTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.dataVersion != widget.dataVersion) {
      _loadData();
    }
  }
  // ▲▲ 追加ここまで ▲▲

  // --- チュートリアル関連 ---
  static const String _tutorialKey = 'is_gacha_tutorial_shown';

  Future<void> _checkTutorialPhase1() async {
    final prefs = await SharedPreferences.getInstance();
    final bool isShown = prefs.getBool(_tutorialKey) ?? false;

    // クレジット(チケット)を持っている場合のみチュートリアルを表示
    if (!isShown && mounted && _credits > 0) {
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted) _showTutorialPhase1();
      });
      _pendingTutorialPhase2 = true;
    }
  }

  Future<void> _completeTutorial() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_tutorialKey, true);
  }

  void _showTutorialPhase1() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return GachaTutorialContent.phase1(
          onDismiss: () async {
            Navigator.pop(context);
            await _completeTutorial();
          },
        );
      },
    );
  }

  Future<void> _showTutorialPhase2() async {
    if (!mounted) return;
    await _completeTutorial();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return GachaTutorialContent.phase2(
          onDismiss: () {
            Navigator.pop(context);
          },
        );
      },
    );
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

      // データ読み込み完了後にチュートリアルチェック
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _checkTutorialPhase1();
      });
    }
  }

  void _showRateDialog() {
    showDialog(
      context: context,
      builder: (context) =>
          GachaRateDialog(allItems: _allItems, itemCounts: _itemCounts),
    );
  }

  Future<void> _spinGacha() async {
    // スピン開始時にも念のためチュートリアル完了とする
    await _completeTutorial();

    if (_credits < _costPerSpin) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final item = await _repository.drawItem();
      await Future.delayed(const Duration(seconds: 1));

      if (!mounted) return;
      Navigator.of(context).pop();

      if (item == null) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text("エラー: アイテムデータがありません")));
        return;
      }

      final success = await _repository.consumeCredits(_costPerSpin);
      if (!success) return;

      final newCount = await _repository.unlockItem(item.id);
      await _loadData();

      if (!mounted) return;

      await HapticFeedback.heavyImpact();
      await _showResultDialog(item, newCount);

      if (newCount == _maxLevel) {
        final maxLevelItems = _itemCounts.entries
            .where((e) => e.value >= _maxLevel)
            .length;
        final isAllComplete =
            maxLevelItems == _allItems.length && _allItems.isNotEmpty;

        if (isAllComplete) {
          await Future.delayed(const Duration(milliseconds: 300));
          if (mounted) _showCompleteDialog();
        }
      }

      if (_pendingTutorialPhase2) {
        _pendingTutorialPhase2 = false;
        await Future.delayed(const Duration(milliseconds: 500));
        if (mounted) _showTutorialPhase2();
      }
    } catch (e) {
      debugPrint("Gacha Error: $e");
      if (mounted && Navigator.canPop(context)) {
        Navigator.of(context).pop();
      }
    }
  }

  void _showCompleteDialog() {
    showDialog(
      context: context,
      builder: (context) => const GachaCompleteDialog(),
    );
  }

  Future<void> _showResultDialog(GachaItem item, int count) async {
    await showDialog(
      context: context,
      barrierDismissible: false,
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
      backgroundColor: Colors.white,
      body: Column(
        children: [
          GachaHeader(
            key: _topBarKey,
            ticketCount: spins,
            onRatePressed: _showRateDialog,
            ticketKey: _ticketKey,
          ),
          Expanded(
            child: GridView.builder(
              key: _gridKey,
              padding: const EdgeInsets.all(16),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 0.8,
              ),
              itemCount: _allItems.length,
              itemBuilder: (context, index) {
                final item = _allItems[index];
                final int count = _itemCounts[item.id] ?? 0;

                return GachaItemTile(
                  item: item,
                  count: count,
                  maxLevel: _maxLevel,
                  onTap: () => _showResultDialog(item, count),
                  onLongPress: kDebugMode
                      ? () async {
                          final newCount = await _repository.unlockItem(
                            item.id,
                          );
                          await _loadData();
                          if (mounted) _showResultDialog(item, newCount);
                        }
                      : null,
                );
              },
            ),
          ),
          GachaActionPanel(
            buttonKey: _spinButtonKey,
            isAllComplete: isAllComplete,
            ticketCount: spins,
            onSpin: spins > 0 ? _spinGacha : null,
          ),
        ],
      ),
    );
  }
}
