import 'dart:math';

import '../models/payment.dart';
import '../models/record.dart';
import 'date_service.dart';

class InterestResult {
  final double remainingPrincipal;
  final double paidPrincipal;
  final double interest;
  final double totalDue;
  final double totalAmount;
  final int totalDays;
  final double durationUnits;
  final DateTime endDate;

  const InterestResult({
    required this.remainingPrincipal,
    required this.paidPrincipal,
    required this.interest,
    required this.totalDue,
    required this.totalAmount,
    required this.totalDays,
    required this.durationUnits,
    required this.endDate,
  });
}

class InterestCalculator {

  static const double daysPerMonth = 30;
  static const double daysPerYear = 365;

  static double durationUnits(int days, String rateType) =>
      days / (rateType == 'year' ? daysPerYear : daysPerMonth);

  static double interestFor({
    required double principal,
    required double rate,
    required String rateType,
    required String method,
    required DateTime from,
    required DateTime to,
  }) {
    final days = to.difference(from).inDays;
    if (days <= 0 || principal <= 0) return 0;
    final duration = durationUnits(days, rateType);
    final r = rate / 100;
    if (method == 'compound') {
      return principal * pow(1 + r, duration).toDouble() - principal;
    }
    return principal * r * duration;
  }

  static InterestResult calculate(Record r, List<Payment> payments,
      {DateTime? now}) {
    final sorted = [...payments]..sort((a, b) => a.date.compareTo(b.date));

    double outstanding = r.principal;
    double paid = 0;
    double interest = 0;
    DateTime cursor = DateService.dateOnly(r.date);

    for (final p in sorted) {
      var payDate = DateService.dateOnly(p.date);
      if (payDate.isBefore(cursor)) payDate = cursor;
      if (r.hasInterest) {
        interest += interestFor(
          principal: outstanding,
          rate: r.rate,
          rateType: r.rateType,
          method: r.interestMethod,
          from: cursor,
          to: payDate,
        );
      }
      outstanding -= p.amount;
      if (outstanding < 0) outstanding = 0;
      paid += p.amount;
      cursor = payDate;
    }

    final fullyPaid = outstanding <= 0.005;
    if (fullyPaid) outstanding = 0;

    var end = fullyPaid ? cursor : DateService.dateOnly(now ?? DateTime.now());
    if (end.isBefore(cursor)) end = cursor;

    if (r.hasInterest && !fullyPaid) {
      interest += interestFor(
        principal: outstanding,
        rate: r.rate,
        rateType: r.rateType,
        method: r.interestMethod,
        from: cursor,
        to: end,
      );
    }

    final totalDays = end.difference(DateService.dateOnly(r.date)).inDays;
    return InterestResult(
      remainingPrincipal: outstanding,
      paidPrincipal: paid,
      interest: interest,
      totalDue: outstanding + interest,
      totalAmount: r.principal + interest,
      totalDays: totalDays < 0 ? 0 : totalDays,
      durationUnits: durationUnits(totalDays < 0 ? 0 : totalDays, r.rateType),
      endDate: end,
    );
  }
}
