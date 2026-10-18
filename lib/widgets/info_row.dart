import 'package:flutter/material.dart';

import '../services/app_colors.dart';

class InfoRow extends StatelessWidget {
  final String label;
  final String value;
  final bool bold;
  const InfoRow(
      {super.key, required this.label, required this.value, this.bold = false});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 4,
            child: Text(label,
                style: const TextStyle(
                    fontSize: 15, color: AppColors.onSurfaceVariant)),
          ),
          Expanded(
            flex: 5,
            child: Text(value,
                textAlign: TextAlign.right,
                style: TextStyle(
                    fontSize: bold ? 19 : 17,
                    fontWeight: bold ? FontWeight.w700 : FontWeight.w500,
                    color: bold ? AppColors.primary : AppColors.onSurface)),
          ),
        ],
      ),
    );
  }
}
