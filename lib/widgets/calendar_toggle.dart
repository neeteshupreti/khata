import 'package:flutter/material.dart';

import '../l10n/app_strings.dart';
import '../services/app_colors.dart';
import '../services/settings.dart';

class CalendarToggle extends StatelessWidget {
  const CalendarToggle({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: Settings.useBs,
      builder: (context, useBs, _) {
        return Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            border: Border.all(color: AppColors.outline),
            borderRadius: BorderRadius.circular(14),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
          child: SegmentedButton<bool>(
            showSelectedIcon: false,
            style: ButtonStyle(
              visualDensity: VisualDensity.compact,
              padding: WidgetStatePropertyAll(
                  EdgeInsets.symmetric(horizontal: 14, vertical: 6)),
              foregroundColor: WidgetStateColor.resolveWith((s) {
                if (s.contains(WidgetState.selected)) {
                  return AppColors.onPrimary;
                }
                return AppColors.onSurfaceVariant;
              }),
              backgroundColor: WidgetStateColor.resolveWith((s) {
                if (s.contains(WidgetState.selected)) {
                  return AppColors.primary;
                }
                return Colors.transparent;
              }),
            ),
            segments: [
              ButtonSegment(
                  value: false,
                  label: Text(tr('ad'),
                      maxLines: 1, overflow: TextOverflow.ellipsis)),
              ButtonSegment(
                  value: true,
                  label: Text(tr('bs'),
                      maxLines: 1, overflow: TextOverflow.ellipsis)),
            ],
            selected: {useBs},
            onSelectionChanged: (s) => Settings.setUseBs(s.first),
          ),
        );
      },
    );
  }
}
