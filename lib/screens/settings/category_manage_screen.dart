import 'package:flutter/material.dart';
import '../../models/category_tag.dart';
import '../../models/gacha_item.dart';
import '../../repositories/settings_repository.dart';
import '../../repositories/gacha_repository.dart';
import '../../repositories/transaction_repository.dart';
import '../../models/bonus_item.dart';
import '../../data/bonus_data.dart';

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
  final TransactionRepository _transactionRepository = TransactionRepository();

  List<CategoryTag> _expenseList = [];
  List<CategoryTag> _cardList = [];

  // ガチャ・ボーナスデータ用
  List<GachaItem> _gachaItems = [];
  Map<String, int> _gachaCounts = {};
  int _totalDays = 0;

  bool _isLoading = true;

  // 標準アイコンリスト
  final List<IconData> _standardIcons = [
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

    // 取引データからユニークな入力日数を取得
    await _transactionRepository.getAllTransactions();
    final days = _transactionRepository.getUniqueInputDaysCount();

    if (mounted) {
      setState(() {
        _expenseList = expenses;
        _cardList = cards;
        _gachaItems = gachaItems;
        _gachaCounts = gachaCounts;
        _totalDays = days;
        _isLoading = false;
      });
    }
  }

  Future<void> _saveCurrentList() async {
    await _settingsRepository.saveExpenseTags(_expenseList);
    await _settingsRepository.saveCardTags(_cardList);
  }

  // ガチャアイテム用のスタイル選択ダイアログ（これは残す）
  Future<void> _showStyleSelectionDialog({
    required BuildContext context,
    required GachaItem item,
    required int currentCount,
    required Function(Color) onColorSelected,
  }) async {
    final int maxStage = item.getStage(currentCount);

    await showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: Text('${item.baseName}のスタイル選択'),
          content: SingleChildScrollView(
            child: Wrap(
              spacing: 12,
              runSpacing: 12,
              alignment: WrapAlignment.center,
              children: List.generate(maxStage, (index) {
                final level = index + 1;
                final color = item.getColor(level);

                return GestureDetector(
                  onTap: () {
                    onColorSelected(color);
                    Navigator.pop(ctx);
                  },
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 50,
                        height: 50,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          border: Border.all(color: color, width: 2),
                        ),
                        child: Icon(item.iconData, color: color, size: 28),
                      ),
                      const SizedBox(height: 4),
                      Text("Lv.$level", style: const TextStyle(fontSize: 10)),
                    ],
                  ),
                );
              }),
            ),
          ),
        );
      },
    );
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
    IconData selectedIcon =
        item?.displayIcon ?? (isExpense ? Icons.category : Icons.credit_card);

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
                      TextField(
                        controller: nameController,
                        decoration: const InputDecoration(labelText: '名称'),
                        onChanged: (_) => setStateDialog(() {}),
                      ),
                      const SizedBox(height: 20),
                      // プレビュー
                      Row(
                        children: [
                          const Text("プレビュー: "),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 10,
                            ),
                            decoration: BoxDecoration(
                              color: selectedColor,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  selectedIcon,
                                  color: Colors.white,
                                  size: 18,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  nameController.text.isEmpty
                                      ? "名称"
                                      : nameController.text,
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
                      // 標準アイコン
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
                            onTap: () =>
                                setStateDialog(() => selectedIcon = icon),
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
                      // 色調整
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
                      // ガチャキャラセクション
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
                      if (_gachaCounts.values.every((c) => c == 0))
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
                            final isSelected = selectedIcon == item.iconData;
                            return InkWell(
                              onTap: () async {
                                await _showStyleSelectionDialog(
                                  context: context,
                                  item: item,
                                  currentCount: count,
                                  onColorSelected: (color) =>
                                      setStateDialog(() {
                                        selectedIcon = item.iconData;
                                        selectedColor = color;
                                      }),
                                );
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
                                child: Icon(
                                  item.iconData,
                                  color: item.getColor(count),
                                ),
                              ),
                            );
                          },
                        ),
                      const SizedBox(height: 30),
                      // 継続ボーナスセクション
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        decoration: BoxDecoration(color: Colors.blue.shade50),
                        child: const Center(
                          child: Text(
                            "継続ボーナス特典",
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.blue,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      if (BonusData.list.every(
                        (item) => _totalDays < item.targetDays,
                      ))
                        const Center(
                          child: Text(
                            "継続日数に応じて解放されます！",
                            style: TextStyle(color: Colors.grey, fontSize: 12),
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
                          itemCount: BonusData.list
                              .where((i) => _totalDays >= i.targetDays)
                              .length,
                          itemBuilder: (context, idx) {
                            final unlockedBonuses = BonusData.list
                                .where((i) => _totalDays >= i.targetDays)
                                .toList();
                            final item = unlockedBonuses[idx];
                            final isSelected = selectedIcon == item.icon;
                            return InkWell(
                              onTap: () {
                                // ★ここを修正：ダイアログなしで即座に反映
                                setStateDialog(() {
                                  selectedIcon = item.icon;
                                  selectedColor = item.color;
                                });
                              },
                              child: Container(
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: isSelected
                                        ? Colors.blueAccent
                                        : Colors.grey.shade300,
                                    width: isSelected ? 3 : 1,
                                  ),
                                ),
                                child: Icon(item.icon, color: item.color),
                              ),
                            );
                          },
                        ),
                      // カード設定
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
                              onChanged: (val) =>
                                  setStateDialog(() => isClosingMode = val),
                            ),
                          ],
                        ),
                        if (isClosingMode) ...[
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
                      iconCodePoint: selectedIcon.codePoint,
                      iconFontFamily: selectedIcon.fontFamily,
                      iconFontPackage: selectedIcon.fontPackage,
                      closingDay: (!isExpense && isClosingMode)
                          ? closingDay
                          : null,
                      paymentDay: (!isExpense && isClosingMode)
                          ? paymentDay
                          : null,
                      paymentMonthOffset: paymentOffset,
                    );
                    setState(() {
                      final list = isExpense ? _expenseList : _cardList;
                      if (item == null) {
                        list.add(newTag);
                      } else {
                        list[index] = newTag;
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
    if (_isLoading)
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
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
        onPressed: () =>
            _showEditDialog(isExpense: _tabController.index == 0, index: -1),
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
          if (oldIndex < newIndex) newIndex -= 1;
          final item = list.removeAt(oldIndex);
          list.insert(newIndex, item);
        });
        await _saveCurrentList();
      },
      itemBuilder: (context, index) {
        final item = list[index];
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
            child: Icon(item.displayIcon, color: item.color, size: 20),
          ),
          title: Text(item.label, overflow: TextOverflow.ellipsis),
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
