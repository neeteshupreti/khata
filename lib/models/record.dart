class RecordStatus {
  static const String unpaid = 'unpaid';
  static const String half = 'half';
  static const String paid = 'paid';
}

class Record {
  final String id;
  final String personId;
  final String name;
  final String phone;
  final double principal;
  final DateTime date;
  final double rate;
  final String rateType;
  final String interestMethod;
  final bool hasInterest;
  final String status;
  final String notes;
  final DateTime createdAt;

  const Record({
    this.id = '',
    this.personId = '',
    required this.name,
    this.phone = '',
    required this.principal,
    required this.date,
    this.rate = 0,
    this.rateType = 'month',
    this.interestMethod = 'simple',
    this.hasInterest = false,
    this.status = RecordStatus.unpaid,
    this.notes = '',
    required this.createdAt,
  });

  Record copyWith({
    String? id,
    String? personId,
    String? name,
    String? phone,
  }) =>
      Record(
        id: id ?? this.id,
        personId: personId ?? this.personId,
        name: name ?? this.name,
        phone: phone ?? this.phone,
        principal: principal,
        date: date,
        rate: rate,
        rateType: rateType,
        interestMethod: interestMethod,
        hasInterest: hasInterest,
        status: status,
        notes: notes,
        createdAt: createdAt,
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'personId': personId,
        'name': name,
        'phone': phone,
        'principal': principal,
        'date': date.toIso8601String(),
        'rate': rate,
        'rateType': rateType,
        'interestMethod': interestMethod,
        'hasInterest': hasInterest ? 1 : 0,
        'status': status,
        'notes': notes,
        'createdAt': createdAt.toIso8601String(),
      };

  factory Record.fromMap(Map<String, dynamic> m) => Record(
        id: m['id'] as String,
        personId: m['personId'] as String,
        name: m['name'] as String,
        phone: (m['phone'] as String?) ?? '',
        principal: (m['principal'] as num).toDouble(),
        date: DateTime.parse(m['date'] as String),
        rate: (m['rate'] as num).toDouble(),
        rateType: m['rateType'] as String,
        interestMethod: m['interestMethod'] as String,
        hasInterest: (m['hasInterest'] as int) == 1,
        status: m['status'] as String,
        notes: (m['notes'] as String?) ?? '',
        createdAt: DateTime.parse(m['createdAt'] as String),
      );
}
