import 'package:flutter/material.dart';

import '../db/local_database.dart';
import '../l10n/app_strings.dart';
import '../models/payment.dart';
import '../models/person.dart';
import '../models/record.dart';
import '../services/app_colors.dart';
import '../services/format_service.dart';
import '../services/interest_calculator.dart';
import '../services/settings.dart';
import '../widgets/person_editor_dialog.dart';
import '../widgets/record_tile.dart';
import 'add_edit_screen.dart';
import 'detail_screen.dart';

class PersonDetailScreen extends StatefulWidget {
  final Person person;

  const PersonDetailScreen({super.key, required this.person});

  @override
  State<PersonDetailScreen> createState() => _PersonDetailScreenState();
}

class _PersonDetailData {
  final Person? person;
  final List<(Record, List<Payment>)> entries;
  const _PersonDetailData(this.person, this.entries);
}

class _PersonDetailScreenState extends State<PersonDetailScreen>
    with SettingsListener<PersonDetailScreen>, DataListener<PersonDetailScreen> {
  final _db = LocalDatabase.instance;
  late Future<_PersonDetailData> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  @override
  void onDataChanged() {
    setState(() => _future = _load());
  }

  Future<_PersonDetailData> _load() async {
    final person = await _db.getPerson(widget.person.id);
    if (person == null) return const _PersonDetailData(null, []);
    final entries = await _db.getRecordsWithPayments(personId: person.id);
    return _PersonDetailData(person, entries);
  }

  Future<void> _editPerson(Person person) async {
    final updated = await showPersonEditorDialog(context, person: person);
    if (!mounted || updated == null) return;
    await _db.updatePerson(updated);
    if (mounted) onDataChanged();
  }

  Future<void> _addRecord(Person person) async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => AddEditScreen(initialPerson: person)),
    );
    if (mounted) onDataChanged();
  }

  Future<void> _openRecord(Record record) async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => DetailScreen(recordId: record.id)),
    );
    if (mounted) onDataChanged();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<_PersonDetailData>(
      future: _future,
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return Scaffold(
            appBar: AppBar(),
            body: snapshot.hasError
                ? Center(child: Text(tr('error')))
                : const Center(child: CircularProgressIndicator()),
          );
        }
        final data = snapshot.data!;
        final person = data.person;
        if (person == null) {
          return Scaffold(
            appBar: AppBar(),
            body: Center(child: Text(tr('notFound'))),
          );
        }
        return _buildDetails(person, data.entries);
      },
    );
  }

  Widget _buildDetails(Person person, List<(Record, List<Payment>)> records) {
    var given = 0.0;
    var accruedInterest = 0.0;
    var paid = 0.0;
    var outstanding = 0.0;
    for (final (record, payments) in records) {
      final result = InterestCalculator.calculate(record, payments);
      given += record.principal;
      accruedInterest += result.interest;
      paid += result.paidPrincipal;
      outstanding += result.totalDue;
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(person.name, maxLines: 1, overflow: TextOverflow.ellipsis),
        actions: [
          IconButton(
            tooltip: tr('editPerson'),
            onPressed: () => _editPerson(person),
            icon: const Icon(Icons.edit_outlined),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _addRecord(person),
        icon: const Icon(Icons.add),
        label: Text(tr('addRecord')),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 104),
        children: [
          _PersonSummaryCard(
            person: person,
            given: given,
            interest: accruedInterest,
            paid: paid,
            outstanding: outstanding,
          ),
          const SizedBox(height: 24),
          Text(
            tr('personRecords'),
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 12),
          if (records.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 28),
              child: Text(
                tr('noPersonRecords'),
                textAlign: TextAlign.center,
                style: const TextStyle(
                    color: AppColors.onSurfaceVariant, fontSize: 16),
              ),
            )
          else
            ...records.map(
              (entry) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: RecordTile(
                  record: entry.$1,
                  onTap: () => _openRecord(entry.$1),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _PersonSummaryCard extends StatelessWidget {
  final Person person;
  final double given;
  final double interest;
  final double paid;
  final double outstanding;

  const _PersonSummaryCard({
    required this.person,
    required this.given,
    required this.interest,
    required this.paid,
    required this.outstanding,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: AppColors.surface,
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(person.name,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style:
                    const TextStyle(fontSize: 24, fontWeight: FontWeight.w700)),
            if (person.phone.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(person.phone,
                  style: const TextStyle(color: AppColors.onSurfaceVariant)),
            ],
            const SizedBox(height: 16),
            _SummaryValue(label: tr('totalGiven'), value: given),
            _SummaryValue(label: tr('totalInterest'), value: interest),
            _SummaryValue(label: tr('totalPaid'), value: paid),
            const Divider(height: 20),
            _SummaryValue(
              label: tr('totalOutstanding'),
              value: outstanding,
              emphasize: true,
            ),
          ],
        ),
      ),
    );
  }
}

class _SummaryValue extends StatelessWidget {
  final String label;
  final double value;
  final bool emphasize;

  const _SummaryValue({
    required this.label,
    required this.value,
    this.emphasize = false,
  });

  @override
  Widget build(BuildContext context) {
    final style = TextStyle(
      color: emphasize ? AppColors.primary : AppColors.onSurface,
      fontWeight: emphasize ? FontWeight.w700 : FontWeight.w500,
      fontSize: emphasize ? 17 : 15,
    );
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          Expanded(child: Text(label, style: style)),
          const SizedBox(width: 12),
          Text(Fmt.money(value), style: style),
        ],
      ),
    );
  }
}
