import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../utils/simple_calculator.dart';

class CustomNumberKeyboard extends StatefulWidget {
  final TextEditingController controller;
  final VoidCallback onSubmitted; // 次へ
  final VoidCallback? onSaveAndClose; // 保存して閉じる
  final VoidCallback? onUndo;
  final VoidCallback onClose; // キーボードを閉じる
  final ValueChanged<String> onChanged;
  final int maxLength;

  const CustomNumberKeyboard({
    super.key,
    required this.controller,
    required this.onSubmitted,
    this.onSaveAndClose,
    this.onUndo,
    required this.onClose,
    required this.onChanged,
    this.maxLength = 20,
  });

  @override
  State<CustomNumberKeyboard> createState() => _CustomNumberKeyboardState();
}

class _CustomNumberKeyboardState extends State<CustomNumberKeyboard> {
  // 演算子かどうか判定
  bool _isOperator(String value) {
    return ["+", "-", "x", "÷"].contains(value);
  }

  // 文字列全体をフォーマット（カンマ区切り）し直す関数
  // 修正：int.parse ではなく double.tryParse を使い、小数が来ても安全に処理するように変更
  String _formatExpression(String expression) {
    if (expression.isEmpty) return "";

    final formatter = NumberFormat("#,###");
    StringBuffer result = StringBuffer();
    String currentNum = "";

    // バッファにある数値を処理して書き込むヘルパー関数
    void flushCurrentNum() {
      if (currentNum.isEmpty) return;

      // カンマを除去して解析準備
      String cleanNum = currentNum.replaceAll(',', '');

      // doubleとして解析を試みる
      double? val = double.tryParse(cleanNum);

      // 数値として有効、かつ小数点が含まれていない場合のみカンマフォーマットする
      // (入力中の "1." や小数の "1.08" などはフォーマットせずそのまま表示する)
      if (val != null && !cleanNum.contains('.')) {
        // 整数部としてフォーマットできるか確認
        try {
          // formatter.format(double) だと挙動により小数が丸められることがあるため
          // 明示的に整数として扱う
          result.write(formatter.format(val.toInt()));
        } catch (_) {
          result.write(currentNum);
        }
      } else {
        // 小数やパース不能な文字列はそのまま書き込む
        result.write(currentNum);
      }
      currentNum = "";
    }

    for (int i = 0; i < expression.length; i++) {
      String char = expression[i];
      if (_isOperator(char)) {
        // 演算子が来たら、溜まっていた数値を書き出す
        flushCurrentNum();
        result.write(char);
      } else {
        currentNum += char;
      }
    }
    // ループ終了後に残っている数値を書き出す
    flushCurrentNum();

    return result.toString();
  }

  void _handleTap(BuildContext context, String value) {
    String text = widget.controller.text;
    final bool isInputOperator = _isOperator(value);

    // 1桁目（テキストが空）の時に演算子が押されたら無視する
    if (text.isEmpty && isInputOperator) {
      return;
    }

    // 文字数制限チェック
    if (!isInputOperator && text.length >= widget.maxLength) {
      ScaffoldMessenger.of(context).clearSnackBars();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('これ以上入力できません'),
          duration: Duration(milliseconds: 500),
        ),
      );
      return;
    }

    // 演算子の連続入力を防ぐ（末尾の演算子を置換する）
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

    String formattedText = _formatExpression(rawText);
    _updateController(formattedText);
  }

  void _handleClear() {
    widget.controller.clear();
    widget.onChanged("");
    setState(() {});
  }

  void _handleCalculate() {
    final result = SimpleCalculator.calculate(widget.controller.text);
    final formattedResult = _formatExpression(result);
    _updateController(formattedResult);
  }

  // コントローラー更新とState更新をまとめたメソッド
  void _updateController(String newText) {
    widget.controller.value = TextEditingValue(
      text: newText,
      selection: TextSelection.collapsed(offset: newText.length),
    );
    widget.onChanged(newText);
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    const Color bgColor = Color(0xFFF2F2F7);
    const Color btnColor = Colors.white;
    const Color shadowColor = Colors.black12;

    // 現在のテキストを取得
    String text = widget.controller.text;

    // 判定：末尾が "x" で終わっているか？
    bool isMultiplyMode = text.isNotEmpty && text.endsWith("x");

    // 計算記号が含まれているか判定
    final bool hasOperator = [
      "+",
      "-",
      "x",
      "÷",
    ].any((o) => widget.controller.text.contains(o));

    Widget buildKey(
      String label, {
      Color textColor = Colors.black,
      Color? color,
      int flex = 1,
      VoidCallback? onTap,
      bool isBold = true,
    }) {
      return Expanded(
        flex: flex,
        child: Padding(
          padding: const EdgeInsets.all(4.0),
          child: Material(
            color: color ?? btnColor,
            elevation: 1,
            shadowColor: shadowColor,
            borderRadius: BorderRadius.circular(8),
            child: InkWell(
              onTap: onTap ?? () => _handleTap(context, label),
              borderRadius: BorderRadius.circular(8),
              child: Container(
                alignment: Alignment.center,
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 22,
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

    Widget buildFunctionKey(
      String label,
      VoidCallback onTap, {
      Color textColor = Colors.black,
    }) {
      return buildKey(label, onTap: onTap, textColor: textColor, isBold: true);
    }

    return GestureDetector(
      onTap: () {
        // キーボード内のタップが背後の「閉じる判定」に伝わるのを防ぐ
      },
      behavior: HitTestBehavior.opaque,
      child: Container(
        color: bgColor,
        width: double.infinity,
        child: Column(
          children: [
            SizedBox(
              height: 40,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  if (widget.onUndo != null)
                    Padding(
                      padding: const EdgeInsets.only(left: 4),
                      child: TextButton.icon(
                        onPressed: widget.onUndo,
                        icon: const Icon(Icons.undo, size: 18),
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

                  Row(
                    children: [
                      // 「保存して閉じる」ボタンの表示制御
                      if (widget.onSaveAndClose != null && !hasOperator) ...[
                        TextButton.icon(
                          onPressed: widget.onSaveAndClose,
                          icon: const Icon(Icons.check_circle, size: 18),
                          label: const Text(
                            '保存して閉じる',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          style: TextButton.styleFrom(
                            foregroundColor: Colors.blue.shade700,
                            visualDensity: VisualDensity.compact,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Container(
                          width: 1,
                          height: 20,
                          color: Colors.grey.shade300,
                        ),
                        const SizedBox(width: 4),
                      ],
                      IconButton(
                        onPressed: widget.onClose,
                        icon: const Icon(
                          Icons.keyboard_hide,
                          color: Colors.grey,
                        ),
                        tooltip: 'キーボードを閉じる',
                      ),
                      const SizedBox(width: 8),
                    ],
                  ),
                ],
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(4, 0, 4, 4),
                child: Column(
                  children: [
                    Expanded(
                      child: Row(
                        children: [
                          buildKey("7"),
                          buildKey("8"),
                          buildKey("9"),
                          buildKey("÷", textColor: Colors.black87),
                          buildFunctionKey(
                            "AC",
                            _handleClear,
                            textColor: Colors.black54,
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: Row(
                        children: [
                          buildKey("4"),
                          buildKey("5"),
                          buildKey("6"),
                          buildKey("x", textColor: Colors.black87),
                          buildFunctionKey(
                            "Del",
                            _handleDelete,
                            textColor: Colors.deepOrange,
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      flex: 2,
                      child: Row(
                        children: [
                          Expanded(
                            flex: 4,
                            child: Column(
                              children: [
                                Expanded(
                                  child: Row(
                                    children: [
                                      buildKey("1"),
                                      buildKey("2"),
                                      buildKey("3"),
                                      buildKey("-", textColor: Colors.black87),
                                    ],
                                  ),
                                ),
                                Expanded(
                                  child: Row(
                                    children: [
                                      // 左側のボタン
                                      buildKey(
                                        isMultiplyMode ? "1.1" : "0",
                                        color: isMultiplyMode ? null : null,
                                        textColor: isMultiplyMode
                                            ? Colors.orange
                                            : Colors.black,
                                      ),

                                      // 中央のボタン
                                      buildKey(
                                        isMultiplyMode ? "1.08" : "00",
                                        flex: 2,
                                        color: isMultiplyMode ? null : null,
                                        textColor: isMultiplyMode
                                            ? Colors.orange
                                            : Colors.black,
                                      ),

                                      // 右のプラスボタン
                                      buildKey("+", textColor: Colors.black87),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Expanded(
                            flex: 1,
                            child: Padding(
                              padding: const EdgeInsets.all(4.0),
                              child: Material(
                                color: hasOperator
                                    ? Colors.orange
                                    : Colors.blue,
                                elevation: 1,
                                borderRadius: BorderRadius.circular(8),
                                child: InkWell(
                                  onTap: hasOperator
                                      ? _handleCalculate
                                      : widget.onSubmitted,
                                  borderRadius: BorderRadius.circular(8),
                                  child: Container(
                                    alignment: Alignment.center,
                                    child: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          hasOperator
                                              ? Icons.calculate
                                              : Icons.playlist_add,
                                          color: Colors.white,
                                          size: 28,
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          hasOperator ? "＝" : "次へ",
                                          style: const TextStyle(
                                            fontSize: 14,
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
                          ),
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
}
