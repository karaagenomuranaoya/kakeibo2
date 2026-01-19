import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../utils/simple_calculator.dart';

class CustomNumberKeyboard extends StatefulWidget {
  final TextEditingController controller;
  final VoidCallback onSubmitted; // 「次へ」アクション
  final VoidCallback? onSaveAndClose; // 「保存」アクション
  final VoidCallback? onUndo;
  final VoidCallback onClose;
  final ValueChanged<String> onChanged;
  final int maxLength;
  final VoidCallback? onDebugCodeEntered;

  const CustomNumberKeyboard({
    super.key,
    required this.controller,
    required this.onSubmitted,
    this.onSaveAndClose,
    this.onUndo,
    required this.onClose,
    required this.onChanged,
    this.maxLength = 20,
    this.onDebugCodeEntered,
  });

  @override
  State<CustomNumberKeyboard> createState() => _CustomNumberKeyboardState();
}

class _CustomNumberKeyboardState extends State<CustomNumberKeyboard> {
  // ▼▼ 入力履歴（デバッグコマンド判定用） ▼▼
  final List<String> _inputHistory = [];
  static const List<String> _debugSequence = [
    "1",
    "2",
    "3",
    "4",
    "1",
    "2",
    "3",
    "4",
    "+",
    "-",
    "x",
    "÷",
    "÷",
    "x",
    "-",
    "+",
  ];

  @override
  Widget build(BuildContext context) {
    const Color bgColor = Color(0xFFF2F2F7);

    // 現在のテキスト状態判定
    final String text = widget.controller.text;
    final bool isMultiplyMode = text.isNotEmpty && text.endsWith("x");
    final bool hasOperator = ["+", "-", "x", "÷"].any((o) => text.contains(o));

    return GestureDetector(
      onTap: () {}, // タップイベントの透過防止
      behavior: HitTestBehavior.opaque,
      child: Container(
        color: bgColor,
        width: double.infinity,
        // ▼▼ 変更: 下部のパディングを増やして高さを確保 ▼▼
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).padding.bottom + 8,
        ),
        child: Column(
          children: [
            // --- ヘッダー部分 ---
            _buildHeader(hasOperator),

            // --- キーパッド部分 ---
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                child: Column(
                  children: [
                    // 1段目: 7, 8, 9, ÷, AC
                    Expanded(
                      child: Row(
                        children: [
                          _buildNumberKey("7"),
                          _buildNumberKey("8"),
                          _buildNumberKey("9"),
                          _buildNumberKey("÷", textColor: Colors.black87),
                          _buildActionKey(
                            "AC",
                            _handleClear,
                            textColor: Colors.black54,
                          ),
                        ],
                      ),
                    ),
                    // 2段目: 4, 5, 6, x, Del
                    Expanded(
                      child: Row(
                        children: [
                          _buildNumberKey("4"),
                          _buildNumberKey("5"),
                          _buildNumberKey("6"),
                          _buildNumberKey("x", textColor: Colors.black87),
                          _buildActionKey(
                            "Del",
                            _handleDelete,
                            textColor: Colors.deepOrange,
                          ),
                        ],
                      ),
                    ),
                    // 3段目 (下半分)
                    Expanded(
                      flex: 2,
                      child: Row(
                        children: [
                          // 左側の数字キーブロック
                          Expanded(
                            flex: 4,
                            child: Column(
                              children: [
                                // 3段目上: 1, 2, 3, -
                                Expanded(
                                  child: Row(
                                    children: [
                                      _buildNumberKey("1"),
                                      _buildNumberKey("2"),
                                      _buildNumberKey("3"),
                                      _buildNumberKey(
                                        "-",
                                        textColor: Colors.black87,
                                      ),
                                    ],
                                  ),
                                ),
                                // 3段目下: 0/Tax, 00/Tax, +
                                Expanded(
                                  child: Row(
                                    children: [
                                      _buildNumberKey(
                                        isMultiplyMode ? "1.1" : "0",
                                        textColor: isMultiplyMode
                                            ? Colors.orange
                                            : Colors.black,
                                      ),
                                      _buildNumberKey(
                                        isMultiplyMode ? "1.08" : "00",
                                        flex: 2,
                                        textColor: isMultiplyMode
                                            ? Colors.orange
                                            : Colors.black,
                                      ),
                                      _buildNumberKey(
                                        "+",
                                        textColor: Colors.black87,
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          // 右下のメインアクションボタン（保存 / ＝）
                          _buildMainActionButton(hasOperator),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- ヘッダー構築 ---
  Widget _buildHeader(bool hasOperator) {
    return SizedBox(
      // ▼▼ 変更: 高さを少し広げてタップしやすく ▼▼
      height: 48,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // 左側: Undoボタン
          if (widget.onUndo != null)
            Padding(
              padding: const EdgeInsets.only(left: 8),
              child: TextButton.icon(
                onPressed: widget.onUndo,
                icon: const Icon(Icons.undo, size: 20),
                label: const Text(
                  '1つ戻す',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                style: TextButton.styleFrom(
                  foregroundColor: Colors.black54,
                  visualDensity: VisualDensity.compact,
                ),
              ),
            )
          else
            const SizedBox(),

          // 右側: 次へ & 閉じる
          Row(
            children: [
              // ▼▼ 変更: ヘッダーに「次へ」ボタンを配置（計算中でない場合） ▼▼
              if (!hasOperator) ...[
                TextButton.icon(
                  onPressed: widget.onSubmitted,
                  icon: const Icon(Icons.arrow_forward, size: 20),
                  label: const Text(
                    '次へ',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.blue.shade700,
                    visualDensity: VisualDensity.compact,
                  ),
                ),
                const SizedBox(width: 8),
                Container(width: 1, height: 24, color: Colors.grey.shade300),
                const SizedBox(width: 4),
              ],

              // 閉じるボタン
              IconButton(
                onPressed: widget.onClose,
                icon: const Icon(Icons.keyboard_hide, color: Colors.grey),
                tooltip: 'キーボードを閉じる',
              ),
              const SizedBox(width: 8),
            ],
          ),
        ],
      ),
    );
  }

  // --- メインアクションボタン（右下） ---
  Widget _buildMainActionButton(bool hasOperator) {
    // 計算中は「＝」、それ以外は「保存」
    final bool isCalculateMode = hasOperator;
    final String label = isCalculateMode ? "＝" : "保存";
    final IconData icon = isCalculateMode
        ? Icons.calculate
        : Icons.check_circle_outline;
    final Color color = isCalculateMode ? Colors.orange : Colors.blue;
    final VoidCallback? onTap = isCalculateMode
        ? _handleCalculate
        : (widget.onSaveAndClose ?? widget.onSubmitted); // 保存がない場合は次へで代用

    return Expanded(
      flex: 1,
      child: Padding(
        padding: const EdgeInsets.all(4.0),
        child: Material(
          color: color,
          elevation: 1,
          borderRadius: BorderRadius.circular(12), // 少し丸みを増やす
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(12),
            child: Container(
              alignment: Alignment.center,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(icon, color: Colors.white, size: 30),
                  const SizedBox(height: 4),
                  Text(
                    label,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // --- ヘルパーメソッド: キー生成 ---
  Widget _buildNumberKey(
    String label, {
    int flex = 1,
    Color textColor = Colors.black,
  }) {
    return _KeyboardKey(
      label: label,
      flex: flex,
      textColor: textColor,
      onTap: () => _handleTap(label),
    );
  }

  Widget _buildActionKey(
    String label,
    VoidCallback onTap, {
    Color textColor = Colors.black,
  }) {
    return _KeyboardKey(
      label: label,
      textColor: textColor,
      onTap: onTap,
      isBold: true,
      fontSize: 18,
    );
  }

  // --- ロジック部分 ---

  bool _isOperator(String value) {
    return ["+", "-", "x", "÷"].contains(value);
  }

  String _formatExpression(String expression) {
    if (expression.isEmpty) return "";
    final formatter = NumberFormat("#,###");
    StringBuffer result = StringBuffer();
    String currentNum = "";

    void flushCurrentNum() {
      if (currentNum.isEmpty) return;
      String cleanNum = currentNum.replaceAll(',', '');
      double? val = double.tryParse(cleanNum);
      if (val != null && !cleanNum.contains('.')) {
        try {
          result.write(formatter.format(val.toInt()));
        } catch (_) {
          result.write(currentNum);
        }
      } else {
        result.write(currentNum);
      }
      currentNum = "";
    }

    for (int i = 0; i < expression.length; i++) {
      String char = expression[i];
      if (_isOperator(char)) {
        flushCurrentNum();
        result.write(char);
      } else {
        currentNum += char;
      }
    }
    flushCurrentNum();
    return result.toString();
  }

  void _handleTap(String value) {
    // デバッグコマンド判定
    _inputHistory.add(value);
    if (_inputHistory.length > _debugSequence.length) {
      _inputHistory.removeAt(0);
    }
    if (_inputHistory.length == _debugSequence.length) {
      bool isMatch = true;
      for (int i = 0; i < _debugSequence.length; i++) {
        if (_inputHistory[i] != _debugSequence[i]) {
          isMatch = false;
          break;
        }
      }
      if (isMatch) {
        _inputHistory.clear();
        widget.onDebugCodeEntered?.call();
        return;
      }
    }

    String text = widget.controller.text;
    final bool isInputOperator = _isOperator(value);

    if (text.isEmpty && isInputOperator) return;

    // ▼▼ 変更: ここから桁数制限ロジック ▼▼

    // 1. 全体の文字数制限（計算式が長くなりすぎてエラーになるのを防ぐ安全弁）
    // 数字だけでなく演算子も含んだ全体の長さチェック
    if (text.length >= 30) {
      // 少し余裕を持たせて30文字くらいで止める
      _showWarning(context, 'これ以上入力できません');
      return;
    }

    // 2. 数値単体の桁数制限（これがメインの10桁制限）
    // 入力しようとしているのが「数字」の場合のみチェック
    if (!isInputOperator) {
      // 今入力している数値の部分を取り出す（演算子で区切られた最後の塊）
      // 例: "100+1234" -> ["100", "1234"] -> "1234"
      final parts = text.split(RegExp(r'[\+\-x÷]'));
      final currentNumStr = parts.isNotEmpty ? parts.last : "";

      // カンマを除去して純粋な数字の長さをカウント
      final currentDigits = currentNumStr.replaceAll(',', '').length;

      // 既に10桁あって、さらに数字を足そうとしているならブロック
      if (currentDigits >= 10) {
        _showWarning(context, '10桁までしか入力できません');
        return;
      }
    }
    // ▲▲ 変更ここまで ▲▲

    // if (!isInputOperator && text.length >= widget.maxLength) {
    //   ScaffoldMessenger.of(context).clearSnackBars();
    //   ScaffoldMessenger.of(context).showSnackBar(
    //     const SnackBar(
    //       content: Text('これ以上入力できません'),
    //       duration: Duration(milliseconds: 500),
    //     ),
    //   );
    //   return;
    // }

    // 演算子の連続入力防止（置換）
    if (isInputOperator && text.isNotEmpty) {
      final lastChar = text[text.length - 1];
      if (_isOperator(lastChar)) {
        text = text.substring(0, text.length - 1) + value;
        _updateController(text);
        return;
      }
    }

    final selection = widget.controller.selection;
    int start = selection.start;
    int end = selection.end;
    if (start < 0) {
      start = text.length;
      end = text.length;
    }

    String newText = text.replaceRange(start, end, value);
    String formattedText = _formatExpression(newText);
    _updateController(formattedText);
  }

  // ▼▼ 追加: 警告メッセージを出すヘルパーメソッド ▼▼
  void _showWarning(BuildContext context, String msg) {
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        duration: const Duration(milliseconds: 1000),
      ),
    );
  }

  void _handleDelete() {
    String text = widget.controller.text;
    if (text.isEmpty) return;

    final selection = widget.controller.selection;
    int start = selection.start;
    int end = selection.end;
    if (start < 0) start = text.length;
    if (end < 0) end = text.length;

    String rawText;
    if (start != end) {
      rawText = text.replaceRange(start, end, "");
    } else if (start > 0) {
      rawText = text.replaceRange(start - 1, start, "");
    } else {
      return;
    }
    _updateController(_formatExpression(rawText));
  }

  void _handleClear() {
    widget.controller.clear();
    widget.onChanged("");
    setState(() {});
  }

  void _handleCalculate() {
    // 1. 計算実行
    final resultString = SimpleCalculator.calculate(widget.controller.text);
    double? val = double.tryParse(resultString);

    if (val == null) return; // 計算不能

    // 2. 例外チェック（ここを強化！）

    // A. ゼロ除算 (例: 100 ÷ 0) -> 無限大(Infinity)になる
    if (val.isInfinite || val.isNaN) {
      _showWarning(context, '0では割れません');
      return;
    }

    // B. 金額が大きすぎる (10桁以上)
    if (val.abs() >= 10000000000) {
      _showWarning(context, '金額が大きすぎます');
      return;
    }

    // C. マイナスになる (例: 100 - 200)
    if (val < 0) {
      _showWarning(context, 'マイナスの金額は入力できません');
      return;
    }

    // D. 0円になる (例: 100 - 100)
    // ※ 入力中は0でもいいですが、計算結果として0が確定するのは無意味なので弾きます
    if (val == 0) {
      _showWarning(context, '金額が0円になってしまいます');
      return;
    }

    // 3. 問題なければ表示を更新
    final formattedResult = _formatExpression(resultString);
    _updateController(formattedResult);
  }

  void _updateController(String newText) {
    widget.controller.value = TextEditingValue(
      text: newText,
      selection: TextSelection.collapsed(offset: newText.length),
    );
    widget.onChanged(newText);
    setState(() {});
  }
}

// ▼▼ 分割したキーウィジェット ▼▼
class _KeyboardKey extends StatelessWidget {
  final String label;
  final int flex;
  final Color textColor;
  final VoidCallback onTap;
  final bool isBold;
  final double fontSize;

  const _KeyboardKey({
    required this.label,
    this.flex = 1,
    required this.textColor,
    required this.onTap,
    this.isBold = true,
    this.fontSize = 22,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      flex: flex,
      child: Padding(
        padding: const EdgeInsets.all(4.0), // キー同士の間隔
        child: Material(
          color: Colors.white,
          elevation: 1,
          shadowColor: Colors.black12,
          borderRadius: BorderRadius.circular(8),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(8),
            child: Container(
              alignment: Alignment.center,
              child: Text(
                label,
                style: TextStyle(
                  fontSize: fontSize,
                  fontWeight: isBold ? FontWeight.bold : FontWeight.w500,
                  color: textColor,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
