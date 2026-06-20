class TransactionItem {
  final String id;
  final int amount;
  final String expense;
  final String? expenseId; // カテゴリID
  final String payment;
  final String? paymentId; // 支払い方法ID
  final DateTime date;
  final DateTime? paymentDate;
  final String memo;

  TransactionItem({
    String? id,
    required this.amount,
    required this.expense,
    this.expenseId,
    required this.payment,
    this.paymentId,
    required this.date,
    this.paymentDate,
    this.memo = '',
  }) : id = id ?? DateTime.now().microsecondsSinceEpoch.toString();

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'amount': amount,
      'expense': expense,
      'expense_id': expenseId,
      'payment': payment,
      'payment_id': paymentId,
      'date_iso': date.toIso8601String(),
      'payment_date_iso': paymentDate?.toIso8601String(),
      'memo': memo,
    };
  }

  factory TransactionItem.fromJson(Map<String, dynamic> json) {
    return TransactionItem(
      // ▼▼ 修正: IDの再生成を防ぐ。IDがない場合は date_iso をベースに生成 ▼▼
      // 同じデータを複数回JSONデコードしても同じIDが生成されるようにする
      id:
          json['id'] as String? ??
          // フォールバック: date_iso はユニークなので、これをIDの一部に使用
          "legacy_${json['date_iso']}",
      amount: json['amount'] as int,
      expense: json['expense'] as String,
      expenseId: json['expense_id'] as String?,
      payment: json['payment'] as String,
      paymentId: json['payment_id'] as String?,
      date: DateTime.parse(json['date_iso'] as String),
      paymentDate: json['payment_date_iso'] != null
          ? DateTime.parse(json['payment_date_iso'] as String)
          : null,
      memo: json['memo'] as String? ?? '',
    );
  }

  TransactionItem copyWith({
    String? id, // IDもcopyできるようにしておくと編集時に便利です
    int? amount,
    String? expense,
    String? expenseId,
    String? payment,
    String? paymentId,
    DateTime? date,
    DateTime? paymentDate,
    String? memo,
  }) {
    return TransactionItem(
      id: id ?? this.id,
      amount: amount ?? this.amount,
      expense: expense ?? this.expense,
      expenseId: expenseId ?? this.expenseId,
      payment: payment ?? this.payment,
      paymentId: paymentId ?? this.paymentId,
      date: date ?? this.date,
      paymentDate: paymentDate ?? this.paymentDate,
      memo: memo ?? this.memo,
    );
  }
}

//copywithを利用して、カテゴリや支払いの編集もできるようにしよう。
