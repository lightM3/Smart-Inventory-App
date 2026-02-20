import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';

enum StockStatus { critical, low, normal }

class CriticalStockCard extends StatelessWidget {
  final String productName;
  final String category;
  final int currentStock;
  final int maxStock;
  final IconData icon;

  const CriticalStockCard({
    super.key,
    required this.productName,
    required this.category,
    required this.currentStock,
    required this.maxStock,
    this.icon = Icons.inventory_2,
  });

  StockStatus get stockStatus {
    final ratio = maxStock > 0 ? currentStock / maxStock : 0.0;
    if (ratio <= 0.2) return StockStatus.critical;
    if (ratio <= 0.5) return StockStatus.low;
    return StockStatus.normal;
  }

  Color get statusColor {
    switch (stockStatus) {
      case StockStatus.critical:
        return AppColors.critical;
      case StockStatus.low:
        return AppColors.warning;
      case StockStatus.normal:
        return AppColors.success;
    }
  }

  String get statusText {
    switch (stockStatus) {
      case StockStatus.critical:
        return 'Kritik';
      case StockStatus.low:
        return 'Düşük Stok';
      case StockStatus.normal:
        return 'Normal';
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final double progress = maxStock > 0
        ? (currentStock / maxStock).clamp(0.0, 1.0)
        : 0.0;

    return Container(
      width: 180,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: theme.shadowColor.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: AppColors.primarySurface,
                child: Icon(icon, color: AppColors.primary, size: 20),
              ),
              const SizedBox(width: 8),
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
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      category,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.textTheme.bodySmall?.color?.withValues(alpha: 
                          0.7,
                        ),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                statusText,
                style: TextStyle(
                  color: statusColor,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
              Text(
                '$currentStock/$maxStock left',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.textTheme.bodySmall?.color?.withValues(alpha: 0.7),
                  fontSize: 12,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: statusColor.withValues(alpha: 0.15),
              valueColor: AlwaysStoppedAnimation<Color>(statusColor),
              minHeight: 6,
            ),
          ),
        ],
      ),
    );
  }
}
