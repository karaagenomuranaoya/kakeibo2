import 'package:flutter/material.dart';
import '../../models/category_tag.dart';
import '../../models/gacha_item.dart';
import '../../repositories/settings_repository.dart';
import '../../repositories/gacha_repository.dart';

class CategoryManageScreen extends StatefulWidget {
  const CategoryManageScreen({super.key});

  @override
  State<CategoryManageScreen> createState() => _CategoryManageScreenState();
}

class _CategoryManageScreenState extends State<CategoryManageScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final SettingsRepository _settingsRepository = SettingsRepository();
  final GachaRepository _gachaRepository = GachaRepository();

  List<CategoryTag> _expenseList = [];
  List<CategoryTag> _cardList = [];

  // ガチャデータ用
  List<GachaItem> _gachaItems = [];
  Map<String, int> _gachaCounts = {};

  bool _isLoading = true;

  // 標準アイコンリスト
  final List<IconData> _standardIcons = [
    Icons.restaurant,
    Icons.shopping_cart,
    Icons.train,
    Icons.movie,
    Icons.medical_services,
    Icons.school,
    Icons.phone_iphone,
    Icons.home,
    Icons.checkroom,
    Icons.sports_soccer,
    Icons.savings,
    Icons.card_giftcard,
    Icons.pets,
    Icons.flight,
    Icons.local_cafe,
    Icons.local_bar,
    Icons.directions_car,
    Icons.work,
    Icons.category,
    Icons.star,
    Icons.favorite,
    Icons.account_balance_wallet,
    Icons.coffee,
    Icons.fastfood,
    Icons.shopping_bag,
    Icons.receipt_long,
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadData();
  }

  Future<void> _loadData() async {
    final expenses = await _settingsRepository.loadExpenseTags();
    final cards = await _settingsRepository.loadCardTags();

    final gachaItems = await _gachaRepository.getItems();
    final gachaCounts = await _gachaRepository.getItemCounts();

    if (mounted) {
      setState(() {
        _expenseList = expenses;
        _cardList = cards;
        _gachaItems = gachaItems;
        _gachaCounts = gachaCounts;
        _isLoading = false;
      });
    }
  }

  Future<void> _saveCurrentList() async {
    await _settingsRepository.saveExpenseTags(_expenseList);
    await _settingsRepository.saveCardTags(_cardList);
  }

  void _showEditDialog({
    required bool isExpense,
    CategoryTag? item,
    required int index,
  }) {
    final TextEditingController nameController = TextEditingController(
      text: item?.label ?? '',
    );

    Color selectedColor =
        item?.color ?? (isExpense ? Colors.orange : Colors.blue);
    IconData? selectedIcon = item?.icon;

    // --- カード設定用の変数 ---
    bool isClosingMode = (item?.closingDay != null);
    int closingDay = item?.closingDay ?? 99;
    int paymentDay = item?.paymentDay ?? 27;
    int paymentOffset = item?.paymentMonthOffset ?? 1;

    final List<Color> colors = [
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

    List<DropdownMenuItem<int>> getDayItems() {
      final items = List.generate(
        28,
        (i) => i + 1,
      ).map((i) => DropdownMenuItem(value: i, child: Text('$i日'))).toList();
      items.add(const DropdownMenuItem(value: 99, child: Text('末日')));
      return items;
    }

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              title: Text(item == null ? '新規追加' : '編集'),
              content: SizedBox(
                width: double.maxFinite,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // --- 1. 名称入力 ---
                      TextField(
                        controller: nameController,
                        decoration: const InputDecoration(labelText: '名称'),
                        // ▼▼ 修正: 自動でキーボードを出さないように変更 ▼▼
                        autofocus: false,
                        onChanged: (_) => setStateDialog(() {}),
                      ),
                      const SizedBox(height: 20),

                      // --- 2. プレビュー (オーバーフロー対策済み) ---
                      Row(
                        children: [
                          const Text("プレビュー: "),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Align(
                              alignment: Alignment.centerLeft,
                              child: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: selectedColor.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: selectedColor),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      selectedIcon ?? Icons.category,
                                      color: selectedColor,
                                    ),
                                    const SizedBox(width: 8),
                                    Flexible(
                                      child: Text(
                                        nameController.text.isEmpty
                                            ? "名称"
                                            : nameController.text,
                                        style: TextStyle(
                                          color: selectedColor,
                                          fontWeight: FontWeight.bold,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                        maxLines: 1,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),

                      // --- 3. 標準アイコン選択 ---
                      const Text(
                        'アイコンを選択',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 10),
                      GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 6,
                              crossAxisSpacing: 8,
                              mainAxisSpacing: 8,
                            ),
                        itemCount: _standardIcons.length,
                        itemBuilder: (context, idx) {
                          final icon = _standardIcons[idx];
                          final isSelected = selectedIcon == icon;
                          return InkWell(
                            onTap: () {
                              setStateDialog(() => selectedIcon = icon);
                            },
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
                              child: Icon(
                                icon,
                                color: Colors.black54,
                                size: 20,
                              ),
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 20),

                      // --- 4. 色の調整 ---
                      const Text(
                        '色を調整',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: colors.map((c) {
                          return GestureDetector(
                            onTap: () =>
                                setStateDialog(() => selectedColor = c),
                            child: Container(
                              width: 30,
                              height: 30,
                              decoration: BoxDecoration(
                                color: c,
                                shape: BoxShape.circle,
                                border: selectedColor == c
                                    ? Border.all(color: Colors.black, width: 2)
                                    : null,
                              ),
                              child: selectedColor == c
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
                      const SizedBox(height: 30),

                      // --- 5. 大きな仕切り (獲得済みキャラを使用) ---
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        decoration: BoxDecoration(
                          color: Colors.orange.shade50,
                          border: Border.symmetric(
                            horizontal: BorderSide(
                              color: Colors.orange.shade200,
                              width: 2,
                            ),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: const [
                            Icon(Icons.auto_awesome, color: Colors.orange),
                            SizedBox(width: 8),
                            Text(
                              "獲得済みキャラを使用",
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.deepOrange,
                              ),
                            ),
                            SizedBox(width: 8),
                            Icon(Icons.auto_awesome, color: Colors.orange),
                          ],
                        ),
                      ),
                      const SizedBox(height: 10),
                      const Text(
                        "※キャラを選択すると、そのキャラの色が自動で適用されます。",
                        style: TextStyle(fontSize: 11, color: Colors.grey),
                      ),
                      const SizedBox(height: 15),

                      // --- 6. 獲得済みキャラ選択 ---
                      if (_gachaCounts.values.every((c) => c == 0))
                        const Center(
                          child: Padding(
                            padding: EdgeInsets.all(10),
                            child: Text(
                              "まだキャラクターがいません\nガチャを回してゲットしよう！",
                              textAlign: TextAlign.center,
                              style: TextStyle(color: Colors.grey),
                            ),
                          ),
                        )
                      else
                        GridView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 5,
                                crossAxisSpacing: 8,
                                mainAxisSpacing: 8,
                              ),
                          itemCount: _gachaItems
                              .where((i) => (_gachaCounts[i.id] ?? 0) > 0)
                              .length,
                          itemBuilder: (context, idx) {
                            final unlockedItems = _gachaItems
                                .where((i) => (_gachaCounts[i.id] ?? 0) > 0)
                                .toList();
                            final item = unlockedItems[idx];
                            final count = _gachaCounts[item.id] ?? 0;
                            final charColor = item.getColor(count);
                            final isSelected = selectedIcon == item.iconData;

                            return InkWell(
                              onTap: () {
                                setStateDialog(() {
                                  selectedIcon = item.iconData;
                                  selectedColor = charColor; // 色を強制適用
                                });
                              },
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
                                child: Icon(item.iconData, color: charColor),
                              ),
                            );
                          },
                        ),

                      // --- カード設定 ---
                      if (!isExpense) ...[
                        const Divider(height: 30),
                        Row(
                          children: [
                            const Text(
                              '締め日・支払日設定',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            const Spacer(),
                            Switch(
                              value: isClosingMode,
                              onChanged: (val) {
                                setStateDialog(() => isClosingMode = val);
                              },
                            ),
                          ],
                        ),
                        if (isClosingMode) ...[
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              const Text('締め: '),
                              DropdownButton<int>(
                                value: closingDay,
                                items: getDayItems(),
                                onChanged: (val) =>
                                    setStateDialog(() => closingDay = val!),
                              ),
                              const SizedBox(width: 15),
                              const Text('払い: '),
                              DropdownButton<int>(
                                value: paymentDay,
                                items: getDayItems(),
                                onChanged: (val) =>
                                    setStateDialog(() => paymentDay = val!),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              const Text('支払月: '),
                              DropdownButton<int>(
                                value: paymentOffset,
                                items: const [
                                  DropdownMenuItem(value: 1, child: Text('翌月')),
                                  DropdownMenuItem(
                                    value: 2,
                                    child: Text('翌々月'),
                                  ),
                                ],
                                onChanged: (val) =>
                                    setStateDialog(() => paymentOffset = val!),
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
                ElevatedButton(
                  onPressed: () async {
                    if (nameController.text.isEmpty) return;

                    final newTag = CategoryTag(
                      id: item?.id,
                      label: nameController.text,
                      color: selectedColor,
                      isCircle: isExpense,
                      iconCodePoint: selectedIcon?.codePoint,
                      iconFontFamily: selectedIcon?.fontFamily,
                      iconFontPackage: selectedIcon?.fontPackage,
                      closingDay: (!isExpense && isClosingMode)
                          ? closingDay
                          : null,
                      paymentDay: (!isExpense && isClosingMode)
                          ? paymentDay
                          : null,
                      paymentMonthOffset: paymentOffset,
                    );

                    setState(() {
                      if (isExpense) {
                        if (item == null) {
                          _expenseList.add(newTag);
                        } else {
                          _expenseList[index] = newTag;
                        }
                      } else {
                        if (item == null) {
                          _cardList.add(newTag);
                        } else {
                          _cardList[index] = newTag;
                        }
                      }
                    });
                    await _saveCurrentList();
                    if (context.mounted) Navigator.pop(context);
                  },
                  child: const Text('保存'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _deleteItem(bool isExpense, int index) async {
    setState(() {
      if (isExpense) {
        _expenseList.removeAt(index);
      } else {
        _cardList.removeAt(index);
      }
    });
    await _saveCurrentList();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('カテゴリ・カード管理'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: '費目 (カテゴリ)'),
            Tab(text: 'カード・決済'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [_buildList(isExpense: true), _buildList(isExpense: false)],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          final isExpense = _tabController.index == 0;
          _showEditDialog(isExpense: isExpense, index: -1);
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildList({required bool isExpense}) {
    final list = isExpense ? _expenseList : _cardList;

    return ReorderableListView.builder(
      itemCount: list.length,
      padding: const EdgeInsets.only(bottom: 80),
      onReorder: (oldIndex, newIndex) async {
        setState(() {
          if (oldIndex < newIndex) {
            newIndex -= 1;
          }
          final item = list.removeAt(oldIndex);
          list.insert(newIndex, item);
        });
        await _saveCurrentList();
      },
      itemBuilder: (context, index) {
        final item = list[index];
        String subtitle = "";
        if (!isExpense && item.closingDay != null) {
          final closeStr = item.closingDay == 99 ? "末" : "${item.closingDay}日";
          final payStr = item.paymentDay == 99 ? "末" : "${item.paymentDay}日";
          final offsetStr = item.paymentMonthOffset == 1 ? "翌月" : "翌々月";
          subtitle = "締め: $closeStr / 払い: $offsetStr$payStr";
        }

        return ListTile(
          key: ValueKey(item.id),
          leading: Container(
            width: 40,
            height: 40,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: item.color.withOpacity(0.1),
              shape: item.isCircle ? BoxShape.circle : BoxShape.rectangle,
              borderRadius: item.isCircle ? null : BorderRadius.circular(8),
              border: Border.all(color: item.color, width: 1.5),
            ),
            child: Icon(
              item.icon ?? (isExpense ? Icons.category : Icons.credit_card),
              color: item.color,
              size: 20,
            ),
          ),
          title: Text(item.label, overflow: TextOverflow.ellipsis, maxLines: 1),
          subtitle: subtitle.isNotEmpty
              ? Text(subtitle, style: const TextStyle(fontSize: 11))
              : null,
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: const Icon(Icons.edit, color: Colors.grey),
                onPressed: () => _showEditDialog(
                  isExpense: isExpense,
                  item: item,
                  index: index,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.delete, color: Colors.redAccent),
                onPressed: () => _deleteItem(isExpense, index),
              ),
              const Icon(Icons.drag_handle, color: Colors.grey),
            ],
          ),
        );
      },
    );
  }
}
