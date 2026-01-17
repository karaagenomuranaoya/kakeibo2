import 'package:flutter/material.dart';
import 'dart:math'; // アニメーション用
import '../../repositories/transaction_repository.dart';
import '../../models/transaction_item.dart';

// ボーナスアイテムのデータ定義
class BonusItem {
  final int targetDays;
  final IconData icon;
  final Color color;
  final String title;
  final String description;

  const BonusItem({
    required this.targetDays,
    required this.icon,
    required this.color,
    required this.title,
    required this.description,
  });
}

class BonusTab extends StatefulWidget {
  const BonusTab({super.key});

  @override
  State<BonusTab> createState() => _BonusTabState();
}

class _BonusTabState extends State<BonusTab>
    with AutomaticKeepAliveClientMixin {
  final TransactionRepository _txnRepository = TransactionRepository();
  int _inputDays = 0;
  bool _isLoading = true;

  // ボーナスデータ一覧
  final List<BonusItem> _bonusList = const [
    BonusItem(
      targetDays: 3,
      icon: Icons.save,
      color: Colors.green,
      title: "芽生えの精霊",
      description: "家計簿生活の第一歩。\n小さな芽が出てきました。",
    ),
    BonusItem(
      targetDays: 7,
      icon: Icons.directions_walk,
      color: Colors.orange,
      title: "ウォーキングマン",
      description: "継続は力なり。\n毎日コツコツ歩き続けよう。",
    ),
    BonusItem(
      targetDays: 14,
      icon: Icons.rowing,
      color: Colors.blue,
      title: "ボート漕ぎの達人",
      description: "荒波もなんのその。\n流れに乗って進め。",
    ),
    BonusItem(
      targetDays: 21,
      icon: Icons.flight_takeoff,
      color: Colors.indigo,
      title: "ジェットパイロット",
      description: "習慣が板についてきた。\n空高く舞い上がれ。",
    ),
    BonusItem(
      targetDays: 30,
      icon: Icons.diamond,
      color: Colors.cyan,
      title: "クリスタルガーディアン",
      description: "1ヶ月の継続の証。\n硬い意志は宝石の輝き。",
    ),
    BonusItem(
      targetDays: 50,
      icon: Icons.rocket_launch,
      color: Colors.redAccent,
      title: "マーズボイジャー",
      description: "とどまることを知らない。\n目指すは遥か彼方。",
    ),
    BonusItem(
      targetDays: 100,
      icon: Icons.auto_awesome,
      color: Colors.amber,
      title: "伝説の記録者",
      description: "百日の記録を刻みし者。\nその背中には後光が差す。",
    ),
    BonusItem(
      targetDays: 365,
      icon: Icons.castle,
      color: Colors.purple,
      title: "一年城の王",
      description: "四季を巡り辿り着いた。\nここはあなたの城。",
    ),
  ];

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _loadBonusData();
  }

  Future<void> _loadBonusData() async {
    await _txnRepository.getAllTransactions();
    final days = _txnRepository.getUniqueInputDaysCount();

    if (mounted) {
      setState(() {
        _inputDays = days;
        _isLoading = false;
      });
    }
  }

  // ▼▼ dev: デバッグ用チート機能 (チケット配布削除、日数追加のみ) ▼▼
  Future<void> _devCheat() async {
    // 1. 日数を増やす（過去のユニークな日付にダミーデータを入れる）
    final dummyDate = DateTime(2000, 1, 1).add(Duration(days: _inputDays));

    final dummyItem = TransactionItem(
      amount: 100,
      expense: 'ボーナス確認用',
      payment: 'デバッグ',
      date: dummyDate,
      memo: 'Dev:InputCountUp',
    );

    await _txnRepository.addTransaction(dummyItem);

    // 2. UI更新
    await _loadBonusData(); // 日数再計算

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Dev: 日数+1 (現在: $_inputDays日)'),
          duration: const Duration(milliseconds: 300),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      backgroundColor: Colors.blue.shade50,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // --- 現在のステータス表示 ---
            GestureDetector(
              onTap: _devCheat, // タップで日数増加
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.blue.shade400, Colors.blue.shade700],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.blue.withOpacity(0.3),
                      blurRadius: 10,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    const Text(
                      "累計入力日数",
                      style: TextStyle(color: Colors.white70, fontSize: 14),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        Text(
                          "$_inputDays",
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 48,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          "日",
                          style: TextStyle(color: Colors.white, fontSize: 18),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      "青いパネルをタップで日数進行(Dev)",
                      style: TextStyle(color: Colors.white54, fontSize: 10),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // --- ボーナス一覧 ---
            const Align(
              alignment: Alignment.centerLeft,
              child: Text(
                "入力ボーナス",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ),
            const SizedBox(height: 12),

            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _bonusList.length,
              itemBuilder: (context, index) {
                final item = _bonusList[index];
                final bool isReached = _inputDays >= item.targetDays;

                return _FlipBonusCard(item: item, isReached: isReached);
              },
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}

/// フリップアニメーションを行うカードウィジェット
class _FlipBonusCard extends StatelessWidget {
  final BonusItem item;
  final bool isReached;

  const _FlipBonusCard({required this.item, required this.isReached});

  @override
  Widget build(BuildContext context) {
    // AnimatedSwitcherでWidgetの切り替え時にアニメーションを入れる
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 800),
      transitionBuilder: (Widget child, Animation<double> animation) {
        // 回転アニメーション (Y軸)
        final rotateAnim = Tween(begin: pi, end: 0.0).animate(animation);
        return AnimatedBuilder(
          animation: rotateAnim,
          child: child,
          builder: (context, child) {
            final isBack = child!.key == const ValueKey('front');
            final value = isBack
                ? min(rotateAnim.value, pi / 2)
                : rotateAnim.value;

            // 90度を超えたらコンテンツを裏返すかどうかの制御が必要だが、
            // AnimatedSwitcherはWidgetを入れ替えるため、
            // ここでは単純にY軸回転を適用する。
            // 奥行きを出すためにMatrix4を使用
            var tilt = ((animation.value - 0.5).abs() - 0.5) * 0.003;
            tilt *= isBack ? -1.0 : 1.0;
            final angle = isBack
                ? min(rotateAnim.value, pi / 2)
                : rotateAnim.value;

            return Transform(
              transform: Matrix4.rotationY(angle)..setEntry(3, 2, 0.001),
              alignment: Alignment.center,
              child: child,
            );
          },
        );
      },
      // layoutBuilderを指定しないとデフォルトのフェード等が混ざることがある
      layoutBuilder: (widget, list) =>
          Stack(children: [if (widget != null) widget, ...list]),
      switchInCurve: Curves.easeOutBack,
      switchOutCurve: Curves.easeInBack.flipped,
      child: isReached
          ? _buildRewardCard() // 達成時（裏面・報酬）
          : _buildLockedCard(), // 未達成時（表面・ロック）
    );
  }

  // 表面：ロック状態
  Widget _buildLockedCard() {
    return Container(
      key: const ValueKey('front'),
      margin: const EdgeInsets.only(bottom: 12),
      width: double.infinity,
      height: 80, // 高さを固定してフリップ時のガタつきを防ぐ
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Row(
        children: [
          const SizedBox(width: 20),
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.lock, color: Colors.grey),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "入力 ${item.targetDays} 日達成",
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.grey,
                    fontSize: 16,
                  ),
                ),
                const Text(
                  "？？？",
                  style: TextStyle(color: Colors.grey, fontSize: 12),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            margin: const EdgeInsets.only(right: 16),
            decoration: BoxDecoration(
              color: Colors.grey.shade200,
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Text(
              "未達成",
              style: TextStyle(
                fontSize: 10,
                color: Colors.grey,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // 裏面：報酬状態（キャラクター出現）
  Widget _buildRewardCard() {
    return Container(
      key: const ValueKey('back'),
      margin: const EdgeInsets.only(bottom: 12),
      width: double.infinity,
      // height: 100, // 少し大きくしても良いが、揃えるために高さを自動または固定
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: item.color.withOpacity(0.2),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: item.color.withOpacity(0.3), width: 1.5),
      ),
      child: Row(
        children: [
          // 左側：アイコン
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: item.color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(item.icon, color: item.color, size: 32),
          ),
          const SizedBox(width: 16),
          // 右側：タイトルと説明
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  item.title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  item.description,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
