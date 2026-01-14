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

    // 選択範囲がある場合は置換、なければカーソル位置に挿入
    // ただしreadOnlyのTextFieldだとカーソル位置が常に-1や不正になることがあるため、
    // 基本は末尾追加、カーソルがある場合のみ位置考慮とする

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

    // 範囲選択されている場合は範囲削除
    if (start != end) {
      String newText = text.replaceRange(start, end, "");
      controller.value = TextEditingValue(
        text: newText,
        selection: TextSelection.collapsed(offset: start),
      );
      onChanged(newText);
      return;
    }

    // カーソルが先頭にある場合は何もしない
    if (start == 0) return;

    // 1文字削除
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
    // まず現在の式を計算してから掛け算する
    final currentText = controller.text;
    if (currentText.isEmpty) return;

    // 簡易計算ロジックをここで呼ぶのは依存関係が複雑になるため、
    // UI側で「計算してから」この関数を呼ぶ設計も考えられるが、
    // ここでは単純に「文字列として計算可能な場合のみ」処理する
    try {
      // 簡易的な評価（utilsのCalculatorを利用する前提だが、import循環を避けるため簡易実装）
      // 実際にはInputTab側でCalculatorを使ってからセットされることが多いが、
      // ここでは「現在の入力値が単一の数値なら」掛け算する
      double? val = double.tryParse(currentText);
      if (val != null) {
        int result = (val * rate).floor();
        controller.text = result.toString();
        // カーソル末尾
        controller.selection =
            TextSelection.collapsed(offset: controller.text.length);
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
    Widget buildKey(String label,
        {Color textColor = Colors.black,
        Color? color,
        int flex = 1,
        VoidCallback? onTap,
        bool isBold = true}) {
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

    Widget buildFunctionKey(String label, VoidCallback onTap,
        {Color textColor = Colors.black}) {
      return buildKey(label, onTap: onTap, textColor: textColor, isBold: true);
    }

    return Container(
      color: bgColor,
      width: double.infinity,
      height: 320, // 固定高さ
      child: Column(
        children: [
          // ツールバー (電卓アイコン, 税ボタン, 完了)
          Container(
            height: 48,
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: Row(
              children: [
                const Icon(Icons.calculate_outlined,
                    color: Colors.orange, size: 28),
                const Spacer(),
                _buildToolButton("税込8%", () => _handleTax(1.08)),
                const SizedBox(width: 8),
                _buildToolButton("税込10%", () => _handleTax(1.10)),
                const SizedBox(width: 16),
                TextButton(
                  onPressed: onClose,
                  child: const Text(
                    "完了",
                    style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.orange),
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
                  // Row 1: 7, 8, 9, ÷, AC
                  Expanded(
                    child: Row(
                      children: [
                        buildKey("7"),
                        buildKey("8"),
                        buildKey("9"),
                        buildKey("÷", textColor: Colors.black87),
                        buildFunctionKey("AC", _handleClear,
                            textColor: Colors.black54),
                      ],
                    ),
                  ),
                  // Row 2: 4, 5, 6, x, Del
                  Expanded(
                    child: Row(
                      children: [
                        buildKey("4"),
                        buildKey("5"),
                        buildKey("6"),
                        buildKey("x", textColor: Colors.black87),
                        buildFunctionKey("Del", _handleDelete,
                            textColor: Colors.deepOrange),
                      ],
                    ),
                  ),
                  // Row 3 & 4 (OKボタンが縦結合に見えるレイアウトへの対応)
                  // FlutterのRow/Columnで縦結合は難しいので、
                  // [1,2,3,-] と [0,00,+] の列と、右側の [OK] 列に分けるか、
                  // あるいは単純なグリッドにする。
                  // 画像の「OK」は右下で大きい。
                  // ここでは Row 3 と Row 4 を作って、右端の扱いは工夫する。
                  Expanded(
                    flex: 2,
                    child: Row(
                      children: [
                        // 左側の数字・演算ブロック (flex 4)
                        Expanded(
                          flex: 4,
                          child: Column(
                            children: [
                              // Row 3: 1, 2, 3, -
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
                              // Row 4: 0, 00, ., + (画像では.がないが、0と00のスペース的に空きがあるかも？)
                              // 画像: [0] [00] [ ] [+] ...
                              // ここでは [0] [00] [ ] [+] として実装
                              Expanded(
                                child: Row(
                                  children: [
                                    buildKey("0"),
                                    buildKey("00"),
                                    // 空白の代わりにドットを入れるか、空白にするか。
                                    // 家計簿なので小数はあまり使わないかもしれないが、計算には必要かも。
                                    // 画像準拠なら空白だが、機能性を取って空白スペースにする
                                    const Expanded(child: SizedBox()),
                                    buildKey("+", textColor: Colors.black87),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        // 右端のOKボタン (flex 1)
                        Expanded(
                          flex: 1,
                          child: Padding(
                            padding: const EdgeInsets.all(4.0),
                            child: Material(
                              color: Colors.white,
                              elevation: 1,
                              borderRadius: BorderRadius.circular(8),
                              child: InkWell(
                                onTap: onSubmitted,
                                borderRadius: BorderRadius.circular(8),
                                child: Container(
                                  alignment: Alignment.center,
                                  child: const Text(
                                    "OK",
                                    style: TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.blue,
                                    ),
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
      child: Text(label,
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
    );
  }
}
