import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../utils/simple_calculator.dart';

// ▼▼ StatelessWidget から StatefulWidget に変更 ▼▼
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
  String _formatExpression(String expression) {
    if (expression.isEmpty) return "";

    final formatter = NumberFormat("#,###");
    StringBuffer result = StringBuffer();
    String currentNum = "";

    for (int i = 0; i < expression.length; i++) {
      String char = expression[i];
      if (_isOperator(char)) {
        if (currentNum.isNotEmpty) {
          try {
            final numVal = int.parse(currentNum.replaceAll(',', ''));
            result.write(formatter.format(numVal));
          } catch (_) {
            result.write(currentNum);
          }
          currentNum = "";
        }
        result.write(char);
      } else {
        currentNum += char;
      }
    }
    if (currentNum.isNotEmpty) {
      try {
        final numVal = int.parse(currentNum.replaceAll(',', ''));
        result.write(formatter.format(numVal));
      } catch (_) {
        result.write(currentNum);
      }
    }

    return result.toString();
  }

  void _handleTap(BuildContext context, String value) {
    String text = widget.controller.text;
    final bool isInputOperator = _isOperator(value);

    // ▼▼ 追加: 1桁目（テキストが空）の時に演算子が押されたら無視する ▼▼
    if (text.isEmpty && isInputOperator) {
      return;
    }
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

    // 演算子の連続入力を防ぐ（置換する）
    if (isInputOperator && text.isNotEmpty) {
      final lastChar = text[text.length - 1];
      if (_isOperator(lastChar)) {
        text = text.substring(0, text.length - 1) + value;
        widget.controller.value = TextEditingValue(
          text: text,
          selection: TextSelection.collapsed(offset: text.length),
        );
        widget.onChanged(text);
        setState(() {}); // ▼▼ 再描画 ▼▼
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

    widget.controller.value = TextEditingValue(
      text: formattedText,
      selection: TextSelection.collapsed(offset: formattedText.length),
    );
    widget.onChanged(formattedText);
    setState(() {}); // ▼▼ 再描画 ▼▼
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

    widget.controller.value = TextEditingValue(
      text: formattedText,
      selection: TextSelection.collapsed(offset: formattedText.length),
    );
    widget.onChanged(formattedText);
    setState(() {}); // ▼▼ 再描画 ▼▼
  }

  void _handleClear() {
    widget.controller.clear();
    widget.onChanged("");
    setState(() {}); // ▼▼ 再描画 ▼▼
  }

  void _handleCalculate() {
    final result = SimpleCalculator.calculate(widget.controller.text);
    final formattedResult = _formatExpression(result);

    widget.controller.value = TextEditingValue(
      text: formattedResult,
      selection: TextSelection.collapsed(offset: formattedResult.length),
    );
    widget.onChanged(formattedResult);
    setState(() {}); // ▼▼ 再描画 ▼▼
  }

  @override
  Widget build(BuildContext context) {
    const Color bgColor = Color(0xFFF2F2F7);
    const Color btnColor = Colors.white;
    const Color shadowColor = Colors.black12;

    // 現在のテキストを取得
    String text = widget.controller.text;

    // ▼▼ 判定：末尾が "x" で終わっているか？ ▼▼
    // "100x" の状態なら true になり、ボタンが税率に変わります
    bool isMultiplyMode = text.isNotEmpty && text.endsWith("x");

    // ▼▼ ここで状態を見てボタンを切り替える判定を行う ▼▼
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

    return Container(
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
                    // ▼▼ 「保存して閉じる」ボタンの表示制御 ▼▼
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
                      icon: const Icon(Icons.keyboard_hide, color: Colors.grey),
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
                                    // 左側のボタン (通常は0、xの後は 1.1)
                                    buildKey(
                                      isMultiplyMode ? "1.1" : "0",
                                      // 税率モードの時は少し色を変えて強調しても良いですが、
                                      // ここではシンプルに文字色だけ変えるか、標準のままでいきます。
                                      // 今回は分かりやすく太字のままにします。
                                    ),

                                    // 中央のボタン (通常は00、xの後は 1.08)
                                    // flex: 2 で横幅2倍
                                    buildKey(
                                      isMultiplyMode ? "1.08" : "00",
                                      flex: 2,
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
                              // ▼▼ 計算記号の有無でボタンの色と機能を切り替え ▼▼
                              color: hasOperator ? Colors.orange : Colors.blue,
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
                                    mainAxisAlignment: MainAxisAlignment.center,
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
    );
  }
}
