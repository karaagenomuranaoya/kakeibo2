import 'package:flutter/material.dart';

class CustomNumberKeyboard extends StatelessWidget {
  final TextEditingController controller;
  final VoidCallback onSubmitted;
  final VoidCallback onClose; // 完了ボタン（閉じる）
  final ValueChanged<String> onChanged; // 値変更通知

  const CustomNumberKeyboard({
    super.key,
    required this.controller,
    required this.onSubmitted,
    required this.onClose,
    required this.onChanged,
  });

  // キー入力処理
  void _handleTap(String value) {
    final text = controller.text;
    final selection = controller.selection;

    int start = selection.start;
    int end = selection.end;

    if (start < 0) {
      start = text.length;
      end = text.length;
    }

    String newText = text.replaceRange(start, end, value);
    controller.value = TextEditingValue(
      text: newText,
      selection: TextSelection.collapsed(offset: start + value.length),
    );
    onChanged(newText);
  }

  void _handleDelete() {
    final text = controller.text;
    if (text.isEmpty) return;

    final selection = controller.selection;
    int start = selection.start;
    int end = selection.end;

    if (start < 0) {
      start = text.length;
      end = text.length;
    }

    if (start != end) {
      String newText = text.replaceRange(start, end, "");
      controller.value = TextEditingValue(
        text: newText,
        selection: TextSelection.collapsed(offset: start),
      );
      onChanged(newText);
      return;
    }

    if (start == 0) return;

    String newText = text.replaceRange(start - 1, start, "");
    controller.value = TextEditingValue(
      text: newText,
      selection: TextSelection.collapsed(offset: start - 1),
    );
    onChanged(newText);
  }

  void _handleClear() {
    controller.clear();
    onChanged("");
  }

  // 税計算 (8%, 10%)
  void _handleTax(double rate) {
    final currentText = controller.text;
    if (currentText.isEmpty) return;

    try {
      double? val = double.tryParse(currentText);
      if (val != null) {
        int result = (val * rate).floor();
        controller.text = result.toString();
        controller.selection = TextSelection.collapsed(
          offset: controller.text.length,
        );
        onChanged(controller.text);
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    // 背景色
    const Color bgColor = Color(0xFFF2F2F7);
    // ボタンの色
    const Color btnColor = Colors.white;
    // 影の色
    const Color shadowColor = Colors.black12;

    // キーのスタイル定義
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
              onTap: onTap ?? () => _handleTap(label),
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
      height: 320, // 固定高さ
      child: Column(
        children: [
          // ツールバー
          Container(
            height: 48,
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: Row(
              children: [
                const Icon(
                  Icons.calculate_outlined,
                  color: Colors.orange,
                  size: 28,
                ),
                const Spacer(),
                _buildToolButton("税込8%", () => _handleTax(1.08)),
                const SizedBox(width: 8),
                _buildToolButton("税込10%", () => _handleTax(1.10)),
                const SizedBox(width: 16),
                TextButton(
                  onPressed: onClose,
                  child: const Text(
                    "閉じる",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.orange,
                    ),
                  ),
                ),
              ],
            ),
          ),
          // キーパッドエリア
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(4, 0, 4, 4),
              child: Column(
                children: [
                  // Row 1
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
                  // Row 2
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
                  // Row 3 & 4
                  Expanded(
                    flex: 2,
                    child: Row(
                      children: [
                        // 左側の数字・演算ブロック (flex 4)
                        Expanded(
                          flex: 4,
                          child: Column(
                            children: [
                              // Row 3
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
                              // Row 4
                              Expanded(
                                child: Row(
                                  children: [
                                    buildKey("0"),
                                    buildKey("00"),
                                    const Expanded(child: SizedBox()),
                                    buildKey("+", textColor: Colors.black87),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        // 右端の「次へ」ボタン (flex 1)
                        Expanded(
                          flex: 1,
                          child: Padding(
                            padding: const EdgeInsets.all(4.0),
                            child: Material(
                              color: Colors.blue, // 青色で強調
                              elevation: 1,
                              borderRadius: BorderRadius.circular(8),
                              child: InkWell(
                                onTap: onSubmitted,
                                borderRadius: BorderRadius.circular(8),
                                child: Container(
                                  alignment: Alignment.center,
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: const [
                                      Icon(
                                        Icons.playlist_add,
                                        color: Colors.white,
                                        size: 28,
                                      ),
                                      SizedBox(height: 4),
                                      Text(
                                        "次へ",
                                        style: TextStyle(
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

  Widget _buildToolButton(String label, VoidCallback onTap) {
    return OutlinedButton(
      onPressed: onTap,
      style: OutlinedButton.styleFrom(
        foregroundColor: Colors.orange,
        side: const BorderSide(color: Colors.orange),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        visualDensity: VisualDensity.compact,
      ),
      child: Text(
        label,
        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
      ),
    );
  }
}
