import 'package:flutter/material.dart';
import '../models/category_tag.dart';

class CategorySelector extends StatelessWidget {
  final List<CategoryTag> tags;
  final int? selectedIndex;
  final Function(int) onSelected;
  final Function(int)? onLongPress;
  final VoidCallback? onAddPressed;

  const CategorySelector({
    super.key,
    required this.tags,
    required this.selectedIndex,
    required this.onSelected,
    this.onLongPress,
    this.onAddPressed,
  });

  @override
  Widget build(BuildContext context) {
    final int itemCount = onAddPressed != null ? tags.length + 1 : tags.length;

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 2),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        mainAxisSpacing: 8,
        crossAxisSpacing: 8,
        childAspectRatio: 2.0,
      ),
      itemCount: itemCount,
      itemBuilder: (context, index) {
        if (onAddPressed != null && index == tags.length) {
          return _buildAddButton();
        }

        final tag = tags[index];
        final isSelected = selectedIndex == index;
        return _buildCategoryChip(
          tag,
          isSelected,
          () => onSelected(index),
          onLongPress != null ? () => onLongPress!(index) : null,
        );
      },
    );
  }

  Widget _buildAddButton() {
    return Material(
      color: Colors.grey.shade100,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(color: Colors.grey.shade300, width: 1.5),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onAddPressed,
        child: Padding(
          padding: const EdgeInsets.all(4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: const [
              Icon(Icons.settings, color: Colors.grey, size: 18),
              SizedBox(width: 4),
              Text(
                "編集",
                style: TextStyle(
                  color: Colors.grey,
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryChip(
    CategoryTag tag,
    bool isSelected,
    VoidCallback onTap,
    VoidCallback? onLongPress,
  ) {
    // ▼▼ 変更: プレビュー風のスタイル（背景薄め・文字濃いめ） ▼▼

    // 背景: 選択時は少し濃く、非選択時は薄く
    final backgroundColor = tag.color.withOpacity(isSelected ? 0.25 : 0.1);

    // 文字・アイコン: タグの色そのものを使用（白文字にしない）
    final foregroundColor = tag.color;

    // 枠線: 選択時は太くハッキリ、非選択時は薄く
    final borderSide = BorderSide(
      color: isSelected ? tag.color : tag.color.withOpacity(0.3),
      width: isSelected ? 2.5 : 1.0,
    );

    return Material(
      color: backgroundColor,
      // 選択時のみ少し浮かせる
      elevation: isSelected ? 2 : 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: borderSide,
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        onLongPress: onLongPress,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(tag.displayIcon, color: foregroundColor, size: 20),
              const SizedBox(width: 6),
              Flexible(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    tag.label,
                    style: TextStyle(
                      color: foregroundColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
