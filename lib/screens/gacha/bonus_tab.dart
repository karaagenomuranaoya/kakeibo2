import 'package:flutter/material.dart';
import 'dart:math'; // アニメーション用
import '../../repositories/transaction_repository.dart';
import '../../models/transaction_item.dart';
// ▼▼ 追加: モデルとデータをインポート ▼▼
import '../../models/bonus_item.dart';
import '../../data/bonus_data.dart';

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

  // ※ ここにあった _bonusList 定義は削除し、BonusData.list を使用します

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

  // ▼▼ dev: デバッグ用チート機能 ▼▼
  Future<void> _devCheat() async {
    final dummyDate = DateTime(2000, 1, 1).add(Duration(days: _inputDays));
    final dummyItem = TransactionItem(
      amount: 100,
      expense: 'ボーナス確認用',
      payment: 'デバッグ',
      date: dummyDate,
      memo: 'Dev:InputCountUp',
    );

    await _txnRepository.addTransaction(dummyItem);
    await _loadBonusData();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Dev: 日数+1 (現在: $_inputDays日)'),
          duration: const Duration(milliseconds: 300),
        ),
      );
    }
  }

  // ▼▼ 詳細ダイアログを表示 ▼▼
  void _showBonusDetailDialog(BonusItem item) {
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
                "MISSION CLEAR!!",
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: item.color,
                  fontStyle: FontStyle.italic,
                  shadows: [
                    Shadow(
                      color: item.color.withOpacity(0.3),
                      offset: const Offset(2, 2),
                      blurRadius: 4,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 30),
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.grey.shade100,
                  border: Border.all(
                    color: item.color.withOpacity(0.5),
                    width: 4,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: item.color.withOpacity(0.2),
                      blurRadius: 15,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: Icon(item.icon, size: 60, color: item.color),
              ),
              const SizedBox(height: 20),
              Text(
                item.title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                "達成日数: ${item.targetDays}日",
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.grey,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),

              Container(
                constraints: const BoxConstraints(maxHeight: 200),
                width: double.maxFinite,
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      Text(
                        item.description,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.black54,
                          fontSize: 15,
                          height: 1.6,
                        ),
                      ),
                      const SizedBox(height: 20),
                      Divider(
                        color: item.color.withOpacity(0.2),
                        indent: 40,
                        endIndent: 40,
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: item.color,
                  foregroundColor: Colors.white,
                  shape: const StadiumBorder(),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 12,
                  ),
                ),
                child: const Text(
                  '閉じる',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
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

    return Scaffold(
      backgroundColor: Colors.blue.shade50,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // --- 現在のステータス表示 ---
            GestureDetector(
              onTap: _devCheat,
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

            // ▼▼ 修正: BonusData.list を使用 ▼▼
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: BonusData.list.length,
              itemBuilder: (context, index) {
                final item = BonusData.list[index];
                final bool isReached = _inputDays >= item.targetDays;

                return _FlipBonusCard(
                  item: item,
                  isReached: isReached,
                  onTap: isReached ? () => _showBonusDetailDialog(item) : null,
                );
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
  final VoidCallback? onTap;

  const _FlipBonusCard({
    required this.item,
    required this.isReached,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 800),
      transitionBuilder: (Widget child, Animation<double> animation) {
        final rotateAnim = Tween(begin: pi, end: 0.0).animate(animation);
        return AnimatedBuilder(
          animation: rotateAnim,
          child: child,
          builder: (context, child) {
            final isBack = child!.key == const ValueKey('front');
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
      layoutBuilder: (widget, list) =>
          Stack(children: [if (widget != null) widget, ...list]),
      switchInCurve: Curves.easeOutBack,
      switchOutCurve: Curves.easeInBack.flipped,
      child: isReached ? _buildRewardCard() : _buildLockedCard(),
    );
  }

  Widget _buildLockedCard() {
    return Container(
      key: const ValueKey('front'),
      margin: const EdgeInsets.only(bottom: 12),
      width: double.infinity,
      height: 80,
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

  Widget _buildRewardCard() {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        key: const ValueKey('back'),
        margin: const EdgeInsets.only(bottom: 12),
        width: double.infinity,
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
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: Colors.grey.shade400),
          ],
        ),
      ),
    );
  }
}
