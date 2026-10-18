class Payment {
  final String id;
  final String recordId;
  final double amount;
  final DateTime date;

  const Payment({
    this.id = '',
    required this.recordId,
    required this.amount,
    required this.date,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'recordId': recordId,
        'amount': amount,
        'date': date.toIso8601String(),
      };

  factory Payment.fromMap(Map<String, dynamic> m) => Payment(
        id: m['id'] as String,
        recordId: m['recordId'] as String,
        amount: (m['amount'] as num).toDouble(),
        date: DateTime.parse(m['date'] as String),
      );
}
