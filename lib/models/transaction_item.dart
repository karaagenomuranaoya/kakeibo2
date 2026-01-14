class TransactionItem {
  final String id; // データを識別するためのIDを追加
  final int amount;
  final String expense;
  final String payment;
  final DateTime date;

  TransactionItem({
    String? id,
    required this.amount,
    required this.expense,
    required this.payment,
    required this.date,
  }) : id = id ??
            DateTime.now().microsecondsSinceEpoch.toString(); // IDがなければ現在時刻から生成

  // 表示用日付フォーマット
  String get displayDate {
    return "${date.month}/${date.day} ${date.hour}:${date.minute.toString().padLeft(2, '0')}";
  }

  // JSON保存用: Mapに変換
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'amount': amount,
      'expense': expense,
      'payment': payment,
      'date_iso': date.toIso8601String(),
    };
  }

  // 読み込み用: Mapから生成
  factory TransactionItem.fromJson(Map<String, dynamic> json) {
    return TransactionItem(
      // 古いデータにはidがない場合があるので、その場合は読み込み時に付与する
      id: json['id'] as String? ??
          DateTime.now().microsecondsSinceEpoch.toString() +
              (json['date_iso'] as String),
      amount: json['amount'] as int,
      expense: json['expense'] as String,
      payment: json['payment'] as String,
      date: DateTime.parse(json['date_iso'] as String),
    );
  }

  // 編集用: 内容をコピーして新しいインスタンスを作る
  TransactionItem copyWith({
    int? amount,
    String? expense,
    String? payment,
    DateTime? date,
  }) {
    return TransactionItem(
      id: id, // IDは維持
      amount: amount ?? this.amount,
      expense: expense ?? this.expense,
      payment: payment ?? this.payment,
      date: date ?? this.date,
    );
  }
}
