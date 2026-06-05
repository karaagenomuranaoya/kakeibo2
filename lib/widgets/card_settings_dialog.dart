import 'package:flutter/material.dart';
import '../models/category_tag.dart';

class CardSettingsDialog extends StatefulWidget {
  final CategoryTag currentTag;
  final Function(int? closing, int? payment, int offset) onSave;

  const CardSettingsDialog({
    super.key,
    required this.currentTag,
    required this.onSave,
  });

  @override
  State<CardSettingsDialog> createState() => _CardSettingsDialogState();
}

class _CardSettingsDialogState extends State<CardSettingsDialog> {
  late bool isEnabled;
  late int closingDay;
  late int paymentDay;
  late int paymentOffset;

  @override
  void initState() {
    super.initState();
    isEnabled = widget.currentTag.closingDay != null;
    closingDay = widget.currentTag.closingDay ?? 99;
    paymentDay = widget.currentTag.paymentDay ?? 27;
    paymentOffset = widget.currentTag.paymentMonthOffset;
  }

  List<DropdownMenuItem<int>> _getDayItems() {
    final items = List.generate(
      28,
      (i) => i + 1,
    ).map((i) => DropdownMenuItem(value: i, child: Text('$i日'))).toList();
    items.add(const DropdownMenuItem(value: 99, child: Text('末日')));
    return items;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('カード設定'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Expanded(child: Text('締め日・支払日を管理する')),
                Switch(
                  value: isEnabled,
                  onChanged: (val) => setState(() => isEnabled = val),
                ),
              ],
            ),
            const SizedBox(height: 10),
            if (isEnabled) ...[
              const Text(
                '設定すると「引き落とし予定」タブが有効になります。',
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
              const SizedBox(height: 15),
              Row(
                children: [
                  const Text('締め: '),
                  DropdownButton<int>(
                    value: closingDay,
                    items: _getDayItems(),
                    onChanged: (val) => setState(() => closingDay = val!),
                  ),
                  const SizedBox(width: 15),
                  const Text('払い: '),
                  DropdownButton<int>(
                    value: paymentDay,
                    items: _getDayItems(),
                    onChanged: (val) => setState(() => paymentDay = val!),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  const Text('支払月: '),
                  DropdownButton<int>(
                    value: paymentOffset,
                    items: const [
                      DropdownMenuItem(value: 1, child: Text('翌月')),
                      DropdownMenuItem(value: 2, child: Text('翌々月')),
                    ],
                    onChanged: (val) => setState(() => paymentOffset = val!),
                  ),
                ],
              ),
            ] else ...[
              const Text(
                'PayPayやデビットカードなど、即時決済の場合はオフにしてください。',
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('キャンセル'),
        ),
        ElevatedButton(
          onPressed: () {
            widget.onSave(
              isEnabled ? closingDay : null,
              isEnabled ? paymentDay : null,
              paymentOffset,
            );
            Navigator.pop(context);
          },
          child: const Text('保存'),
        ),
      ],
    );
  }
}
