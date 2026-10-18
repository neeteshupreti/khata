import 'package:flutter/material.dart';

import 'app_colors.dart';

@immutable
class AppStatusColors extends ThemeExtension<AppStatusColors> {
  final Color paid;
  final Color paidContainer;
  final Color half;
  final Color halfContainer;
  final Color unpaid;
  final Color unpaidContainer;

  const AppStatusColors({
    required this.paid,
    required this.paidContainer,
    required this.half,
    required this.halfContainer,
    required this.unpaid,
    required this.unpaidContainer,
  });

  static const light = AppStatusColors(
    paid: AppColors.paid,
    paidContainer: AppColors.paidContainer,
    half: AppColors.half,
    halfContainer: AppColors.halfContainer,
    unpaid: AppColors.unpaid,
    unpaidContainer: AppColors.unpaidContainer,
  );

  @override
  AppStatusColors copyWith({
    Color? paid,
    Color? paidContainer,
    Color? half,
    Color? halfContainer,
    Color? unpaid,
    Color? unpaidContainer,
  }) =>
      AppStatusColors(
        paid: paid ?? this.paid,
        paidContainer: paidContainer ?? this.paidContainer,
        half: half ?? this.half,
        halfContainer: halfContainer ?? this.halfContainer,
        unpaid: unpaid ?? this.unpaid,
        unpaidContainer: unpaidContainer ?? this.unpaidContainer,
      );

  @override
  AppStatusColors lerp(ThemeExtension<AppStatusColors>? other, double t) {
    if (other is! AppStatusColors) return this;
    return AppStatusColors(
      paid: Color.lerp(paid, other.paid, t)!,
      paidContainer: Color.lerp(paidContainer, other.paidContainer, t)!,
      half: Color.lerp(half, other.half, t)!,
      halfContainer: Color.lerp(halfContainer, other.halfContainer, t)!,
      unpaid: Color.lerp(unpaid, other.unpaid, t)!,
      unpaidContainer: Color.lerp(unpaidContainer, other.unpaidContainer, t)!,
    );
  }
}
