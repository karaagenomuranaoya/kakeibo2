import 'package:flutter/material.dart';
import '../../../../../models/gacha_item.dart';

class GachaItemTile extends StatelessWidget {
  final GachaItem item;
  final int count;
  final int maxLevel;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;

  const GachaItemTile({
    super.key,
    required this.item,
    required this.count,
    this.maxLevel = 10,
    this.onTap,
    this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    final int level = item.getStage(count);
    final bool isUnlocked = count > 0;
    final Color itemColor = item.getColor(count);
    final bool isOverLimit = count > maxLevel;

    return GestureDetector(
      onTap: isUnlocked ? onTap : null,
      onLongPress: onLongPress,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isUnlocked
                ? itemColor.withOpacity(0.3)
                : Colors.grey.shade200,
            width: isUnlocked ? 2 : 1,
          ),
          boxShadow: [
            if (isUnlocked)
              BoxShadow(
                color: itemColor.withOpacity(0.1),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
          ],
        ),
        child: Stack(
          children: [
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Expanded(
                  child: Center(
                    child: isUnlocked
                        ? Icon(item.iconData, size: 42, color: itemColor)
                        : Icon(
                            Icons.lock_outline,
                            size: 32,
                            color: Colors.grey.shade300,
                          ),
                  ),
                ),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  decoration: BoxDecoration(
                    color: isUnlocked
                        ? itemColor.withOpacity(0.1)
                        : Colors.grey.shade50,
                    borderRadius: const BorderRadius.vertical(
                      bottom: Radius.circular(14),
                    ),
                  ),
                  child: Column(
                    children: [
                      Text(
                        isUnlocked
                            ? (isOverLimit ? "Lv.$count" : "Lv.$level")
                            : "???",
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: isUnlocked ? itemColor : Colors.grey,
                        ),
                      ),
                      if (isUnlocked && !isOverLimit)
                        Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 2,
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(2),
                            child: LinearProgressIndicator(
                              value: level / maxLevel,
                              minHeight: 3,
                              backgroundColor: Colors.white,
                              color: itemColor,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
            if (isOverLimit)
              Positioned(
                top: 8,
                right: 8,
                child: Icon(
                  Icons.auto_awesome,
                  size: 16,
                  color: itemColor.withOpacity(0.8),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
