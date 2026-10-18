import 'package:flutter/material.dart';

import '../l10n/app_strings.dart';
import '../models/sort_option.dart';
import '../services/app_colors.dart';

class SortDialog extends StatelessWidget {
  final SortOption current;
  const SortDialog({super.key, required this.current});

  static Future<SortOption?> show(BuildContext context, SortOption current) {
    return showModalBottomSheet<SortOption>(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      isScrollControlled: true,
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.6,
      ),
      builder: (_) => SortDialog(current: current),
    );
  }

  void _pick(BuildContext context, SortOption option) {
    Navigator.of(context).pop(option);
  }

  String _label(BuildContext context, SortField field, SortDirection dir) {
    final isAsc = dir == SortDirection.asc;
    switch (field) {
      case SortField.name:
        return tr('sortByName') + (isAsc ? ' A→Z' : ' Z→A');
      case SortField.date:
        return isAsc ? tr('oldestFirst') : tr('newestFirst');
      case SortField.amount:
        return isAsc ? tr('lowestFirst') : tr('highestFirst');
    }
  }

  @override
  Widget build(BuildContext context) {
    final items = [
      (SortField.name, SortDirection.asc),
      (SortField.name, SortDirection.desc),
      (SortField.date, SortDirection.desc),
      (SortField.date, SortDirection.asc),
      (SortField.amount, SortDirection.desc),
      (SortField.amount, SortDirection.asc),
    ];

    return Padding(
      padding: EdgeInsets.fromLTRB(
        16,
        MediaQuery.of(context).viewInsets.bottom +
            12,
        16,
        12,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [

          Container(
            width: 36,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.outline,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 12),
          Text(tr('sort'),
              style:
                  const TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
          const SizedBox(height: 12),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: items.length,
            separatorBuilder: (_, __) => const SizedBox(height: 6),
            itemBuilder: (_, i) {
              final (field, dir) = items[i];
              final isSelected =
                  current.field == field && current.direction == dir;
              return _SortOptionTile(
                label: _label(context, field, dir),
                selected: isSelected,
                onTap: () => _pick(context, SortOption(field, dir)),
              );
            },
          ),
          const SizedBox(height: 4),
        ],
      ),
    );
  }
}

class _SortOptionTile extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _SortOptionTile(
      {required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? AppColors.primaryContainer : AppColors.surface,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
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
                size: 22,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(label,
                    style: TextStyle(
                        fontSize: 16,
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
}
