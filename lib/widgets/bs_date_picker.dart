import 'package:flutter/material.dart';

import '../l10n/app_strings.dart';
import '../services/app_colors.dart';
import '../services/date_service.dart';
import '../services/format_service.dart';

Future<DateTime?> showBsDatePicker(BuildContext context, DateTime initial) {
  return showDialog<DateTime>(
    context: context,
    builder: (_) => _BsPickerDialog(initial: initial),
  );
}

class _BsPickerDialog extends StatefulWidget {
  final DateTime initial;
  const _BsPickerDialog({required this.initial});

  @override
  State<_BsPickerDialog> createState() => _BsPickerDialogState();
}

class _BsPickerDialogState extends State<_BsPickerDialog> {
  late int _year;
  late int _month;
  late int _day;

  @override
  void initState() {
    super.initState();
    final bs = DateService.toBs(widget.initial);
    _year = bs.year.clamp(DateService.minBsYear, DateService.maxBsYear);
    _month = bs.month;
    _day = bs.day;
    _fixDay();
  }

  void _fixDay() {
    final max = DateService.bsDaysInMonth(_year, _month);
    if (_day > max) _day = max;
  }

  InputDecoration _fieldDec(String label) => InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(
            borderRadius: BorderRadius.all(Radius.circular(12))),
      );

  @override
  Widget build(BuildContext context) {
    final daysInMonth = DateService.bsDaysInMonth(_year, _month);
    return AlertDialog(
      backgroundColor: AppColors.surface,
      surfaceTintColor: AppColors.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Text(tr('pickDate'),
          style: const TextStyle(fontWeight: FontWeight.w600)),
      content: SizedBox(
        width: 280,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DropdownButtonFormField<int>(
              initialValue: _year,
              isExpanded: true,
              decoration: _fieldDec(tr('year')),
              items: [
                for (var y = DateService.minBsYear;
                    y <= DateService.maxBsYear;
                    y++)
                  DropdownMenuItem(value: y, child: Text(Fmt.integer(y))),
              ],
              onChanged: (v) => setState(() {
                _year = v!;
                _fixDay();
              }),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<int>(
              initialValue: _month,
              isExpanded: true,
              decoration: _fieldDec(tr('month')),
              items: [
                for (var m = 1; m <= 12; m++)
                  DropdownMenuItem(
                      value: m, child: Text(DateService.bsMonthName(m))),
              ],
              onChanged: (v) => setState(() {
                _month = v!;
                _fixDay();
              }),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<int>(
              initialValue: _day,
              isExpanded: true,
              decoration: _fieldDec(tr('day')),
              items: [
                for (var d = 1; d <= daysInMonth; d++)
                  DropdownMenuItem(value: d, child: Text(Fmt.integer(d))),
              ],
              onChanged: (v) => setState(() => _day = v!),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(tr('cancel')),
        ),
        TextButton(
          onPressed: () =>
              Navigator.pop(context, DateService.fromBs(_year, _month, _day)),
          child: Text(tr('ok')),
        ),
      ],
    );
  }
}
