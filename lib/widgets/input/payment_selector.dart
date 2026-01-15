import 'package:flutter/material.dart';
import '../../models/category_tag.dart';

class PaymentSelector extends StatefulWidget {
  final bool isCardPayment;
  final ValueChanged<bool> onToggle;
  final List<CategoryTag> cardList;
  final int selectedCardIndex;
  final ValueChanged<int> onCardSelected;
  final ValueChanged<CategoryTag>? onCardLongPress;

  const PaymentSelector({
    super.key,
    required this.isCardPayment,
    required this.onToggle,
    required this.cardList,
    required this.selectedCardIndex,
    required this.onCardSelected,
    this.onCardLongPress,
  });

  @override
  State<PaymentSelector> createState() => _PaymentSelectorState();
}

class _PaymentSelectorState extends State<PaymentSelector> {
  late PageController _pageController;
  late int _itemCount;

  @override
  void initState() {
    super.initState();
    _initController();
  }

  void _initController() {
    // 項目数 = 「記録しない(1つ)」 + カード数
    _itemCount = 1 + widget.cardList.length;

    // 現在の選択状態から初期ページ位置を計算 (0: 現金, 1~: カード)
    int initialOffset = 0;
    if (widget.isCardPayment) {
      initialOffset = 1 + widget.selectedCardIndex;
      // 範囲外チェック
      if (initialOffset >= _itemCount) initialOffset = 0;
    }

    // 無限スクロールに見せるため、十分に大きな数字を初期位置にする
    final int initialPage = (_itemCount * 1000) + initialOffset;

    _pageController = PageController(initialPage: initialPage);
  }

  @override
  void didUpdateWidget(covariant PaymentSelector oldWidget) {
    super.didUpdateWidget(oldWidget);
    // カードリストの数が変わったらコントローラーを作り直す
    if (widget.cardList.length != oldWidget.cardList.length) {
      _pageController.dispose();
      _initController();
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onPageChanged(int index) {
    final int actualIndex = index % _itemCount;

    if (actualIndex == 0) {
      // 0番目は「記録しない（現金）」
      if (widget.isCardPayment) {
        widget.onToggle(false);
      }
    } else {
      // 1番目以降は「カード」
      final int cardIndex = actualIndex - 1;
      if (!widget.isCardPayment || widget.selectedCardIndex != cardIndex) {
        widget.onToggle(true);
        widget.onCardSelected(cardIndex);
      }
    }
  }

  void _prevPage() {
    _pageController.previousPage(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  void _nextPage() {
    _pageController.nextPage(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    // カードがない場合（項目が1つしかない場合）は固定表示
    if (_itemCount <= 1) {
      return Container(
        height: 50,
        margin: const EdgeInsets.symmetric(vertical: 10),
        alignment: Alignment.center,
        child: _buildContent(0),
      );
    }

    return Container(
      height: 50,
      margin: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          // 左矢印
          IconButton(
            onPressed: _prevPage,
            icon: const Icon(Icons.chevron_left, color: Colors.grey),
            tooltip: '前へ',
          ),

          // スワイプ可能なメインエリア
          Expanded(
            child: PageView.builder(
              controller: _pageController,
              onPageChanged: _onPageChanged,
              itemBuilder: (context, index) {
                final int actualIndex = index % _itemCount;
                return Center(child: _buildContent(actualIndex));
              },
            ),
          ),

          // 右矢印
          IconButton(
            onPressed: _nextPage,
            icon: const Icon(Icons.chevron_right, color: Colors.grey),
            tooltip: '次へ',
          ),
        ],
      ),
    );
  }

  Widget _buildContent(int index) {
    if (index == 0) {
      // 現金（記録しない）
      return _buildChip(
        label: '記録しない',
        icon: Icons.wallet,
        color: Colors.grey,
        isCard: false,
        onLongPress: null, // 現金は長押しなし
      );
    } else {
      // カード
      final card = widget.cardList[index - 1];
      return _buildChip(
        label: card.label,
        icon: card.displayIcon,
        color: card.color,
        isCard: true,
        // 長押し処理を渡す
        onLongPress: widget.onCardLongPress != null
            ? () => widget.onCardLongPress!(card)
            : null,
      );
    }
  }

  Widget _buildChip({
    required String label,
    required IconData icon,
    required Color color,
    required bool isCard,
    VoidCallback? onLongPress,
  }) {
    // デザイン構造: Container(影/枠) > Material > InkWell > Padding > Row
    // InkWellを使うことで、スワイプ操作との競合に強くなり、長押し判定が安定します。
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(25),
        border: Border.all(color: color.withOpacity(0.5), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.1),
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(25),
        clipBehavior: Clip.antiAlias, // インクウェルがはみ出ないようにクリップ
        child: InkWell(
          onTap: () {}, // 空のonTapを入れることでタッチ判定を有効化
          onLongPress: onLongPress,
          splashColor: color.withOpacity(0.1),
          highlightColor: color.withOpacity(0.05),
          borderRadius: BorderRadius.circular(25),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, color: color, size: 20),
                const SizedBox(width: 8),
                Text(
                  label,
                  style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
