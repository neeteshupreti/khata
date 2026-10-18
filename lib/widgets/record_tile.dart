import 'package:flutter/material.dart';

import '../models/record.dart';
import '../services/app_colors.dart';
import '../services/app_status_colors.dart';
import '../services/date_service.dart';
import '../services/format_service.dart';
import 'status_badge.dart';

class RecordTile extends StatelessWidget {
  final Record record;
  final VoidCallback onTap;
  const RecordTile({super.key, required this.record, required this.onTap});

  static IconData _iconFor(String status) {
    switch (status) {
      case RecordStatus.paid:
        return Icons.check_circle;
      case RecordStatus.half:
        return Icons.hourglass_bottom;
      default:
        return Icons.pending;
    }
  }

  @override
  Widget build(BuildContext context) {
    final statusColors =
        Theme.of(context).extension<AppStatusColors>() ?? AppStatusColors.light;
    final Color iconColor;
    switch (record.status) {
      case RecordStatus.paid:
        iconColor = statusColors.paid;
        break;
      case RecordStatus.half:
        iconColor = statusColors.half;
        break;
      default:
        iconColor = statusColors.unpaid;
    }

    return Card(
      elevation: 0,
      margin: EdgeInsets.zero,
      color: AppColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: const BorderSide(color: AppColors.outline),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              CircleAvatar(
                radius: 22,
                backgroundColor: iconColor.withValues(alpha: 0.10),
                foregroundColor: iconColor,
                child: Icon(_iconFor(record.status), size: 20),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(record.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            fontSize: 19, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 4),
                    Text(DateService.format(record.date),
                        style: const TextStyle(
                            fontSize: 15, color: AppColors.onSurfaceVariant)),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(Fmt.money(record.principal),
                      style: const TextStyle(
                          fontSize: 19, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 6),
                  StatusBadge(status: record.status),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
