import 'package:flutter/widgets.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:uuid/uuid.dart';

import '../models/payment.dart';
import '../models/person.dart';
import '../models/record.dart';
import '../services/interest_calculator.dart';

class LocalDatabase {
  LocalDatabase._();
  static final LocalDatabase instance = LocalDatabase._();

  static const String _fileName = 'khata_local.db';
  static const int _version = 1;
  static const Uuid _uuid = Uuid();

  final ValueNotifier<int> revision = ValueNotifier<int>(0);

  Database? _db;
  Future<Database>? _opening;

  Future<Database> get database async {
    if (_db != null) return _db!;
    _opening ??= _open();
    _db = await _opening;
    return _db!;
  }

  Future<Database> _open() async {
    final path = join(await getDatabasesPath(), _fileName);
    return openDatabase(
      path,
      version: _version,
      onConfigure: (db) async {
        await db.execute('PRAGMA foreign_keys = ON');
      },
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE people (
            id TEXT PRIMARY KEY,
            name TEXT NOT NULL,
            phone TEXT NOT NULL DEFAULT '',
            createdAt TEXT NOT NULL
          )
        ''');
        await db.execute('''
          CREATE TABLE records (
            id TEXT PRIMARY KEY,
            personId TEXT NOT NULL,
            name TEXT NOT NULL,
            phone TEXT NOT NULL DEFAULT '',
            principal REAL NOT NULL,
            date TEXT NOT NULL,
            rate REAL NOT NULL DEFAULT 0,
            rateType TEXT NOT NULL DEFAULT 'month',
            interestMethod TEXT NOT NULL DEFAULT 'simple',
            hasInterest INTEGER NOT NULL DEFAULT 0,
            status TEXT NOT NULL DEFAULT 'unpaid',
            notes TEXT NOT NULL DEFAULT '',
            createdAt TEXT NOT NULL,
            FOREIGN KEY (personId) REFERENCES people (id) ON DELETE RESTRICT
          )
        ''');
        await db.execute('''
          CREATE TABLE payments (
            id TEXT PRIMARY KEY,
            recordId TEXT NOT NULL,
            amount REAL NOT NULL,
            date TEXT NOT NULL,
            FOREIGN KEY (recordId) REFERENCES records (id) ON DELETE CASCADE
          )
        ''');
        await db.execute('CREATE INDEX idx_records_person ON records (personId)');
        await db.execute('CREATE INDEX idx_payments_record ON payments (recordId)');
      },
    );
  }

  void _notify() => revision.value++;

  Future<List<Person>> getAllPeople() async {
    final db = await database;
    final rows = await db.query('people', orderBy: 'createdAt DESC');
    return rows.map(Person.fromMap).toList();
  }

  Future<Person?> getPerson(String id) async {
    final db = await database;
    final rows = await db.query('people', where: 'id = ?', whereArgs: [id]);
    return rows.isEmpty ? null : Person.fromMap(rows.first);
  }

  Future<String> insertPerson(Person person) async {
    final db = await database;
    final id = person.id.isEmpty ? _uuid.v4() : person.id;
    await db.insert('people', {...person.toMap(), 'id': id});
    _notify();
    return id;
  }

  Future<void> updatePerson(Person person) async {
    final db = await database;
    await db.transaction((txn) async {
      await txn.update(
        'people',
        {'name': person.name, 'phone': person.phone},
        where: 'id = ?',
        whereArgs: [person.id],
      );
      await txn.update(
        'records',
        {'name': person.name, 'phone': person.phone},
        where: 'personId = ?',
        whereArgs: [person.id],
      );
    });
    _notify();
  }

  Future<bool> personHasRecords(String personId) async {
    final db = await database;
    final rows = await db.rawQuery(
        'SELECT COUNT(*) AS c FROM records WHERE personId = ?', [personId]);
    return (rows.first['c'] as int) > 0;
  }

  Future<void> deletePerson(String personId) async {
    if (await personHasRecords(personId)) {
      throw StateError('Cannot delete a person with existing records.');
    }
    final db = await database;
    await db.delete('people', where: 'id = ?', whereArgs: [personId]);
    _notify();
  }

  Future<Person> ensurePerson({
    required String name,
    required String phone,
    String? preferredPersonId,
  }) async {
    final cleanName = name.trim();
    final cleanPhone = phone.trim();
    final people = await getAllPeople();
    Person? existing;
    if (preferredPersonId != null && preferredPersonId.isNotEmpty) {
      for (final candidate in people) {
        if (candidate.id == preferredPersonId) {
          existing = candidate;
          break;
        }
      }
    }
    if (existing == null) {
      for (final candidate in people) {
        if (candidate.name.trim().toLowerCase() == cleanName.toLowerCase()) {
          existing = candidate;
          break;
        }
      }
    }
    if (existing == null) {
      final created = Person(
        name: cleanName,
        phone: cleanPhone,
        createdAt: DateTime.now(),
      );
      final id = await insertPerson(created);
      return Person(
        id: id,
        name: created.name,
        phone: created.phone,
        createdAt: created.createdAt,
      );
    }
    final updated = Person(
      id: existing.id,
      name: cleanName,
      phone: cleanPhone,
      createdAt: existing.createdAt,
    );
    if (existing.name != updated.name || existing.phone != updated.phone) {
      await updatePerson(updated);
    }
    return updated;
  }

  Future<List<Record>> getAllRecords() async {
    final db = await database;
    final rows =
        await db.query('records', orderBy: 'createdAt DESC, rowid DESC');
    return rows.map(Record.fromMap).toList();
  }

  Future<Record?> getRecord(String id) async {
    final db = await database;
    final rows = await db.query('records', where: 'id = ?', whereArgs: [id]);
    return rows.isEmpty ? null : Record.fromMap(rows.first);
  }

  Future<String> insertRecord(Record record) async {
    final db = await database;
    final id = record.id.isEmpty ? _uuid.v4() : record.id;
    await db.insert('records', {...record.toMap(), 'id': id});
    _notify();
    return id;
  }

  Future<void> updateRecord(Record record) async {
    final db = await database;
    await db.update(
      'records',
      record.toMap(),
      where: 'id = ?',
      whereArgs: [record.id],
    );
    _notify();
  }

  Future<void> deleteRecord(String id) async {
    final db = await database;
    await db.transaction((txn) async {
      await txn.delete('payments', where: 'recordId = ?', whereArgs: [id]);
      await txn.delete('records', where: 'id = ?', whereArgs: [id]);
    });
    _notify();
  }

  Future<List<Payment>> getPayments(String recordId) async {
    final db = await database;
    final rows = await db.query(
      'payments',
      where: 'recordId = ?',
      whereArgs: [recordId],
      orderBy: 'date ASC, rowid ASC',
    );
    return rows.map(Payment.fromMap).toList();
  }

  Future<String> insertPayment(Payment payment) async {
    final db = await database;
    final id = payment.id.isEmpty ? _uuid.v4() : payment.id;
    await db.insert('payments', {...payment.toMap(), 'id': id});
    _notify();
    return id;
  }

  Future<void> deletePayment(String id) async {
    final db = await database;
    await db.delete('payments', where: 'id = ?', whereArgs: [id]);
    _notify();
  }

  Future<void> refreshStatus(String recordId) async {
    final db = await database;
    final record = await getRecord(recordId);
    if (record == null) return;
    final sumRows = await db.rawQuery(
        'SELECT COALESCE(SUM(amount), 0) AS total FROM payments WHERE recordId = ?',
        [recordId]);
    final paid = (sumRows.first['total'] as num).toDouble();
    String status;
    if (record.principal - paid <= 0.005) {
      status = RecordStatus.paid;
    } else if (paid > 0) {
      status = RecordStatus.half;
    } else {
      status = RecordStatus.unpaid;
    }
    await db.update(
      'records',
      {'status': status},
      where: 'id = ?',
      whereArgs: [recordId],
    );
    _notify();
  }

  Future<List<(Record, List<Payment>)>> getRecordsWithPayments(
      {String? personId}) async {
    final db = await database;
    final recordRows = await db.query(
      'records',
      where: personId == null ? null : 'personId = ?',
      whereArgs: personId == null ? null : [personId],
      orderBy: 'createdAt DESC, rowid DESC',
    );
    final paymentRows =
        await db.query('payments', orderBy: 'date ASC, rowid ASC');
    final byRecord = <String, List<Payment>>{};
    for (final row in paymentRows) {
      final payment = Payment.fromMap(row);
      byRecord.putIfAbsent(payment.recordId, () => <Payment>[]).add(payment);
    }
    final result = <(Record, List<Payment>)>[];
    for (final row in recordRows) {
      final record = Record.fromMap(row);
      result.add((record, byRecord[record.id] ?? const <Payment>[]));
    }
    return result;
  }

  Future<List<(Person, double)>> getPeopleWithBalances() async {
    final people = await getAllPeople();
    final entries = await getRecordsWithPayments();
    final totals = <String, double>{};
    for (final (record, payments) in entries) {
      totals[record.personId] = (totals[record.personId] ?? 0) +
          InterestCalculator.calculate(record, payments).totalDue;
    }
    return [for (final person in people) (person, totals[person.id] ?? 0)];
  }
}

mixin DataListener<T extends StatefulWidget> on State<T> {
  void onDataChanged();

  void _handleRevision() {
    if (mounted) onDataChanged();
  }

  @override
  void initState() {
    super.initState();
    LocalDatabase.instance.revision.addListener(_handleRevision);
  }

  @override
  void dispose() {
    LocalDatabase.instance.revision.removeListener(_handleRevision);
    super.dispose();
  }
}
