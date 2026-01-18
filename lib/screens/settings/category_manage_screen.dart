import 'package:flutter/material.dart';
import '../../models/category_tag.dart';
import '../../models/gacha_item.dart';
import '../../repositories/settings_repository.dart';
import '../../repositories/gacha_repository.dart';
// ▼ 作成したダイアログをインポート
import 'dialogs/category_edit_dialog.dart';

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

  // ガチャデータ
  List<GachaItem> _gachaItems = [];
  Map<String, int> _gachaCounts = {};

  bool _isLoading = true;

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

  // 追加・編集ダイアログを開く
  Future<void> _openEditDialog({
    required bool isExpense,
    CategoryTag? item,
    required int index,
  }) async {
    // 分割したダイアログウィジェットを呼び出す
    final CategoryTag? result = await showDialog<CategoryTag>(
      context: context,
      builder: (context) {
        return CategoryEditDialog(
          isExpense: isExpense,
          existingItem: item,
          gachaItems: _gachaItems,
          gachaCounts: _gachaCounts,
        );
      },
    );

    // 保存ボタンが押されてデータが返ってきた場合のみ更新
    if (result != null) {
      setState(() {
        final list = isExpense ? _expenseList : _cardList;
        if (item == null) {
          // 新規追加
          list.add(result);
        } else {
          // 編集更新
          list[index] = result;
        }
      });
      await _saveCurrentList();
    }
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
        onPressed: () => _openEditDialog(
          isExpense: _tabController.index == 0,
          index: -1,
          item: null,
        ),
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
                onPressed: () => _openEditDialog(
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
