import 'dart:io';
import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../data/models/product_model.dart';

class ProductListTile extends StatelessWidget {
  final Product product;
  final VoidCallback? onTap;
  final VoidCallback? onDelete;

  const ProductListTile({
    super.key,
    required this.product,
    this.onTap,
    this.onDelete,
  });

  // Stok durumuna göre sol kenar rengi
  Color get _statusColor {
    if (product.quantity == 0) return AppColors.critical;
    if (product.quantity < product.minStockLevel) return AppColors.warning;
    return AppColors.success;
  }

  // Miktar metninin rengi
  Color get _quantityColor {
    if (product.quantity == 0) return AppColors.critical;
    if (product.quantity < product.minStockLevel) return AppColors.warning;
    return AppColors.primary;
  }

  // Ürüne uygun ikon
  IconData get _productIcon {
    switch (product.category.toLowerCase()) {
      case 'electronics':
      case 'elektronik':
        return Icons.devices;
      case 'accessories':
      case 'aksesuar':
        return Icons.headphones;
      case 'peripherals':
      case 'çevre birimleri':
        return Icons.keyboard;
      case 'storage':
      case 'depolama':
        return Icons.storage;
      case 'gıda':
      case 'grocery':
        return Icons.fastfood;
      case 'ofis malzemeleri':
      case 'office supplies':
        return Icons.business_center;
      case 'mobilya':
      case 'furniture':
        return Icons.chair;
      case 'hammadde':
      case 'raw materials':
        return Icons.science;
      default:
        return Icons.inventory_2;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: ValueKey(product.id),
      direction: DismissDirection.endToStart,
      // Sola kaydır -> Sil
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 24),
        decoration: BoxDecoration(
          color: AppColors.critical,
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Icon(Icons.delete, color: Colors.white, size: 24),
      ),
      confirmDismiss: (direction) async {
        return await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: const Text('Ürünü Sil'),
            content: Text('${product.title} silinecek. Emin misiniz?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('İptal'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(ctx, true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.critical,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Sil'),
              ),
            ],
          ),
        );
      },
      onDismissed: (direction) {
        if (direction == DismissDirection.endToStart) {
          onDelete?.call();
        }
      },
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Theme.of(context).shadowColor.withValues(alpha: 0.03),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: IntrinsicHeight(
            child: Row(
              children: [
                // Sol renk çubuğu
                Container(
                  width: 4,
                  decoration: BoxDecoration(
                    color: _statusColor,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(12),
                      bottomLeft: Radius.circular(12),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                // Ürün ikonu (Hero animasyonlu)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Hero(
                    tag: 'product_image_${product.id}',
                    child:
                        product.imagePath != null &&
                            File(product.imagePath!).existsSync()
                        ? CircleAvatar(
                            radius: 24,
                            backgroundImage: ResizeImage(
                              FileImage(File(product.imagePath!)),
                              width: 150,
                            ),
                          )
                        : CircleAvatar(
                            radius: 24,
                            backgroundColor: AppColors.primarySurface,
                            child: Icon(
                              _productIcon,
                              color: AppColors.primary,
                              size: 22,
                            ),
                          ),
                  ),
                ),
                const SizedBox(width: 12),
                // Ürün bilgileri
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          product.title,
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(
                                fontWeight: FontWeight.w600,
                                fontSize: 15,
                              ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          product.category,
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(
                                fontSize: 13,
                                color: Theme.of(context)
                                    .textTheme
                                    .bodySmall
                                    ?.color
                                    ?.withValues(alpha: 0.7),
                              ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'ID: ${product.id.toString().padLeft(6, '0')}',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[400],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                // Miktar
                Padding(
                  padding: const EdgeInsets.only(right: 16),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        '${product.quantity}',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: _quantityColor,
                        ),
                      ),
                      Text(
                        'adet',
                        style: TextStyle(fontSize: 12, color: _quantityColor),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
