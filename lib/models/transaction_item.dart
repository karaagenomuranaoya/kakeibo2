class TransactionItem {
  final String id;
  final int amount;
  final String expense;
  final String payment;
  final DateTime date;

  // 支払日（クレジットカードの引き落とし日など）
  // nullの場合は date と同じ（即時払い）とみなす
  final DateTime? paymentDate;

  TransactionItem({
    String? id,
    required this.amount,
    required this.expense,
    required this.payment,
    required this.date,
    this.paymentDate,
  }) : id = id ?? DateTime.now().microsecondsSinceEpoch.toString();

  String get displayDate {
    return "${date.month}/${date.day} ${date.hour}:${date.minute.toString().padLeft(2, '0')}";
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'amount': amount,
      'expense': expense,
      'payment': payment,
      'date_iso': date.toIso8601String(),
      'payment_date_iso': paymentDate?.toIso8601String(),
    };
  }

  factory TransactionItem.fromJson(Map<String, dynamic> json) {
    return TransactionItem(
      id: json['id'] as String? ??
          DateTime.now().microsecondsSinceEpoch.toString() +
              (json['date_iso'] as String),
      amount: json['amount'] as int,
      expense: json['expense'] as String,
      payment: json['payment'] as String,
      date: DateTime.parse(json['date_iso'] as String),
      paymentDate: json['payment_date_iso'] != null
          ? DateTime.parse(json['payment_date_iso'] as String)
          : null,
    );
  }

  TransactionItem copyWith({
    int? amount,
    String? expense,
    String? payment,
    DateTime? date,
    DateTime? paymentDate,
  }) {
    return TransactionItem(
      id: id,
      amount: amount ?? this.amount,
      expense: expense ?? this.expense,
      payment: payment ?? this.payment,
      date: date ?? this.date,
      paymentDate: paymentDate ?? this.paymentDate,
    );
  }
}
