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
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: onDelete != null ? 12 : 16,
        vertical: 10,
      ),
      decoration: BoxDecoration(
        color: AppTheme.lightGreen,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppTheme.darkText,
              fontWeight: FontWeight.w500,
            ),
          ),
          if (onDelete != null) ...[
            const SizedBox(width: 6),
            GestureDetector(
              onTap: onDelete,
              child: const Icon(
                Icons.close,
                size: 16,
                color: AppTheme.mediumGray,
              ),
            ),
          ],
        ],
      ),
    );
  }
}