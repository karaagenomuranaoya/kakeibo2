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
    // --- 指示に基づいたUI仕様 ---
    // 非選択時: 背景は白, 文字は黒, アイコンは固有の色, 枠線は薄い固有の色で細い
    // 選択時: 枠線なし, 背景は固有の色, 文字色は白 (アイコンも白)

    final backgroundColor = isSelected ? tag.color : Colors.white;
    final iconColor = isSelected ? Colors.white : tag.color;
    final textColor = isSelected ? Colors.white : Colors.black;

    final borderSide = isSelected
        ? BorderSide.none
        : BorderSide(color: tag.color.withOpacity(0.5), width: 1.0);

    return Material(
      color: backgroundColor,
      elevation: 0,
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
              Icon(tag.displayIcon, color: iconColor, size: 20),
              const SizedBox(width: 6),
              Flexible(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    tag.label,
                    style: TextStyle(
                      color: textColor,
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
