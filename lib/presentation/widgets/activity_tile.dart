import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';

class ActivityTile extends StatelessWidget {
  final String productName;
  final String activityType;
  final String timeAgo;
  final int quantityChange;
  final String? performedBy;

  const ActivityTile({
    super.key,
    required this.productName,
    required this.activityType,
    required this.timeAgo,
    required this.quantityChange,
    this.performedBy,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isPositive = quantityChange > 0;
    final changeColor = isPositive ? AppColors.success : AppColors.critical;
    final changeIcon = isPositive ? Icons.arrow_upward : Icons.arrow_downward;
    final changeText = isPositive ? '+$quantityChange' : '$quantityChange';

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: changeColor.withValues(alpha: 0.1),
            child: Icon(changeIcon, color: changeColor, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  productName,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  performedBy != null
                      ? '$activityType • $timeAgo • $performedBy'
                      : '$activityType • $timeAgo',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.textTheme.bodySmall?.color?.withValues(
                      alpha: 0.7,
                    ),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Text(
            changeText,
            style: TextStyle(
              color: changeColor,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }
}
