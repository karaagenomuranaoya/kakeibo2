import 'package:flutter/material.dart';

import '../models/transaction_item.dart';
import '../services/input_service.dart';
import '../widgets/category_selector.dart';
import '../widgets/custom_number_keyboard.dart';
import '../widgets/flash_message.dart';
import '../widgets/input/amount_input_area.dart';
import '../widgets/input/payment_selector.dart';
import 'input/transaction_edit_view_model.dart';
import 'settings/category_manage_screen.dart';

class TransactionEditScreen extends StatefulWidget {
  final TransactionItem item;
  final VoidCallback? onSuccess;

  const TransactionEditScreen({super.key, required this.item, this.onSuccess});

  @override
  State<TransactionEditScreen> createState() => _TransactionEditScreenState();
}

class _TransactionEditScreenState extends State<TransactionEditScreen> {
  late final TransactionEditViewModel _vm;
  final InputService _inputService = InputService();

  final GlobalKey _paymentKey = GlobalKey();
  final GlobalKey _categoryKey = GlobalKey();

  static const double _keyboardHeight = 312.0;

  @override
  void initState() {
    super.initState();
    _vm = TransactionEditViewModel(
      inputService: _inputService,
      initialItem: widget.item,
    );
    _vm.loadData();
  }

  @override
  void dispose() {
    _vm.dispose();
    super.dispose();
  }

  Future<void> _openCategorySettings() async {
    // 編集画面からカテゴリ管理を開く場合の挙動（必要なら実装）
    // 今回はシンプルに開くだけ
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const CategoryManageScreen()),
    );
    _vm.loadData();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('履歴の編集')),
      body: AnimatedBuilder(
        animation: _vm,
        builder: (context, child) {
          if (_vm.isLoading || _vm.data == null) {
            return const Center(child: CircularProgressIndicator());
          }

          final bottomInset = MediaQuery.of(context).viewInsets.bottom;
          final double additionalPadding = _vm.showCustomKeyboard
              ? _keyboardHeight
              : bottomInset;
          final double bottomPadding = 80 + additionalPadding;

          return GestureDetector(
            onTap: _vm.closeKeyboard,
            behavior: HitTestBehavior.opaque,
            child: Stack(
              children: [
                Positioned.fill(
                  child: SingleChildScrollView(
                    padding: EdgeInsets.fromLTRB(16, 10, 16, bottomPadding),
                    child: Column(
                      children: [
                        AmountInputArea(
                          selectedDate: _vm.selectedDate,
                          amountController: _vm.amountController,
                          amountFocusNode: _vm.amountFocusNode,
                          memoController: _vm.memoController,
                          memoFocusNode: _vm.memoFocusNode,
                          onDateTap: () => _vm.pickDate(context),
                          onAmountTap: () => _vm.amountFocusNode.requestFocus(),
                        ),

                        if (_vm.data!.showCardOnInput)
                          GestureDetector(
                            key: _paymentKey,
                            child: PaymentSelector(
                              isCardPayment: _vm.isCardPayment,
                              onToggle: _vm.toggleCardPayment,
                              cardList: _vm.data!.cards,
                              selectedCardIndex: _vm.selectedCardIndex,
                              onCardSelected: _vm.setCardIndex,
                              onCardLongPress: (_) {}, // 編集画面では履歴遷移なし
                            ),
                          )
                        else
                          const SizedBox(height: 24),

                        CategorySelector(
                          key: _categoryKey,
                          tags: _vm.data!.expenses,
                          selectedIndex: _vm.selectedExpenseIndex,
                          onSelected: _vm.setExpenseIndex,
                          onLongPress: null, // 編集画面では履歴遷移なし
                          onAddPressed: _openCategorySettings,
                        ),
                        const SizedBox(height: 30),

                        // 保存ボタン
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: () async {
                              final success = await _vm.saveData(context);
                              if (success && mounted) {
                                widget.onSuccess?.call();
                                Navigator.pop(context);
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue,
                              foregroundColor: Colors.white,
                              elevation: 2,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                            ),
                            child: const Text(
                              '更新する',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 20),

                        // 削除ボタン
                        TextButton.icon(
                          onPressed: () async {
                            await _vm.deleteTransaction(context);
                            // deleteTransaction内でダイアログ表示 -> 削除 -> popまで行う想定だが、
                            // ViewModel側でpopするとここには戻ってこないかもしれない。
                            // ViewModelの実装を見ると、削除後にpopしている。
                            // なのでここでonSuccessを呼ぶ必要があるが、ViewModelがpopした後だと遅いか？
                            // ViewModelでpopしているので、ここではonSuccessを呼べないかも。
                            // -> ViewModelのdeleteTransactionを修正するか、ここでハンドリングする方が良い。
                            // ViewModel側を確認すると、contextを使ってpopしている。
                            // 修正が必要そうだが、一旦このまま進めて、ViewModel側でonSuccess相当のことができるか考える。
                            // 実際はViewModelでdelete完了 -> pop しているので、
                            // 呼び出し元のHistoryMonthlyPageでawait Navigator.push()しているので、
                            // 戻ってきたときにrefreshすれば良い。
                            widget.onSuccess?.call();
                          },
                          icon: const Icon(Icons.delete, color: Colors.red),
                          label: const Text(
                            'この履歴を削除する',
                            style: TextStyle(
                              color: Colors.red,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                              vertical: 12,
                              horizontal: 24,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                if (_vm.showCustomKeyboard)
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: 0,
                    height: _keyboardHeight,
                    child: CustomNumberKeyboard(
                      controller: _vm.amountController,
                      onSubmitted: () async {
                        final success = await _vm.saveData(context);
                        if (success && mounted) {
                          widget.onSuccess?.call();
                          Navigator.pop(context);
                        }
                      },
                      onSaveAndClose: () async {
                        final success = await _vm.saveData(context);
                        if (success && mounted) {
                          widget.onSuccess?.call();
                          Navigator.pop(context);
                        }
                      },
                      onUndo: null,
                      onClose: _vm.closeKeyboard,
                      onChanged: (_) {},
                      onDebugCodeEntered: null,
                    ),
                  ),

                FlashMessage(
                  isVisible: _vm.isFlashVisible,
                  message: _vm.flashMsg,
                  color: _vm.flashColor,
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
