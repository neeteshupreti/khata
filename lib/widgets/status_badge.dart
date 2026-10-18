import 'package:flutter/material.dart';

import '../l10n/app_strings.dart';
import '../models/record.dart';
import '../services/app_status_colors.dart';

class StatusBadge extends StatelessWidget {
  final String status;
  const StatusBadge({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    final s =
        Theme.of(context).extension<AppStatusColors>() ?? AppStatusColors.light;
    late final String label;
    late final Color bg;
    late final Color text;

    switch (status) {
      case RecordStatus.paid:
        label = tr('statusPaid');
        bg = s.paidContainer;
        text = s.paid;
        break;
      case RecordStatus.half:
        label = tr('statusHalf');
        bg = s.halfContainer;
        text = s.half;
        break;
      default:
        label = tr('statusUnpaid');
        bg = s.unpaidContainer;
        text = s.unpaid;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(label,
          style: TextStyle(
              color: text, fontSize: 13, fontWeight: FontWeight.w600)),
    );
  }
}
