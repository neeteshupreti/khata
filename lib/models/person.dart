class Person {
  final String id;
  final String name;
  final String phone;
  final DateTime createdAt;

  const Person({
    this.id = '',
    required this.name,
    this.phone = '',
    required this.createdAt,
  });

  factory Person.fromMap(Map<String, dynamic> map) => Person(
        id: map['id'] as String,
        name: map['name'] as String,
        phone: (map['phone'] as String?) ?? '',
        createdAt: DateTime.parse(map['createdAt'] as String),
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'phone': phone,
        'createdAt': createdAt.toIso8601String(),
      };
}
