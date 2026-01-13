import 'package:flutter/material.dart';
import '../models/category_tag.dart';

class CategorySelector extends StatelessWidget {
  final List<CategoryTag> tags;
  final int? selectedIndex;
  final Function(int) onSelected;

  const CategorySelector({
    super.key,
    required this.tags,
    required this.selectedIndex,
    required this.onSelected,
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
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      // 余白を少し詰める
      padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 0),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        mainAxisSpacing: 8, // 間隔を少し詰める
        crossAxisSpacing: 8,
        // ▼▼ 変更点: 横長比率を上げて、ボタンの高さを低くする (1.5 -> 2.0) ▼▼
        // これにより、同じ画面スペースにより多くの行（ボタン）が表示されます。
        childAspectRatio: 2.0,
      ),
      itemCount: tags.length,
      itemBuilder: (context, index) {
        final tag = tags[index];
        final isSelected = selectedIndex == index;
        final icon = _getIconForLabel(tag.label);

        return Material(
          color: isSelected ? tag.color : Colors.white,
          elevation: isSelected ? 2 : 1, // 影を少し控えめに
          // MaterialのborderRadius指定は削除し、shapeのみで管理
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10), // 角丸も少し控えめに
            side: BorderSide(
              color:
                  isSelected ? Colors.transparent : tag.color.withOpacity(0.3),
              width: 1.5,
            ),
          ),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: () => onSelected(index),
            child: Padding(
              // 内部の余白も詰める
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
              child: Row(
                // ColumnではなくRow（横並び）または、コンパクトなColumnにする手もあるが、
                // 今回は「アイコン＋文字」が見やすいコンパクトなColumnを維持しつつ調整
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    icon,
                    color: isSelected ? Colors.white : tag.color,
                    size: 20, // アイコンを少し小さく
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
      },
    );
  }
}
