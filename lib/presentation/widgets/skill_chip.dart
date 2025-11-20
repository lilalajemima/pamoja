import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';

class SkillChip extends StatelessWidget {
  final String label;
  final VoidCallback? onDelete;

  const SkillChip({
    super.key,
    required this.label,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Chip(
      label: Text(label),
      labelStyle: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: AppTheme.darkText,
            fontWeight: FontWeight.w500,
          ),
      backgroundColor: AppTheme.lightGreen,
      deleteIcon: onDelete != null
          ? Icon(
              Icons.close,
              size: 18,
              color: AppTheme.darkText,
            )
          : null,
      onDeleted: onDelete,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
    );
  }
}