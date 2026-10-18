import 'package:flutter/material.dart';

import '../db/local_database.dart';
import '../l10n/app_strings.dart';
import '../models/payment.dart';
import '../models/record.dart';
import '../services/app_colors.dart';
import '../services/format_service.dart';
import '../services/interest_calculator.dart';
import '../services/settings.dart';

class _SummaryTotals {
  final double given;
  final double interest;
  final double paid;
  final double outstanding;

  const _SummaryTotals({
    required this.given,
    required this.interest,
    required this.paid,
    required this.outstanding,
  });
}

class SummaryScreen extends StatefulWidget {
  const SummaryScreen({super.key});

  @override
  State<SummaryScreen> createState() => _SummaryScreenState();
}

class _SummaryScreenState extends State<SummaryScreen>
    with SettingsListener<SummaryScreen>, DataListener<SummaryScreen> {
  final _db = LocalDatabase.instance;
  late Future<List<(Record, List<Payment>)>> _dataFuture;

  @override
  void initState() {
    super.initState();
    _dataFuture = _db.getRecordsWithPayments();
  }

  @override
  void onDataChanged() {
    setState(() => _dataFuture = _db.getRecordsWithPayments());
  }

  _SummaryTotals _calculate(List<(Record, List<Payment>)> recordData) {
    var given = 0.0;
    var interest = 0.0;
    var paid = 0.0;
    var outstanding = 0.0;
    for (final (record, payments) in recordData) {
      final result = InterestCalculator.calculate(record, payments);
      given += record.principal;
      interest += result.interest;
      paid += result.paidPrincipal;
      outstanding += result.totalDue;
    }
    return _SummaryTotals(
      given: given,
      interest: interest,
      paid: paid,
      outstanding: outstanding,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(tr('summaryTab'),
            maxLines: 1, overflow: TextOverflow.ellipsis),
      ),
      body: FutureBuilder<List<(Record, List<Payment>)>>(
        future: _dataFuture,
        builder: (context, recordsSnapshot) {
          if (!recordsSnapshot.hasData) {
            if (recordsSnapshot.hasError) {
              return Center(child: Text(tr('error')));
            }
            return const Center(child: CircularProgressIndicator());
          }
          final totals = _calculate(recordsSnapshot.data!);
          return ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  _SummaryCard(
                    icon: Icons.south_west,
                    label: tr('totalGiven'),
                    amount: totals.given,
                  ),
                  _SummaryCard(
                    icon: Icons.trending_up,
                    label: tr('totalInterest'),
                    amount: totals.interest,
                  ),
                  _SummaryCard(
                    icon: Icons.payments_outlined,
                    label: tr('totalPaid'),
                    amount: totals.paid,
                  ),
                  _SummaryCard(
                    icon: Icons.account_balance_wallet_outlined,
                    label: tr('totalOutstanding'),
                    amount: totals.outstanding,
                    emphasize: true,
                  ),
                ],
              );
        },
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final double amount;
  final bool emphasize;

  const _SummaryCard({
    required this.icon,
    required this.label,
    required this.amount,
    this.emphasize = false,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      color: emphasize ? AppColors.primaryContainer : AppColors.surface,
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Row(
          children: [
            Icon(icon,
                color: emphasize ? AppColors.primary : AppColors.secondary,
                size: 28),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label,
                      style: const TextStyle(
                          color: AppColors.onSurfaceVariant, fontSize: 15)),
                  const SizedBox(height: 6),
                  Text(
                    Fmt.money(amount),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: emphasize ? AppColors.primary : AppColors.onSurface,
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
