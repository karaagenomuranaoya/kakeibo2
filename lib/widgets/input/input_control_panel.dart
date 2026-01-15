import 'package:flutter/material.dart';
import '../../models/category_tag.dart';

class InputControlPanel extends StatelessWidget {
  final bool isCardPayment;
  final ValueChanged<bool> onToggleCard;
  final List<CategoryTag> cardList;
  final int selectedCardIndex;
  final ValueChanged<int> onCardSelected;
  // カード長押し時のコールバック
  final ValueChanged<CategoryTag>? onCardLongPress;
  final VoidCallback onSave;
  final VoidCallback? onUndo;
  final bool showUndo;

  const InputControlPanel({
    super.key,
    required this.isCardPayment,
    required this.onToggleCard,
    required this.cardList,
    required this.selectedCardIndex,
    required this.onCardSelected,
    this.onCardLongPress,
    required this.onSave,
    this.onUndo,
    this.showUndo = false,
  });

  @override
  Widget build(BuildContext context) {
    // Nullチェック用のローカル変数
    final callback = onCardLongPress;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
        border: Border.all(color: Colors.grey.shade200),
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        children: [
          // カード切り替えと選択部分
          Row(
            children: [
              Text(
                "カード",
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: isCardPayment ? Colors.blue : Colors.grey,
                ),
              ),
              const SizedBox(width: 5),
              Transform.scale(
                scale: 0.8,
                child: Switch(
                  value: isCardPayment,
                  activeColor: Colors.blue,
                  onChanged: onToggleCard,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: isCardPayment && cardList.isNotEmpty
                    ? SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: cardList.asMap().entries.map((entry) {
                            final index = entry.key;
                            final tag = entry.value;
                            final isSelected = selectedCardIndex == index;

                            return Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: GestureDetector(
                                // 【解決策】RawChipの外側をGestureDetectorで囲む
                                onLongPress: callback != null
                                    ? () => callback(tag)
                                    : null,
                                child: RawChip(
                                  label: Text(tag.label),
                                  labelStyle: TextStyle(
                                    fontSize: 11,
                                    color: isSelected
                                        ? Colors.white
                                        : Colors.black87,
                                    fontWeight: isSelected
                                        ? FontWeight.bold
                                        : FontWeight.normal,
                                  ),
                                  selected: isSelected,
                                  showCheckmark: false,
                                  selectedColor: tag.color,
                                  backgroundColor: Colors.grey.shade100,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    side: const BorderSide(
                                      color: Colors.transparent,
                                      width: 0,
                                    ),
                                  ),
                                  onSelected: (_) => onCardSelected(index),
                                  // ここにあった onLongPress は削除（存在しない引数のため）
                                  visualDensity: VisualDensity.compact,
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      )
                    : const SizedBox.shrink(),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // 保存ボタン
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: onSave,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              child: const Text(
                '保存',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ),

          // 直前の入力を取り消すボタン
          if (showUndo && onUndo != null)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: SizedBox(
                height: 30,
                child: TextButton.icon(
                  onPressed: onUndo,
                  icon: const Icon(Icons.undo, size: 14, color: Colors.grey),
                  label: const Text(
                    '前回の入力を取り消す',
                    style: TextStyle(color: Colors.grey, fontSize: 12),
                  ),
                  style: TextButton.styleFrom(
                    padding: EdgeInsets.zero,
                    visualDensity: VisualDensity.compact,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
