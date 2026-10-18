import 'package:flutter/material.dart';

import '../db/local_database.dart';
import '../l10n/app_strings.dart';
import '../models/person.dart';
import '../services/app_colors.dart';
import '../services/format_service.dart';
import '../services/settings.dart';
import '../widgets/person_editor_dialog.dart';
import 'add_edit_screen.dart';
import 'person_detail_screen.dart';

class PeopleScreen extends StatefulWidget {
  const PeopleScreen({super.key});

  @override
  State<PeopleScreen> createState() => _PeopleScreenState();
}

class _PeopleScreenState extends State<PeopleScreen>
    with SettingsListener<PeopleScreen>, DataListener<PeopleScreen> {
  final _db = LocalDatabase.instance;
  late Future<List<(Person, double)>> _peopleFuture;

  @override
  void initState() {
    super.initState();
    _peopleFuture = _db.getPeopleWithBalances();
  }

  @override
  void onDataChanged() {
    setState(() => _peopleFuture = _db.getPeopleWithBalances());
  }

  Future<void> _editPerson([Person? person]) async {
    final edited = await showPersonEditorDialog(context, person: person);
    if (!mounted || edited == null) return;
    if (person == null) {
      await _db.insertPerson(edited);
    } else {
      await _db.updatePerson(edited);
    }
  }

  Future<void> _deletePerson(Person person) async {
    if (await _db.personHasRecords(person.id)) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(tr('personHasRecords'))),
      );
      return;
    }
    if (!mounted) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(tr('deletePersonTitle')),
        content: Text(tr('deletePersonMessage')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(tr('cancel')),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(tr('delete')),
          ),
        ],
      ),
    );
    if (!mounted || confirmed != true) return;
    try {
      await _db.deletePerson(person.id);
    } on StateError {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(tr('personHasRecords'))),
      );
    }
  }

  Future<void> _addRecord(Person person) async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => AddEditScreen(initialPerson: person)),
    );
    if (mounted) onDataChanged();
  }

  Future<void> _openPerson(Person person) async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => PersonDetailScreen(person: person)),
    );
    if (mounted) onDataChanged();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title:
            Text(tr('peopleTab'), maxLines: 1, overflow: TextOverflow.ellipsis),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _editPerson,
        tooltip: tr('addPerson'),
        child: const Icon(Icons.person_add_alt_1),
      ),
      body: FutureBuilder<List<(Person, double)>>(
        future: _peopleFuture,
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            if (snapshot.hasError) {
              return Center(child: Text(tr('error')));
            }
            return const Center(child: CircularProgressIndicator());
          }
          final people = snapshot.data!;
          if (people.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Text(
                  tr('peopleEmpty'),
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                      fontSize: 17, color: AppColors.onSurfaceVariant),
                ),
              ),
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 96),
            itemCount: people.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final (person, outstanding) = people[index];
              return Card(
                child: ListTile(
                  leading: const CircleAvatar(
                    backgroundColor: AppColors.primaryContainer,
                    child: Icon(Icons.person_outline, color: AppColors.primary),
                  ),
                  title: Text(person.name,
                      maxLines: 1, overflow: TextOverflow.ellipsis),
                  subtitle: Text(
                    [
                      if (person.phone.isNotEmpty) person.phone,
                      '${tr('totalOutstanding')}: ${Fmt.money(outstanding)}',
                    ].join('\n'),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  onTap: () => _openPerson(person),
                  trailing: PopupMenuButton<String>(
                    onSelected: (action) {
                      if (action == 'record') _addRecord(person);
                      if (action == 'edit') _editPerson(person);
                      if (action == 'delete') _deletePerson(person);
                    },
                    itemBuilder: (context) => [
                      PopupMenuItem(
                          value: 'record', child: Text(tr('addRecord'))),
                      PopupMenuItem(value: 'edit', child: Text(tr('edit'))),
                      PopupMenuItem(value: 'delete', child: Text(tr('delete'))),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
