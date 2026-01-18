import 'package:flutter/material.dart';

import '../models/category_tag.dart';
import '../widgets/category_selector.dart';
import '../widgets/custom_number_keyboard.dart';
import '../widgets/flash_message.dart';
import '../widgets/input/amount_input_area.dart';
import '../widgets/input/input_control_panel.dart';
import '../widgets/input/payment_selector.dart';
import 'history_screen.dart';
import 'input/input_tab_tutorial.dart';
import 'input/input_tab_view_model.dart'; // Import ViewModel
import 'settings/category_manage_screen.dart';

class InputTab extends StatefulWidget {
  final int dataVersion;
  final Function(bool visible)? onTabBarVisibilityChanged;

  const InputTab({
    super.key,
    this.dataVersion = 0,
    this.onTabBarVisibilityChanged,
  });

  @override
  State<InputTab> createState() => _InputTabState();
}

class _InputTabState extends State<InputTab>
    with AutomaticKeepAliveClientMixin, WidgetsBindingObserver {
  // ロジックを保持するViewModel
  late final InputTabViewModel _vm;

  // チュートリアル用のKey（View固有のものなのでここに残す）
  final GlobalKey _paymentKey = GlobalKey();
  final GlobalKey _categoryKey = GlobalKey();

  static const double _keyboardHeight = 312.0;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    _vm = InputTabViewModel();
    _vm.loadData().then((_) => _checkTutorial());

    // キーボード表示状態の変化を監視してTabBar制御
    _vm.addListener(_onVmStateChanged);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _vm.removeListener(_onVmStateChanged);
    _vm.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant InputTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.dataVersion != widget.dataVersion) {
      _vm.loadData();
    }
  }

  @override
  void didChangeMetrics() {
    super.didChangeMetrics();
    // システムキーボードが出たかどうかの判定
    final bottomInset = View.of(context).viewInsets.bottom;
    if (bottomInset > 0) {
      _vm.onSystemKeyboardShown();
    }
  }

  void _onVmStateChanged() {
    // ViewModelの状態に応じてTabBarの表示/非表示を親に通知
    // (カスタムキーボード表示中ならTabBarを隠す)
    widget.onTabBarVisibilityChanged?.call(!_vm.showCustomKeyboard);
  }

  void _checkTutorial() {
    if (!mounted || _vm.data == null) return;
    if (_vm.data!.shouldShowTutorial) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        InputTabTutorial.show(
          context,
          paymentKey: _paymentKey,
          categoryKey: _categoryKey,
          showCardOnInput: _vm.data!.showCardOnInput,
          onFinish: _vm.markTutorialAsShown,
        );
      });
    }
  }

  // --- Navigation Helpers ---
  void _onCategoryLongPress(int index) {
    if (!_vm.data!.isCategoryLongPressEnabled) return;
    if (index >= _vm.data!.expenses.length) return;

    _vm.closeKeyboard();
    final tag = _vm.data!.expenses[index];
    _navigateToHistory(tag.label, 'expense', tag.color);
  }

  void _onCardLongPress(CategoryTag tag) {
    _vm.closeKeyboard();
    _navigateToHistory(tag.label, 'payment', tag.color);
  }

  void _navigateToHistory(String val, String key, Color color) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            HistoryScreen(filterValue: val, filterKey: key, color: color),
      ),
    );
  }

  Future<void> _openCategorySettings() async {
    // 現在の状態を保存
    _vm.setExpenseIndex(_vm.selectedExpenseIndex);

    if (!mounted) return;
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const CategoryManageScreen()),
    );
    _vm.loadData();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    // ViewModelの変更を監視して再描画
    return AnimatedBuilder(
      animation: _vm,
      builder: (context, child) {
        if (_vm.isLoading || _vm.data == null) {
          return const Center(child: CircularProgressIndicator());
        }

        // レイアウト計算
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
              // メインコンテンツエリア
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
                          onTap: () {}, // チュートリアル用のダミー
                          child: PaymentSelector(
                            isCardPayment: _vm.isCardPayment,
                            onToggle: _vm.toggleCardPayment,
                            cardList: _vm.data!.cards,
                            selectedCardIndex: _vm.selectedCardIndex,
                            onCardSelected: _vm.setCardIndex,
                            onCardLongPress: _onCardLongPress,
                          ),
                        )
                      else
                        const SizedBox(height: 24),

                      CategorySelector(
                        key: _categoryKey,
                        tags: _vm.data!.expenses,
                        selectedIndex: _vm.selectedExpenseIndex,
                        onSelected: _vm.setExpenseIndex,
                        onLongPress: _vm.data!.isCategoryLongPressEnabled
                            ? _onCategoryLongPress
                            : null,
                        onAddPressed: _openCategorySettings,
                      ),
                      const SizedBox(height: 20),

                      InputControlPanel(
                        onSave: () => _vm.saveData(keepKeyboard: false),
                        onUndo: () => _vm.undoLastInput(context),
                        showUndo: _vm.lastInputId != null,
                      ),
                    ],
                  ),
                ),
              ),

              // カスタムキーボード
              if (_vm.showCustomKeyboard)
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  height: _keyboardHeight,
                  child: CustomNumberKeyboard(
                    controller: _vm.amountController,
                    onSubmitted: () => _vm.saveData(keepKeyboard: true),
                    onSaveAndClose: () => _vm.saveData(keepKeyboard: false),
                    onUndo: _vm.lastInputId != null
                        ? () => _vm.undoLastInput(context)
                        : null,
                    onClose: _vm.closeKeyboard,
                    onChanged: (_) {},
                    // ▼▼ 追加: デモデータ注入用コールバック ▼▼
                    onDebugCodeEntered: () =>
                        _vm.confirmAndInjectDemoData(context),
                  ),
                ),

              // フラッシュメッセージ
              FlashMessage(
                isVisible: _vm.isFlashVisible,
                message: _vm.flashMsg,
                color: _vm.flashColor,
              ),
            ],
          ),
        );
      },
    );
  }
}
