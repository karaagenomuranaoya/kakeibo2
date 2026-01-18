import 'package:flutter/material.dart';
import '../../../models/category_tag.dart';
import '../../../models/gacha_item.dart';
import 'gacha_style_dialog.dart';

class CategoryEditDialog extends StatefulWidget {
  final bool isExpense;
  final CategoryTag? existingItem; // 編集時はこれが入る
  final List<GachaItem> gachaItems;
  final Map<String, int> gachaCounts;

  const CategoryEditDialog({
    super.key,
    required this.isExpense,
    this.existingItem,
    required this.gachaItems,
    required this.gachaCounts,
  });

  @override
  State<CategoryEditDialog> createState() => _CategoryEditDialogState();
}

class _CategoryEditDialogState extends State<CategoryEditDialog> {
  late TextEditingController _nameController;
  late Color _selectedColor;
  late IconData _selectedIcon;
  late bool _isClosingMode;
  late int _closingDay;
  late int _paymentDay;
  late int _paymentOffset;

  // 標準アイコンリスト
  static const List<IconData> _standardIcons = [
    Icons.restaurant,
    Icons.shopping_bag,
    Icons.train,
    Icons.wine_bar,
    Icons.sports_esports,
    Icons.checkroom,
    Icons.medical_services,
    Icons.menu_book,
    Icons.home,
    Icons.wifi,
    Icons.directions_car,
    Icons.movie,
    Icons.attach_money,
    Icons.credit_card,
    Icons.payment,
    Icons.shopping_cart,
    Icons.school,
    Icons.phone_iphone,
    Icons.sports_soccer,
    Icons.savings,
    Icons.card_giftcard,
    Icons.pets,
    Icons.flight,
    Icons.local_cafe,
    Icons.local_bar,
    Icons.work,
    Icons.category,
    Icons.star,
    Icons.favorite,
    Icons.account_balance_wallet,
    Icons.coffee,
    Icons.fastfood,
    Icons.receipt_long,
    Icons.local_grocery_store,
    Icons.fitness_center,
    Icons.music_note,
    Icons.child_care,
  ];

  static const List<Color> _colors = [
    Colors.red,
    Colors.pink,
    Colors.purple,
    Colors.deepPurple,
    Colors.indigo,
    Colors.blue,
    Colors.lightBlue,
    Colors.cyan,
    Colors.teal,
    Colors.green,
    Colors.lightGreen,
    Colors.lime,
    Colors.yellow,
    Colors.amber,
    Colors.orange,
    Colors.deepOrange,
    Colors.brown,
    Colors.grey,
    Colors.blueGrey,
    Colors.black,
  ];

  // ▼▼▼ 追加: ガチャモードかどうかのフラグ ▼▼▼
  bool _isGachaMode = false;

  @override
  void initState() {
    super.initState();
    final item = widget.existingItem;
    _nameController = TextEditingController(text: item?.label ?? '');

    // 初期値の設定
    _selectedColor =
        item?.color ?? (widget.isExpense ? Colors.orange : Colors.blue);
    _selectedIcon =
        item?.displayIcon ??
        (widget.isExpense ? Icons.category : Icons.credit_card);
    _isClosingMode = (item?.closingDay != null);
    _closingDay = item?.closingDay ?? 99;
    _paymentDay = item?.paymentDay ?? 27;
    _paymentOffset = item?.paymentMonthOffset ?? 1;

    // ▼▼▼ 追加: 初期アイコンがガチャキャラのものか判定 ▼▼▼
    if (item != null) {
      // 既存のアイコンがガチャリストに含まれているかチェック
      _isGachaMode = widget.gachaItems.any(
        (g) => g.iconData == item.displayIcon,
      );
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  List<DropdownMenuItem<int>> _getDayItems() {
    final items = List.generate(
      28,
      (i) => i + 1,
    ).map((i) => DropdownMenuItem(value: i, child: Text('$i日'))).toList();
    items.add(const DropdownMenuItem(value: 99, child: Text('末日')));
    return items;
  }

  Future<void> _pickGachaStyle(GachaItem item, int count) async {
    final Color? pickedColor = await showDialog<Color>(
      context: context,
      builder: (context) => GachaStyleDialog(item: item, currentCount: count),
    );

    if (pickedColor != null && mounted) {
      setState(() {
        _selectedIcon = item.iconData;
        _selectedColor = pickedColor;
        _isGachaMode = true; // ▼ ガチャキャラ選択時はロック有効
      });
    }
  }

  void _onSave() {
    if (_nameController.text.isEmpty) return;

    final newTag = CategoryTag(
      id: widget.existingItem?.id, // IDを引き継ぐ（新規ならnullで内部生成）
      label: _nameController.text,
      color: _selectedColor,
      isCircle: widget.isExpense,
      iconCodePoint: _selectedIcon.codePoint,
      iconFontFamily: _selectedIcon.fontFamily,
      iconFontPackage: _selectedIcon.fontPackage,
      closingDay: (!widget.isExpense && _isClosingMode) ? _closingDay : null,
      paymentDay: (!widget.isExpense && _isClosingMode) ? _paymentDay : null,
      paymentMonthOffset: _paymentOffset,
    );

    Navigator.pop(context, newTag);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.existingItem == null ? '新規追加' : '編集'),
      content: SizedBox(
        width: double.maxFinite,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // --- 名前入力 ---
              TextField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: '名称'),
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: 20),

              // --- プレビュー ---
              Row(
                children: [
                  const Text("プレビュー: "),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: _selectedColor,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(_selectedIcon, color: Colors.white, size: 18),
                        const SizedBox(width: 6),
                        Text(
                          _nameController.text.isEmpty
                              ? "名称"
                              : _nameController.text,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // --- 標準アイコン ---
              const Text(
                'アイコンを選択',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 6,
                  crossAxisSpacing: 8,
                  mainAxisSpacing: 8,
                ),
                itemCount: _standardIcons.length,
                itemBuilder: (context, idx) {
                  final icon = _standardIcons[idx];
                  final isSelected = _selectedIcon == icon;
                  return InkWell(
                    onTap: () => setState(() {
                      _selectedIcon = icon;
                      _isGachaMode = false; // ▼ 標準アイコン選択時はロック解除
                    }),
                    child: Container(
                      decoration: BoxDecoration(
                        color: isSelected
                            ? Colors.grey.shade300
                            : Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(8),
                        border: isSelected
                            ? Border.all(color: Colors.blue, width: 2)
                            : null,
                      ),
                      child: Icon(icon, color: Colors.black54, size: 20),
                    ),
                  );
                },
              ),
              const SizedBox(height: 20),

              // --- 色調整 ---
              Row(
                children: [
                  const Text(
                    '色を調整',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  // ガチャモードのときだけ注意書きを表示
                  if (_isGachaMode) ...[
                    const SizedBox(width: 10),
                    Text(
                      'レベルを上げて色を増やそう。',
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 10),

              // ガチャモードなら操作無効(IgnorePointer)かつ半透明(Opacity)にする
              IgnorePointer(
                ignoring: _isGachaMode, // trueならタッチ反応なし
                child: Opacity(
                  opacity: _isGachaMode ? 0.3 : 1.0, // trueなら薄く表示
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _colors.map((c) {
                      return GestureDetector(
                        onTap: () => setState(() => _selectedColor = c),
                        child: Container(
                          width: 30,
                          height: 30,
                          decoration: BoxDecoration(
                            color: c,
                            shape: BoxShape.circle,
                            border: _selectedColor == c
                                ? Border.all(color: Colors.black, width: 2)
                                : null,
                          ),
                          child: _selectedColor == c
                              ? const Icon(
                                  Icons.check,
                                  color: Colors.white,
                                  size: 16,
                                )
                              : null,
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),
              const SizedBox(height: 30),

              // --- ガチャキャラセクション ---
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(color: Colors.orange.shade50),
                child: const Center(
                  child: Text(
                    "獲得済みキャラを使用",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.deepOrange,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 15),
              if (widget.gachaCounts.values.every((c) => c == 0))
                const Center(
                  child: Text(
                    "ガチャを回してゲットしよう！",
                    style: TextStyle(color: Colors.grey),
                  ),
                )
              else
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 5,
                    crossAxisSpacing: 8,
                    mainAxisSpacing: 8,
                  ),
                  itemCount: widget.gachaItems
                      .where((i) => (widget.gachaCounts[i.id] ?? 0) > 0)
                      .length,
                  itemBuilder: (context, idx) {
                    final unlockedItems = widget.gachaItems
                        .where((i) => (widget.gachaCounts[i.id] ?? 0) > 0)
                        .toList();
                    final item = unlockedItems[idx];
                    final count = widget.gachaCounts[item.id] ?? 0;
                    final isSelected = _selectedIcon == item.iconData;
                    final previewColor = item.getColor(count);

                    return InkWell(
                      onTap: () => _pickGachaStyle(item, count),
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: isSelected
                                ? Colors.redAccent
                                : Colors.grey.shade300,
                            width: isSelected ? 3 : 1,
                          ),
                        ),
                        child: Icon(item.iconData, color: previewColor),
                      ),
                    );
                  },
                ),
              const SizedBox(height: 30),

              // --- カード設定（費目でない場合のみ） ---
              if (!widget.isExpense) ...[
                const Divider(height: 30),
                Row(
                  children: [
                    const Text(
                      '締め日・支払日設定',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const Spacer(),
                    Switch(
                      value: _isClosingMode,
                      onChanged: (val) => setState(() => _isClosingMode = val),
                    ),
                  ],
                ),
                if (_isClosingMode) ...[
                  Row(
                    children: [
                      const Text('締め: '),
                      DropdownButton<int>(
                        value: _closingDay,
                        items: _getDayItems(),
                        onChanged: (val) => setState(() => _closingDay = val!),
                      ),
                      const SizedBox(width: 15),
                      const Text('払い: '),
                      DropdownButton<int>(
                        value: _paymentDay,
                        items: _getDayItems(),
                        onChanged: (val) => setState(() => _paymentDay = val!),
                      ),
                    ],
                  ),
                ],
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('キャンセル'),
        ),
        ElevatedButton(onPressed: _onSave, child: const Text('保存')),
      ],
    );
  }
}
