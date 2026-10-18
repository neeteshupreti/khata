import 'package:flutter/material.dart';

import '../l10n/app_strings.dart';
import '../models/person.dart';

Future<Person?> showPersonEditorDialog(
  BuildContext context, {
  Person? person,
}) =>
    showDialog<Person>(
      context: context,
      builder: (_) => _PersonEditorDialog(person: person),
    );

class _PersonEditorDialog extends StatefulWidget {
  final Person? person;

  const _PersonEditorDialog({this.person});

  @override
  State<_PersonEditorDialog> createState() => _PersonEditorDialogState();
}

class _PersonEditorDialogState extends State<_PersonEditorDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _phoneController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.person?.name ?? '');
    _phoneController = TextEditingController(text: widget.person?.phone ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;
    Navigator.pop(
      context,
      Person(
        id: widget.person?.id ?? '',
        name: _nameController.text.trim(),
        phone: _phoneController.text.trim(),
        createdAt: widget.person?.createdAt ?? DateTime.now(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
        title: Text(tr(widget.person == null ? 'addPerson' : 'editPerson')),
        content: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _nameController,
                autofocus: true,
                textCapitalization: TextCapitalization.words,
                decoration: InputDecoration(labelText: tr('name')),
                validator: (value) => (value == null || value.trim().isEmpty)
                    ? tr('errName')
                    : null,
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                decoration: InputDecoration(labelText: tr('phone')),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(tr('cancel')),
          ),
          FilledButton(
            onPressed: _save,
            child: Text(tr('save')),
          ),
        ],
      );
}
