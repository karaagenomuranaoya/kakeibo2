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

  // ... 前略 (imports, State定義など)

  @override
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
            // --- 現在のステータス表示（青いパネル） ---
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

            // ▼▼ ListView内で _FlipBonusCard を呼び出し ▼▼
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
                  // めくり終わった後のタップ動作（詳細ダイアログ）
                  onDetailTap: () => _showBonusDetailDialog(item),
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

// ▼▼ 修正: _FlipBonusCard を StatefulWidget に変更し、タップ制御を追加 ▼▼

class _FlipBonusCard extends StatefulWidget {
  final BonusItem item;
  final bool isReached;
  final VoidCallback? onDetailTap;

  const _FlipBonusCard({
    super.key,
    required this.item,
    required this.isReached,
    this.onDetailTap,
  });

  @override
  State<_FlipBonusCard> createState() => _FlipBonusCardState();
}

class _FlipBonusCardState extends State<_FlipBonusCard>
    with AutomaticKeepAliveClientMixin {
  bool _isRevealed = false;

  @override
  bool get wantKeepAlive => true;

  void _handleTap() {
    if (!widget.isReached) return;
    if (!_isRevealed) {
      setState(() {
        _isRevealed = true;
      });
    } else {
      widget.onDetailTap?.call();
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    if (!widget.isReached) {
      return _buildLockedCard();
    }

    return GestureDetector(
      onTap: _handleTap,
      child: AnimatedSwitcher(
        // ゆっくり重厚感を出すために 1000ms (1秒) に設定
        duration: const Duration(milliseconds: 1000),
        // デフォルトのレイアウトだと重なり順がアニメーション中に変わることがあるため固定
        layoutBuilder: (Widget? currentChild, List<Widget> previousChildren) {
          return Stack(
            alignment: Alignment.center,
            children: <Widget>[
              ...previousChildren,
              if (currentChild != null) currentChild,
            ],
          );
        },
        transitionBuilder: (Widget child, Animation<double> animation) {
          // バウンド(Back)させず、滑らかに加減速する easeInOut を採用
          final anim = CurvedAnimation(
            parent: animation,
            curve: Curves.easeInOut,
          );

          return AnimatedBuilder(
            animation: anim,
            child: child,
            builder: (context, child) {
              final isBack = child!.key == const ValueKey('back');
              final value = anim.value;

              // ▼▼ 修正1: 角度計算（変更なし） ▼▼
              double angle;
              if (isBack) {
                // 裏面: 90 -> 0度 (右奥から手前へ)
                angle = (pi / 2) * (1.0 - value);
              } else {
                // 表面: 0 -> -90度 (手前から右奥へ)
                angle = -(pi / 2) * (1.0 - value);
              }

              // ▼▼ 修正2: 真横になる瞬間だけ透明にする ▼▼
              // value=1.0(正面) ~ value=0.0(真横)
              // valueが0.15以下（角度が約75度〜90度）になったら急激に透明にする
              // これにより「斜めの線」が出るタイミングを描画させない
              final double opacity = (value < 0.15) ? (value / 0.15) : 1.0;

              return Transform(
                transform: Matrix4.identity()
                  ..setEntry(3, 2, 0.001) // 遠近感
                  ..rotateY(angle), // Y軸回転
                alignment: Alignment.center,
                child: child,
              );
            },
          );
        },
        child: _isRevealed ? _buildRewardCard() : _buildReadyCard(),
      ),
    );
  }

  /// 未達成時のロックカード
  Widget _buildLockedCard() {
    return Container(
      // keyは重要ではないが、明示的に区別
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
                  "入力 ${widget.item.targetDays} 日達成",
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

  /// 達成済みだが、まだタップしていない状態のカード（表面）
  Widget _buildReadyCard() {
    return Container(
      key: const ValueKey('front'), // アニメーション判定用キー
      margin: const EdgeInsets.only(bottom: 12),
      width: double.infinity,
      height: 80, // ロック時と同じ高さ
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        // 達成感を出すためにボーダーの色を変える
        border: Border.all(color: widget.item.color.withOpacity(0.8), width: 2),
        boxShadow: [
          BoxShadow(
            color: widget.item.color.withOpacity(0.2),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          const SizedBox(width: 20),
          // アイコン部分：ギフトボックスや「！」など
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: widget.item.color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.card_giftcard, // プレゼントアイコン
              color: widget.item.color,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "MISSION CLEAR!",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: widget.item.color,
                    fontSize: 16,
                    fontStyle: FontStyle.italic,
                  ),
                ),
                Text(
                  "タップして報酬を確認",
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                ),
              ],
            ),
          ),
          // 右側のバッジ
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            margin: const EdgeInsets.only(right: 16),
            decoration: BoxDecoration(
              color: widget.item.color,
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  "OPEN",
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(width: 4),
                Icon(Icons.touch_app, size: 12, color: Colors.white),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// めくった後の報酬カード（裏面）
  Widget _buildRewardCard() {
    return Container(
      key: const ValueKey('back'), // アニメーション判定用キー
      margin: const EdgeInsets.only(bottom: 12),
      width: double.infinity,
      // 中身が多い場合に備えて高さは柔軟に（元のコード準拠）
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: widget.item.color.withOpacity(0.2),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(
          color: widget.item.color.withOpacity(0.3),
          width: 1.5,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: widget.item.color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(widget.item.icon, color: widget.item.color, size: 32),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  widget.item.title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  widget.item.description,
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
    );
  }
}
