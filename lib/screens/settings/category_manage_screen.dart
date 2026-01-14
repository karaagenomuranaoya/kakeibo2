import 'package:flutter/material.dart';
import '../../models/category_tag.dart';
import '../../repositories/settings_repository.dart';

class CategoryManageScreen extends StatefulWidget {
  const CategoryManageScreen({super.key});

  @override
  State<CategoryManageScreen> createState() => _CategoryManageScreenState();
}

class _CategoryManageScreenState extends State<CategoryManageScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final SettingsRepository _repository = SettingsRepository();

  List<CategoryTag> _expenseList = [];
  List<CategoryTag> _cardList = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadData();
  }

  Future<void> _loadData() async {
    final expenses = await _repository.loadExpenseTags();
    final cards = await _repository.loadCardTags();
    setState(() {
      _expenseList = expenses;
      _cardList = cards;
      _isLoading = false;
    });
  }

  Future<void> _saveCurrentList() async {
    await _repository.saveExpenseTags(_expenseList);
    await _repository.saveCardTags(_cardList);
  }

  void _showEditDialog({
    required bool isExpense,
    CategoryTag? item,
    required int index,
  }) {
    final TextEditingController nameController =
        TextEditingController(text: item?.label ?? '');
    Color selectedColor =
        item?.color ?? (isExpense ? Colors.orange : Colors.blue);

    // --- カード設定用の変数 ---
    bool isClosingMode = (item?.closingDay != null); // 締め日設定があるか
    int closingDay = item?.closingDay ?? 99; // デフォルト末日
    int paymentDay = item?.paymentDay ?? 27; // デフォルト27日
    int paymentOffset = item?.paymentMonthOffset ?? 1; // デフォルト翌月

    // 簡易カラーパレット
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

    // 日付選択用のドロップダウンアイテム生成
    List<DropdownMenuItem<int>> getDayItems() {
      final items = List.generate(28, (i) => i + 1)
          .map((i) => DropdownMenuItem(value: i, child: Text('$i日')))
          .toList();
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
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextField(
                      controller: nameController,
                      decoration: const InputDecoration(labelText: '名称'),
                      autofocus: true,
                    ),
                    const SizedBox(height: 20),
                    const Text('色を選択'),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: colors.map((c) {
                        return GestureDetector(
                          onTap: () => setStateDialog(() => selectedColor = c),
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
                          ),
                        );
                      }).toList(),
                    ),

                    // --- カードの場合のみ、締め日設定を表示 ---
                    if (!isExpense) ...[
                      const Divider(height: 30),
                      Row(
                        children: [
                          const Text('締め日・支払日設定',
                              style: TextStyle(fontWeight: FontWeight.bold)),
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
                                DropdownMenuItem(value: 2, child: Text('翌々月')),
                              ],
                              onChanged: (val) =>
                                  setStateDialog(() => paymentOffset = val!),
                            ),
                          ],
                        ),
                        const Text(
                          '※設定すると入力時に支払日が自動計算されます',
                          style: TextStyle(fontSize: 11, color: Colors.grey),
                        ),
                      ],
                    ],
                  ],
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
                      // 締め日モードOFFならnullを保存
                      closingDay:
                          (!isExpense && isClosingMode) ? closingDay : null,
                      paymentDay:
                          (!isExpense && isClosingMode) ? paymentDay : null,
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
        children: [
          _buildList(isExpense: true),
          _buildList(isExpense: false),
        ],
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
        // 設定情報の要約を表示
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
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: item.color,
              shape: item.isCircle ? BoxShape.circle : BoxShape.rectangle,
              borderRadius: item.isCircle ? null : BorderRadius.circular(4),
            ),
          ),
          title: Text(item.label),
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
