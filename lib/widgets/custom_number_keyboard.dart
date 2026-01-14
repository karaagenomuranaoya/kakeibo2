import 'package:flutter/material.dart';

class CustomNumberKeyboard extends StatelessWidget {
  final TextEditingController controller;
  final VoidCallback onSubmitted;
  final VoidCallback onClose; // 復活: 閉じるボタン用
  final ValueChanged<String> onChanged;

  const CustomNumberKeyboard({
    super.key,
    required this.controller,
    required this.onSubmitted,
    required this.onClose,
    required this.onChanged,
  });

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

  @override
  Widget build(BuildContext context) {
    const Color bgColor = Color(0xFFF2F2F7);
    const Color btnColor = Colors.white;
    const Color shadowColor = Colors.black12;

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
      child: Column(
        children: [
          // ▼▼ 右上の閉じるボタンエリア ▼▼
          SizedBox(
            height: 40,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                IconButton(
                  onPressed: onClose,
                  icon: const Icon(Icons.keyboard_hide, color: Colors.grey),
                  tooltip: '閉じる',
                ),
                const SizedBox(width: 8),
              ],
            ),
          ),
          // ▼▼ キーボードエリア ▼▼
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
                        Expanded(
                          flex: 1,
                          child: Padding(
                            padding: const EdgeInsets.all(4.0),
                            child: Material(
                              color: Colors.blue,
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
}
