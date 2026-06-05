// ▼▼ このファイルが「lib/widgets/」の中に存在するか確認してください ▼▼
import 'package:flutter/material.dart';
import '../models/transaction_item.dart';
import '../repositories/transaction_repository.dart';

class TransactionEditDialog extends StatefulWidget {
  final TransactionItem item;
  final VoidCallback onSuccess;

  const TransactionEditDialog({
    super.key,
    required this.item,
    required this.onSuccess,
  });

  @override
  State<TransactionEditDialog> createState() => _TransactionEditDialogState();
}

class _TransactionEditDialogState extends State<TransactionEditDialog> {
  final TransactionRepository _repository = TransactionRepository();
  late TextEditingController _amountController;
  late TextEditingController _memoController;

  @override
  void initState() {
    super.initState();
    _amountController = TextEditingController(
      text: widget.item.amount.toString(),
    );
    _memoController = TextEditingController(text: widget.item.memo);
  }

  @override
  void dispose() {
    _amountController.dispose();
    _memoController.dispose();
    super.dispose();
  }

  Future<void> _update() async {
    final newAmount = int.tryParse(_amountController.text);
    if (newAmount != null) {
      final newItem = widget.item.copyWith(
        amount: newAmount,
        memo: _memoController.text.trim(),
      );
      await _repository.updateTransaction(newItem);
      if (mounted) {
        Navigator.pop(context);
        widget.onSuccess();
      }
    }
  }

  Future<void> _delete() async {
    await _repository.deleteTransaction(widget.item.id);
    if (mounted) {
      Navigator.pop(context);
      widget.onSuccess();
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('履歴の編集'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _amountController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: '金額'),
              autofocus: true,
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _memoController,
              decoration: const InputDecoration(labelText: 'メモ'),
            ),
            const SizedBox(height: 20),
            Text(
              '利用日: ${widget.item.date.year}/${widget.item.date.month}/${widget.item.date.day}',
              style: const TextStyle(color: Colors.grey, fontSize: 12),
            ),
            if (widget.item.paymentDate != null)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  '支払日: ${widget.item.paymentDate!.year}/${widget.item.paymentDate!.month}/${widget.item.paymentDate!.day}',
                  style: const TextStyle(
                    color: Colors.orange,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _delete,
          style: TextButton.styleFrom(foregroundColor: Colors.red),
          child: const Text('削除'),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('キャンセル'),
        ),
        ElevatedButton(onPressed: _update, child: const Text('更新')),
      ],
    );
  }
}
