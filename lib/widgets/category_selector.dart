import 'package:flutter/material.dart';
import '../models/category_tag.dart';

class CategorySelector extends StatelessWidget {
  final List<CategoryTag> tags;
  final int? selectedIndex;
  final Function(int) onSelected;
  // ▼▼ 追加: 長押しコールバック ▼▼
  final Function(int)? onLongPress;
  final VoidCallback? onAddPressed;

  const CategorySelector({
    super.key,
    required this.tags,
    required this.selectedIndex,
    required this.onSelected,
    this.onLongPress, // 追加
    this.onAddPressed,
  });

  IconData _getIconForLabel(String label) {
    if (label.contains('食')) return Icons.restaurant;
    if (label.contains('日用')) return Icons.shopping_bag;
    if (label.contains('交際')) return Icons.wine_bar;
    if (label.contains('交通') || label.contains('電')) return Icons.train;
    if (label.contains('趣味') || label.contains('推'))
      return Icons.sports_esports;
    if (label.contains('美容') || label.contains('服')) return Icons.checkroom;
    if (label.contains('医療') || label.contains('薬'))
      return Icons.medical_services;
    if (label.contains('教育') || label.contains('本')) return Icons.menu_book;
    if (label.contains('光熱') || label.contains('家賃') || label.contains('住'))
      return Icons.home;
    if (label.contains('通信') || label.contains('スマホ')) return Icons.wifi;
    if (label.contains('車') || label.contains('ガソリン'))
      return Icons.directions_car;
    if (label.contains('給料')) return Icons.attach_money;
    return Icons.category;
  }

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
          // ▼▼ 長押し処理を渡す ▼▼
          onLongPress != null ? () => onLongPress!(index) : null,
        );
      },
    );
  }

  Widget _buildAddButton() {
    return Material(
      color: Colors.grey.shade200,
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
    VoidCallback? onLongPress, // 追加
  ) {
    return Material(
      color: isSelected ? tag.color : Colors.white,
      elevation: isSelected ? 2 : 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(
          color: isSelected ? Colors.transparent : tag.color.withOpacity(0.3),
          width: 1.5,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        onLongPress: onLongPress, // 追加
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                _getIconForLabel(tag.label),
                color: isSelected ? Colors.white : tag.color,
                size: 20,
              ),
              const SizedBox(width: 6),
              Flexible(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    tag.label,
                    style: TextStyle(
                      color: isSelected ? Colors.white : Colors.black87,
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
