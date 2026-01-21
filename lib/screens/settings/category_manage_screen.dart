import 'package:flutter/material.dart';
import '../../models/category_tag.dart';
import '../../models/gacha_item.dart';
import '../../models/transaction_item.dart';
import '../../repositories/settings_repository.dart';
import '../../repositories/gacha_repository.dart';
import '../../repositories/transaction_repository.dart';
import 'dialogs/category_edit_dialog.dart';

enum _DeleteAction { deleteAll, move }

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

  List<GachaItem> _gachaItems = [];
  Map<String, int> _gachaCounts = {};

  bool _isLoading = true;
  // 現在のタブインデックスを保持する変数（FAB用）
  int _currentTabIndex = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    // タブ切り替えを監視してFABの動作を更新する
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        setState(() {
          _currentTabIndex = _tabController.index;
        });
      }
    });
    _loadData();
  }

  // タブコントローラーの破棄忘れ防止
  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
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

  Future<void> _openEditDialog({
    required bool isExpense,
    CategoryTag? item,
    required int index,
  }) async {
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

    if (result != null) {
      setState(() {
        final list = isExpense ? _expenseList : _cardList;
        if (item == null) {
          list.add(result);
        } else {
          list[index] = result;
        }
      });
      await _saveCurrentList();
    }
  }

  void _deleteItem(bool isExpense, int index) async {
    final list = isExpense ? _expenseList : _cardList;
    final itemToDelete = list[index];

    // 使用状況の確認
    final transactionRepo = TransactionRepository();
    final allTransactions = await transactionRepo.getAllTransactions();

    int usageCount = 0;
    if (isExpense) {
      usageCount = allTransactions
          .where(
            (t) =>
                (t.expenseId != null && t.expenseId == itemToDelete.id) ||
                (t.expenseId == null && t.expense == itemToDelete.label),
          )
          .length;
    } else {
      usageCount = allTransactions
          .where(
            (t) =>
                (t.paymentId != null && t.paymentId == itemToDelete.id) ||
                (t.paymentId == null && t.payment == itemToDelete.label),
          )
          .length;
    }

    if (usageCount == 0) {
      // 使用されていない場合でも確認ダイアログを表示
      if (!mounted) return;
      final confirm = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('カテゴリの削除'),
          content: Text('カテゴリ「${itemToDelete.label}」を削除しますか？'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('キャンセル'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('削除'),
            ),
          ],
        ),
      );

      if (confirm == true) {
        _performDelete(isExpense, index);
      }
      return;
    }

    if (!mounted) return;

    // ダイアログ表示
    final action = await showDialog<_DeleteAction>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('カテゴリの削除'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('「${itemToDelete.label}」は $usageCount 件のデータで使用されています。'),
              const SizedBox(height: 16),
              const Text('削除にあたり、これらのデータの扱いを選択してください。'),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('キャンセル'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, _DeleteAction.deleteAll),
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('データごと削除'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, _DeleteAction.move),
              child: const Text('移動して削除'),
            ),
          ],
        );
      },
    );

    if (action == null) return;

    if (action == _DeleteAction.deleteAll) {
      // 関連データを削除してカテゴリも削除
      await _deleteTransactions(itemToDelete, isExpense);
      _performDelete(isExpense, index);
    } else if (action == _DeleteAction.move) {
      // 移動先を選択
      final target = await _showMoveTargetDialog(isExpense, itemToDelete);
      if (target != null) {
        await _moveTransactions(itemToDelete, target, isExpense);
        _performDelete(isExpense, index);
      }
    }
  }

  Future<void> _performDelete(bool isExpense, int index) async {
    setState(() {
      if (isExpense) {
        _expenseList.removeAt(index);
      } else {
        _cardList.removeAt(index);
      }
    });
    await _saveCurrentList();
  }

  Future<void> _deleteTransactions(
    CategoryTag itemToDelete,
    bool isExpense,
  ) async {
    final transactionRepo = TransactionRepository();
    final allTransactions = await transactionRepo.getAllTransactions();
    final toDelete = <String>[];

    for (final t in allTransactions) {
      bool match = false;
      if (isExpense) {
        match =
            (t.expenseId != null && t.expenseId == itemToDelete.id) ||
            (t.expenseId == null && t.expense == itemToDelete.label);
      } else {
        match =
            (t.paymentId != null && t.paymentId == itemToDelete.id) ||
            (t.paymentId == null && t.payment == itemToDelete.label);
      }
      if (match) {
        toDelete.add(t.id);
      }
    }

    for (final id in toDelete) {
      await transactionRepo.deleteTransaction(id);
    }
  }

  Future<CategoryTag?> _showMoveTargetDialog(
    bool isExpense,
    CategoryTag itemToDelete,
  ) async {
    final list = isExpense ? _expenseList : _cardList;
    final candidates = list.where((e) => e.id != itemToDelete.id).toList();

    if (candidates.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('移動先のカテゴリがありません')));
      return null;
    }

    return await showDialog<CategoryTag>(
      context: context,
      builder: (context) {
        return SimpleDialog(
          title: const Text('移動先を選択'),
          children: candidates.map((c) {
            return SimpleDialogOption(
              onPressed: () => Navigator.pop(context, c),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Row(
                  children: [
                    Icon(c.displayIcon, color: c.color, size: 20),
                    const SizedBox(width: 12),
                    Text(c.label),
                  ],
                ),
              ),
            );
          }).toList(),
        );
      },
    );
  }

  Future<void> _moveTransactions(
    CategoryTag from,
    CategoryTag to,
    bool isExpense,
  ) async {
    final transactionRepo = TransactionRepository();
    final allTransactions = await transactionRepo.getAllTransactions();
    final toUpdate = <TransactionItem>[];

    for (final t in allTransactions) {
      bool match = false;
      if (isExpense) {
        match =
            (t.expenseId != null && t.expenseId == from.id) ||
            (t.expenseId == null && t.expense == from.label);
      } else {
        match =
            (t.paymentId != null && t.paymentId == from.id) ||
            (t.paymentId == null && t.payment == from.label);
      }

      if (match) {
        // 更新
        if (isExpense) {
          toUpdate.add(
            t.copyWith(expense: to.label, expenseId: to.id),
          ); // labelも更新しておく(display fallback用)
        } else {
          toUpdate.add(t.copyWith(payment: to.label, paymentId: to.id));
        }
      }
    }

    for (final item in toUpdate) {
      await transactionRepo.updateTransaction(item);
    }
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
        // _tabController.index は非同期でズレることがあるため、listenerで更新した変数を使う
        onPressed: () => _openEditDialog(
          isExpense: _currentTabIndex == 0,
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
        // アイコンデータを変数に格納
        final iconData = item.displayIcon;

        return ListTile(
          key: ValueKey(item.id),
          leading: Container(
            width: 40,
            height: 40,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: item.color.withOpacity(0.1),
              // shapeとborderRadiusの競合を防ぐため、明示的に切り分ける
              shape: item.isCircle ? BoxShape.circle : BoxShape.rectangle,
              borderRadius: item.isCircle ? null : BorderRadius.circular(8),
              border: Border.all(color: item.color, width: 1.5),
            ),
            // ▼▼ 修正箇所: RepaintBoundaryとKeyで描画を安定化 ▼▼
            child: RepaintBoundary(
              child: Icon(
                iconData,
                // Keyを指定することで、データが変わった時や再利用時に確実に再構築させる
                key: ValueKey(iconData.hashCode),
                color: item.color,
                size: 20,
              ),
            ),
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
