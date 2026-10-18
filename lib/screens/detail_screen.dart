import 'package:flutter/material.dart';

import '../db/local_database.dart';
import '../l10n/app_strings.dart';
import '../models/payment.dart';
import '../models/record.dart';
import '../services/app_colors.dart';
import '../services/app_status_colors.dart';
import '../services/date_service.dart';
import '../services/format_service.dart';
import '../services/interest_calculator.dart';
import '../services/settings.dart';
import '../widgets/info_row.dart';
import '../widgets/status_badge.dart';
import 'add_edit_screen.dart';

class _DetailData {
  final Record record;
  final List<Payment> payments;
  final InterestResult calc;
  _DetailData(this.record, this.payments, this.calc);
}

class DetailScreen extends StatefulWidget {
  final String recordId;
  const DetailScreen({super.key, required this.recordId});

  @override
  State<DetailScreen> createState() => _DetailScreenState();
}

class _DetailScreenState extends State<DetailScreen>
    with SettingsListener<DetailScreen>, DataListener<DetailScreen> {
  final _db = LocalDatabase.instance;
  late Future<_DetailData?> _future;
  bool _deleting = false;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  @override
  void onDataChanged() {
    if (_deleting) return;
    setState(() => _future = _load());
  }

  Future<_DetailData?> _load() async {
    final record = await _db.getRecord(widget.recordId);
    if (record == null) return null;
    final payments = await _db.getPayments(record.id);
    return _DetailData(
      record,
      payments,
      InterestCalculator.calculate(record, payments),
    );
  }

  void _snack(String msg) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          backgroundColor: AppColors.primary,
          behavior: SnackBarBehavior.floating,
          content: Text(msg)));

  Future<bool> _confirm(String title, String message) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        surfaceTintColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
        content: Text(message),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(tr('cancel'))),
          TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: Text(tr('yes'),
                  style: const TextStyle(fontWeight: FontWeight.w600))),
        ],
      ),
    );
    return mounted && (result ?? false);
  }

  Future<void> _markPaid(_DetailData d) async {
    if (!await _confirm(tr('markPaidTitle'), tr('markPaidMsg')) || !mounted) {
      return;
    }
    final totalDue = d.calc.totalDue;
    if (totalDue > 0) {
      await _db.insertPayment(Payment(
        recordId: d.record.id,
        amount: totalDue,
        date: DateService.dateOnly(DateTime.now()),
      ));
    }
    await _db.refreshStatus(d.record.id);
    if (!mounted) return;
    _snack(tr('paidSaved'));
  }

  Future<void> _markHalf(_DetailData d) async {
    final remaining = d.calc.remainingPrincipal;
    final interest = d.calc.interest;
    final totalDue = d.calc.totalDue;

    final defaultHalf = totalDue / 2;
    final ctrl = TextEditingController(
        text: defaultHalf == defaultHalf.roundToDouble()
            ? defaultHalf.toStringAsFixed(0)
            : defaultHalf.toStringAsFixed(2));
    final formKey = GlobalKey<FormState>();

    final amount = await showDialog<double>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        surfaceTintColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(tr('markHalf'),
            style: const TextStyle(fontWeight: FontWeight.w600)),
        content: SingleChildScrollView(
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [

                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Column(
                    children: [
                      _miniRow(tr('remaining'), Fmt.money(remaining)),
                      const SizedBox(height: 6),
                      _miniRow(tr('interestAmount'), Fmt.money(interest)),
                      const SizedBox(height: 6),
                      _miniRow(tr('totalDue'), Fmt.money(totalDue),
                          bold: true, accent: true),
                    ],
                  ),
                ),
                TextFormField(
                  controller: ctrl,
                  autofocus: true,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  style: const TextStyle(fontSize: 18),
                  decoration: InputDecoration(
                    labelText: tr('payAmount'),
                    hintText: Fmt.money(totalDue),
                    prefixText: '${tr('currency')} ',
                  ),
                  validator: (v) {
                    final n =
                        double.tryParse((v ?? '').replaceAll(',', '').trim());
                    if (n == null || n <= 0 || n > totalDue + 0.005) {
                      return tr('payErr');
                    }
                    return null;
                  },
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx), child: Text(tr('cancel'))),
          TextButton(
            onPressed: () {
              if (!formKey.currentState!.validate()) return;
              Navigator.pop(
                  ctx, double.parse(ctrl.text.replaceAll(',', '').trim()));
            },
            child: Text(tr('save'),
                style: const TextStyle(fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
    ctrl.dispose();
    if (!mounted || amount == null) return;

    await _db.insertPayment(Payment(
      recordId: d.record.id,
      amount: amount,
      date: DateService.dateOnly(DateTime.now()),
    ));
    await _db.refreshStatus(d.record.id);
    if (!mounted) return;
    _snack(tr('paymentSaved'));
  }

  Widget _miniRow(String label, String value,
      {bool bold = false, bool accent = false}) {
    return Row(
      children: [
        Expanded(
          child: Text(label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                  fontSize: 14,
                  fontWeight: bold ? FontWeight.w600 : FontWeight.w400,
                  color: accent
                      ? AppColors.primary
                      : AppColors.onSurfaceVariant)),
        ),
        const SizedBox(width: 8),
        Text(value,
            style: TextStyle(
                fontSize: 14,
                fontWeight: bold ? FontWeight.w700 : FontWeight.w500,
                color: accent ? AppColors.primary : AppColors.onSurface)),
      ],
    );
  }

  Future<void> _edit(_DetailData d) async {
    await Navigator.push(context,
        MaterialPageRoute(builder: (_) => AddEditScreen(record: d.record)));
  }

  Future<void> _delete(_DetailData d) async {
    final sure = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        surfaceTintColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(tr('deleteTitle'),
            style: const TextStyle(fontWeight: FontWeight.w600)),
        content: Text(tr('deleteMsg')),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(tr('cancel'))),
          TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: Text(tr('delete'),
                  style: TextStyle(
                      color: AppColors.unpaid, fontWeight: FontWeight.w600))),
        ],
      ),
    );
    if (!mounted || sure != true) return;
    _deleting = true;
    await _db.deleteRecord(d.record.id);
    if (!mounted) return;
    _snack(tr('deleted'));
    Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
          backgroundColor: AppColors.surface,
          foregroundColor: AppColors.onSurface,
          surfaceTintColor: AppColors.surface,
          title: Text(tr('recordDetail'),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 22))),
      body: FutureBuilder<_DetailData?>(
        future: _future,
        builder: (context, snap) {
          if (snap.connectionState != ConnectionState.done && !snap.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snap.hasError) return Center(child: Text(tr('error')));
          final d = snap.data;
          if (d == null) return Center(child: Text(tr('notFound')));
          return _content(d);
        },
      ),
    );
  }

  Widget _content(_DetailData d) {
    final r = d.record;
    final c = d.calc;
    final isPaid = r.status == RecordStatus.paid;
    final statusColors =
        Theme.of(context).extension<AppStatusColors>() ?? AppStatusColors.light;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [

        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Text(r.name,
                  style: const TextStyle(
                      fontSize: 26, fontWeight: FontWeight.w700)),
            ),
            const SizedBox(width: 12),
            StatusBadge(status: r.status),
          ],
        ),
        const SizedBox(height: 16),

        Card(
          color: AppColors.surface,
          surfaceTintColor: AppColors.surface,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                InfoRow(
                    label: tr('originalAmount'), value: Fmt.money(r.principal)),
                InfoRow(
                    label: tr('paidSoFar'),
                    value: Fmt.money(c.paidPrincipal),
                    bold: true),
                InfoRow(
                    label: tr('remaining'),
                    value: Fmt.money(c.remainingPrincipal),
                    bold: true),
                if (r.hasInterest) ...[
                  const SizedBox(height: 4),
                  const Divider(),
                  InfoRow(
                      label: tr('interestAmount'),
                      value: Fmt.money(c.interest),
                      bold: true),
                  InfoRow(
                      label: tr(isPaid ? 'totalAmount' : 'totalDue'),
                      value: Fmt.money(isPaid ? c.totalAmount : c.totalDue),
                      bold: true),
                ],
              ],
            ),
          ),
        ),
        const SizedBox(height: 8),

        if (r.phone.isNotEmpty)
          InfoRow(label: tr('phoneLabel'), value: Fmt.digits(r.phone)),
        InfoRow(label: tr('date'), value: DateService.format(r.date)),

        if (r.hasInterest) ...[
          InfoRow(
              label: tr('interestRateLabel'),
              value:
                  '${Fmt.number(r.rate)}% · ${tr(r.rateType == 'year' ? 'perYear' : 'perMonth')}'),
          InfoRow(
              label: tr('methodLabel'),
              value:
                  tr(r.interestMethod == 'compound' ? 'compound' : 'simple')),
          InfoRow(
              label: tr('duration'),
              value:
                  '${Fmt.integer(c.totalDays)} ${tr('days')} (${Fmt.number(c.durationUnits)} ${tr(r.rateType == 'year' ? 'years' : 'months')})'),
          Text(tr('interestNote'),
              style: const TextStyle(
                  fontSize: 14, color: AppColors.onSurfaceVariant)),
        ],

        if (r.notes.isNotEmpty) ...[
          const SizedBox(height: 8),
          Text(tr('notesLabel'),
              style: const TextStyle(
                  fontSize: 16, color: AppColors.onSurfaceVariant)),
          const SizedBox(height: 4),
          Text(r.notes, style: const TextStyle(fontSize: 17)),
        ],

        const SizedBox(height: 24),
        if (!isPaid) ...[
          FilledButton(
            onPressed: () => _markPaid(d),
            style: FilledButton.styleFrom(
              backgroundColor: statusColors.paidContainer,
              foregroundColor: statusColors.paid,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14)),
            ),
            child: Text(tr('markPaid')),
          ),
          const SizedBox(height: 10),
          OutlinedButton(
            onPressed: () => _markHalf(d),
            style: OutlinedButton.styleFrom(
              foregroundColor: statusColors.half,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14)),
            ),
            child: Text(tr('markHalf')),
          ),
          const SizedBox(height: 10),
        ],
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                  onPressed: () => _edit(d), child: Text(tr('edit'))),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: OutlinedButton(
                onPressed: () => _delete(d),
                style: OutlinedButton.styleFrom(
                  foregroundColor: statusColors.unpaid,
                ),
                child: Text(tr('delete')),
              ),
            ),
          ],
        ),

        const SizedBox(height: 28),
        Text(tr('history'),
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
        const SizedBox(height: 8),
        if (d.payments.isEmpty)
          Text(tr('noPayments'),
              style: const TextStyle(
                  fontSize: 16, color: AppColors.onSurfaceVariant))
        else
          for (int i = 0; i < d.payments.length; i++)
            _PaymentTile(
                payment: d.payments[i], showDivider: i < d.payments.length - 1),
        const SizedBox(height: 24),
      ],
    );
  }
}

class _PaymentTile extends StatelessWidget {
  final Payment payment;
  final bool showDivider;
  const _PaymentTile({required this.payment, required this.showDivider});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Card(
          color: AppColors.surface,
          surfaceTintColor: AppColors.surface,
          margin: EdgeInsets.zero,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: const BorderSide(color: AppColors.outline)),
          child: ListTile(
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            leading: const CircleAvatar(
              radius: 18,
              backgroundColor: AppColors.primaryContainer,
              child: Icon(Icons.payment, size: 18, color: AppColors.primary),
            ),
            title: Text(Fmt.money(payment.amount),
                style:
                    const TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
            subtitle: Text(DateService.format(payment.date),
                style: const TextStyle(
                    fontSize: 15, color: AppColors.onSurfaceVariant)),
          ),
        ),
        if (showDivider) const SizedBox(height: 8),
        if (showDivider) const Divider(height: 1, color: AppColors.outline),
      ],
    );
  }
}
