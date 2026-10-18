import 'package:flutter/material.dart';

import '../db/local_database.dart';
import '../l10n/app_strings.dart';
import '../models/person.dart';
import '../models/record.dart';
import '../services/app_colors.dart';
import '../services/date_service.dart';
import '../services/settings.dart';
import '../widgets/bs_date_picker.dart';
import '../widgets/calendar_toggle.dart';

class AddEditScreen extends StatefulWidget {
  final Record? record;
  final Person? initialPerson;
  const AddEditScreen({super.key, this.record, this.initialPerson});

  @override
  State<AddEditScreen> createState() => _AddEditScreenState();
}

class _AddEditScreenState extends State<AddEditScreen>
    with SettingsListener<AddEditScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _amountCtrl = TextEditingController();
  final _rateCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();

  DateTime _date = DateService.dateOnly(DateTime.now());
  bool _hasInterest = false;
  String _rateType = 'month';
  String _method = 'simple';
  Person? _selectedPerson;
  late final Future<List<Person>> _peopleFuture;

  bool get _isEdit => widget.record != null;

  @override
  void initState() {
    super.initState();
    _peopleFuture = LocalDatabase.instance.getAllPeople();
    final r = widget.record;
    _selectedPerson = widget.initialPerson;
    if (r != null) {

      _nameCtrl.text = r.name;
      _phoneCtrl.text = r.phone;
      _amountCtrl.text = _plain(r.principal);
      _notesCtrl.text = r.notes;
      _date = DateService.dateOnly(r.date);
      _hasInterest = r.hasInterest;
      if (r.hasInterest) {
        _rateCtrl.text = _plain(r.rate);
        _rateType = r.rateType;
        _method = r.interestMethod;
      }
    } else if (_selectedPerson != null) {
      _nameCtrl.text = _selectedPerson!.name;
      _phoneCtrl.text = _selectedPerson!.phone;
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _amountCtrl.dispose();
    _rateCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  String _plain(double v) =>
      v == v.roundToDouble() ? v.toStringAsFixed(0) : v.toString();

  double? _parse(String? s) =>
      double.tryParse((s ?? '').replaceAll(',', '').trim());

  Future<void> _pickDate() async {
    DateTime? picked;
    if (Settings.useBs.value) {
      picked = await showBsDatePicker(context, _date);
    } else {
      picked = await showDatePicker(
        context: context,
        initialDate: _date,
        firstDate: DateTime(1950),
        lastDate: DateTime(2100),
      );
    }
    if (!mounted) return;
    if (picked != null) setState(() => _date = DateService.dateOnly(picked!));
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final old = widget.record;
    final db = LocalDatabase.instance;
    final person = await db.ensurePerson(
      name: _nameCtrl.text,
      phone: _phoneCtrl.text,
      preferredPersonId: _selectedPerson?.id ?? old?.personId,
    );

    final rec = Record(
      id: old?.id ?? '',
      personId: person.id,
      name: _nameCtrl.text.trim(),
      phone: _phoneCtrl.text.trim(),
      principal: _parse(_amountCtrl.text)!,
      date: _date,
      rate: _hasInterest ? _parse(_rateCtrl.text)! : 0,
      rateType: _rateType,
      interestMethod: _method,
      hasInterest: _hasInterest,
      status: old?.status ?? RecordStatus.unpaid,
      notes: _notesCtrl.text.trim(),
      createdAt: old?.createdAt ?? DateTime.now(),
    );

    if (old == null) {
      await db.insertRecord(rec);
    } else {
      await db.updateRecord(rec);

      await db.refreshStatus(old.id);
    }

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        backgroundColor: AppColors.primary,
        behavior: SnackBarBehavior.floating,
        content: Text(tr('saved'))));
    Navigator.of(context).pop(true);
  }

  Widget _choice(String label, bool selected, VoidCallback onTap) {
    return Card(
      color: selected ? AppColors.primaryContainer : AppColors.surface,
      surfaceTintColor:
          selected ? AppColors.primaryContainer : AppColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side:
            BorderSide(color: selected ? AppColors.primary : AppColors.outline),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              Icon(
                selected
                    ? Icons.radio_button_checked
                    : Icons.radio_button_unchecked,
                color:
                    selected ? AppColors.primary : AppColors.onSurfaceVariant,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(label,
                    style: TextStyle(
                        fontSize: 17,
                        fontWeight:
                            selected ? FontWeight.w600 : FontWeight.w500,
                        color: selected
                            ? AppColors.primary
                            : AppColors.onSurface)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
          backgroundColor: AppColors.surface,
          foregroundColor: AppColors.onSurface,
          surfaceTintColor: AppColors.surface,
          title: Text(tr(_isEdit ? 'editRecord' : 'addRecord'),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 22))),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            FutureBuilder<List<Person>>(
              future: _peopleFuture,
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const SizedBox(height: 58);
                }
                final people = snapshot.data!;
                return DropdownButtonFormField<String?>(
                  initialValue: people.any((p) => p.id == _selectedPerson?.id)
                      ? _selectedPerson?.id
                      : null,
                  isExpanded: true,
                  decoration: InputDecoration(labelText: tr('choosePerson')),
                  items: [
                    DropdownMenuItem<String?>(
                      value: null,
                      child: Text(
                        tr('noPersonSelected'),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    ...people.map((person) => DropdownMenuItem<String?>(
                          value: person.id,
                          child: Text(
                            person.phone.isEmpty
                                ? person.name
                                : '${person.name} · ${person.phone}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        )),
                  ],
                  onChanged: (id) {
                    final selected = people.cast<Person?>().firstWhere(
                          (person) => person?.id == id,
                          orElse: () => null,
                        );
                    setState(() {
                      _selectedPerson = selected;
                      if (selected != null) {
                        _nameCtrl.text = selected.name;
                        _phoneCtrl.text = selected.phone;
                      }
                    });
                  },
                );
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _nameCtrl,
              textCapitalization: TextCapitalization.words,
              style: const TextStyle(fontSize: 18),
              decoration: InputDecoration(labelText: tr('name')),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? tr('errName') : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _phoneCtrl,
              keyboardType: TextInputType.phone,
              style: const TextStyle(fontSize: 18),
              decoration: InputDecoration(labelText: tr('phone')),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _amountCtrl,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              style: const TextStyle(fontSize: 18),
              decoration: InputDecoration(
                  labelText: tr('amount'), prefixText: '${tr('currency')} '),
              validator: (v) {
                final n = _parse(v);
                return (n == null || n <= 0) ? tr('errAmount') : null;
              },
            ),
            const SizedBox(height: 24),

            Text(tr('date'),
                style: const TextStyle(
                    fontSize: 16, color: AppColors.onSurfaceVariant)),
            const SizedBox(height: 8),
            const SizedBox(width: double.infinity, child: CalendarToggle()),
            const SizedBox(height: 10),
            InkWell(
              onTap: _pickDate,
              borderRadius: BorderRadius.circular(14),
              child: Container(
                height: 56,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  border: Border.all(color: AppColors.outlineVariant),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(DateService.format(_date),
                          style: const TextStyle(fontSize: 18)),
                    ),
                    const Icon(Icons.calendar_today_outlined,
                        color: AppColors.primary),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 28),

            _choice(tr('noInterest'), !_hasInterest,
                () => setState(() => _hasInterest = false)),
            _choice(tr('withInterest'), _hasInterest,
                () => setState(() => _hasInterest = true)),
            if (_hasInterest) ...[
              const SizedBox(height: 8),
              TextFormField(
                controller: _rateCtrl,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                style: const TextStyle(fontSize: 18),
                decoration: InputDecoration(
                    labelText: tr('interestRate'), suffixText: '%'),
                validator: (v) {
                  if (!_hasInterest) return null;
                  final n = _parse(v);
                  return (n == null || n <= 0) ? tr('errRate') : null;
                },
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: SegmentedButton<String>(
                  showSelectedIcon: false,
                  segments: [
                    ButtonSegment(value: 'month', label: Text(tr('perMonth'))),
                    ButtonSegment(value: 'year', label: Text(tr('perYear'))),
                  ],
                  selected: {_rateType},
                  onSelectionChanged: (s) =>
                      setState(() => _rateType = s.first),
                ),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                initialValue: _method,
                isExpanded: true,
                decoration: InputDecoration(labelText: tr('method')),
                items: [
                  DropdownMenuItem(value: 'simple', child: Text(tr('simple'))),
                  DropdownMenuItem(
                      value: 'compound', child: Text(tr('compound'))),
                ],
                onChanged: (v) => setState(() => _method = v ?? 'simple'),
              ),
            ],
            const SizedBox(height: 24),
            TextFormField(
              controller: _notesCtrl,
              maxLines: 4,
              minLines: 3,
              style: const TextStyle(fontSize: 18),
              decoration: InputDecoration(
                  labelText: tr('notes'), alignLabelWithHint: true),
            ),
            const SizedBox(height: 32),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: Text(tr('cancel')),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton(
                    onPressed: _save,
                    child: Text(tr('save')),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}
