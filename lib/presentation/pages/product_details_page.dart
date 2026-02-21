import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/service_locator.dart';
import '../../core/utils/app_strings.dart';
import '../../core/providers/settings_provider.dart';
import '../../data/models/product_model.dart';
import '../../data/models/stock_movement_model.dart';
import '../../domain/repositories/i_inventory_repository.dart';
import 'add_edit_product_page.dart';

class ProductDetailsPage extends StatefulWidget {
  final Product product;

  const ProductDetailsPage({super.key, required this.product});

  @override
  State<ProductDetailsPage> createState() => _ProductDetailsPageState();
}

class _ProductDetailsPageState extends State<ProductDetailsPage> {
  final IInventoryRepository _repository = getIt<IInventoryRepository>();
  late Product _product;

  @override
  void initState() {
    super.initState();
    _product = widget.product;
  }

  // Ürünü yeniden yükle
  Future<void> _refreshProduct() async {
    final result = await _repository.getProductById(_product.id);
    result.fold((err) => null, (updated) {
      if (updated != null && mounted) {
        setState(() => _product = updated);
      }
    });
  }

  // --- STOCK IN ---
  void _showStockInDialog(String lang) {
    int amount = 1;
    String reason = AppStrings.get('reason_stock_in', lang);
    final reasons = [
      AppStrings.get('reason_stock_in', lang),
      AppStrings.get('reason_return', lang),
      AppStrings.get('reason_correction', lang),
    ];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      backgroundColor: Theme.of(context).cardColor,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) => Padding(
          padding: EdgeInsets.fromLTRB(
            24,
            24,
            24,
            MediaQuery.of(ctx).viewInsets.bottom + 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.successBg,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.add_circle,
                      color: AppColors.success,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    AppStrings.get('btn_stock_in', lang),
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).textTheme.headlineMedium?.color,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Text(
                AppStrings.get('label_amount', lang),
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).textTheme.bodyLarge?.color,
                ),
              ),
              const SizedBox(height: 8),
              // Stepper
              Container(
                decoration: BoxDecoration(
                  color: Theme.of(context).scaffoldBackgroundColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: amount > 1
                          ? () => setSheetState(() => amount--)
                          : null,
                      icon: const Icon(Icons.remove, size: 20),
                      style: IconButton.styleFrom(
                        backgroundColor: Theme.of(context).cardColor,
                        foregroundColor: AppColors.primary,
                        disabledForegroundColor: Colors.grey[600],
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                    Expanded(
                      child: TextField(
                        controller: TextEditingController(text: '$amount')
                          ..selection = TextSelection.fromPosition(
                            TextPosition(offset: '$amount'.length),
                          ),
                        keyboardType: TextInputType.number,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(
                            context,
                          ).textTheme.headlineMedium?.color,
                        ),
                        decoration: const InputDecoration(
                          border: InputBorder.none,
                          isDense: true,
                          contentPadding: EdgeInsets.zero,
                        ),
                        onChanged: (val) {
                          final parsed = int.tryParse(val);
                          if (parsed != null && parsed >= 0) {
                            amount = parsed;
                            // State'i güncellemiyoruz ki cursor başa atlamasın
                            // Butonlara basıldığında setState tetiklenince düzelecek
                          }
                        },
                      ),
                    ),
                    IconButton(
                      onPressed: () => setSheetState(() => amount++),
                      icon: const Icon(Icons.add, size: 20),
                      style: IconButton.styleFrom(
                        backgroundColor: Theme.of(context).cardColor,
                        foregroundColor: AppColors.primary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Text(
                AppStrings.get('label_reason', lang),
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).textTheme.bodyLarge?.color,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: reasons.map((r) {
                  final selected = r == reason;
                  return ChoiceChip(
                    label: Text(r),
                    selected: selected,
                    onSelected: (_) => setSheetState(() => reason = r),
                    selectedColor: AppColors.success,
                    labelStyle: TextStyle(
                      color: selected
                          ? Colors.white
                          : Theme.of(context).textTheme.bodyMedium?.color,
                      fontWeight: FontWeight.w500,
                      fontSize: 13,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    side: BorderSide(
                      color: selected ? AppColors.success : Colors.grey[300]!,
                    ),
                    showCheckmark: false,
                  );
                }).toList(),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: () async {
                    await _repository.adjustStock(
                      productId: _product.id,
                      quantityChange: amount.toDouble(),
                      reason: reason,
                    );
                    await _refreshProduct();
                    if (ctx.mounted) Navigator.pop(ctx);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.success,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    '$amount ${AppStrings.get('btn_add_amount', lang)}',
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // --- STOCK OUT ---
  void _showStockOutDialog(String lang) {
    int amount = 1;
    String reason = AppStrings.get('reason_sale', lang);
    final reasons = [
      AppStrings.get('reason_sale', lang),
      AppStrings.get('reason_damaged', lang),
      AppStrings.get('reason_lost', lang),
      AppStrings.get('reason_correction', lang),
    ];
    final noteController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      backgroundColor: Theme.of(context).cardColor,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) {
          final overLimit = amount > _product.quantity;
          return Padding(
            padding: EdgeInsets.fromLTRB(
              24,
              24,
              24,
              MediaQuery.of(ctx).viewInsets.bottom + 24,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppColors.criticalBg,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.remove_circle,
                        color: AppColors.critical,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      AppStrings.get('btn_stock_out', lang),
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(
                          context,
                        ).textTheme.headlineMedium?.color,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      '${AppStrings.get('label_current_stock', lang)} ${_product.quantity}',
                      style: TextStyle(color: Colors.grey[500], fontSize: 13),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Text(
                  AppStrings.get('label_amount', lang),
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).textTheme.bodyLarge?.color,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  decoration: BoxDecoration(
                    color: overLimit
                        ? AppColors.criticalBg.withValues(alpha: 0.1)
                        : Theme.of(context).scaffoldBackgroundColor,
                    borderRadius: BorderRadius.circular(12),
                    border: overLimit
                        ? Border.all(color: AppColors.critical, width: 1)
                        : null,
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 4,
                    vertical: 4,
                  ),
                  child: Row(
                    children: [
                      IconButton(
                        onPressed: amount > 1
                            ? () => setSheetState(() => amount--)
                            : null,
                        icon: const Icon(Icons.remove, size: 20),
                        style: IconButton.styleFrom(
                          backgroundColor: Theme.of(context).cardColor,
                          foregroundColor: AppColors.primary,
                          disabledForegroundColor: Colors.grey[600],
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                      Expanded(
                        child: TextField(
                          controller: TextEditingController(text: '$amount')
                            ..selection = TextSelection.fromPosition(
                              TextPosition(offset: '$amount'.length),
                            ),
                          keyboardType: TextInputType.number,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: overLimit
                                ? AppColors.critical
                                : Theme.of(
                                    context,
                                  ).textTheme.headlineMedium?.color,
                          ),
                          decoration: const InputDecoration(
                            border: InputBorder.none,
                            isDense: true,
                            contentPadding: EdgeInsets.zero,
                          ),
                          onChanged: (val) {
                            final parsed = int.tryParse(val);
                            if (parsed != null && parsed >= 0) {
                              setSheetState(() => amount = parsed);
                            } else if (val.isEmpty) {
                              // Boş ise 0 varsayalım veya hata vermeyelim, set 0
                              setSheetState(() => amount = 0);
                            }
                          },
                        ),
                      ),
                      IconButton(
                        onPressed: () => setSheetState(() => amount++),
                        icon: const Icon(Icons.add, size: 20),
                        style: IconButton.styleFrom(
                          backgroundColor: Theme.of(context).cardColor,
                          foregroundColor: AppColors.primary,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                if (overLimit)
                  Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text(
                      AppStrings.get('msg_over_limit', lang),
                      style: const TextStyle(
                        color: AppColors.critical,
                        fontSize: 12,
                      ),
                    ),
                  ),
                const SizedBox(height: 16),
                Text(
                  AppStrings.get('label_reason', lang),
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).textTheme.bodyLarge?.color,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  children: reasons.map((r) {
                    final selected = r == reason;
                    return ChoiceChip(
                      label: Text(r),
                      selected: selected,
                      onSelected: (_) => setSheetState(() => reason = r),
                      selectedColor: AppColors.critical,
                      labelStyle: TextStyle(
                        color: selected
                            ? Colors.white
                            : Theme.of(context).textTheme.bodyMedium?.color,
                        fontWeight: FontWeight.w500,
                        fontSize: 13,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      side: BorderSide(
                        color: selected
                            ? AppColors.critical
                            : Colors.grey[300]!,
                      ),
                      showCheckmark: false,
                    );
                  }).toList(),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: noteController,
                  decoration: InputDecoration(
                    hintText: AppStrings.get('label_note', lang),
                    hintStyle: TextStyle(color: Colors.grey[400], fontSize: 14),
                    filled: true,
                    fillColor: Theme.of(context).scaffoldBackgroundColor,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: () async {
                      await _repository.adjustStock(
                        productId: _product.id,
                        quantityChange: -amount.toDouble(),
                        reason: reason,
                        note: noteController.text.trim().isEmpty
                            ? null
                            : noteController.text.trim(),
                      );
                      await _refreshProduct();
                      if (ctx.mounted) Navigator.pop(ctx);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.critical,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      '$amount ${AppStrings.get('btn_remove_amount', lang)}',
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final lang = Provider.of<SettingsProvider>(context).languageCode;
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        surfaceTintColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back,
            color: Theme.of(context).textTheme.bodyLarge?.color,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        centerTitle: true,
        title: Text(
          AppStrings.get('title_product_details', lang),
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 18,
            color: Theme.of(context).textTheme.headlineMedium?.color,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined, color: AppColors.primary),
            onPressed: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => AddEditProductPage(productToEdit: _product),
                ),
              );
              _refreshProduct();
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 8),
            _buildProductHeader(lang),
            const SizedBox(height: 24),
            _buildActionButtons(lang),
            const SizedBox(height: 24),
            _buildMovementHistory(lang),
          ],
        ),
      ),
    );
  }

  // --- ÜST KISIM: Görsel + İsim + Kategori + Stok Badge ---
  Widget _buildProductHeader(String lang) {
    final hasImage =
        _product.imagePath != null && File(_product.imagePath!).existsSync();
    final stockColor = _product.quantity <= 0
        ? AppColors.critical
        : _product.quantity < _product.minStockLevel
        ? AppColors.warning
        : AppColors.primary;

    return Column(
      children: [
        SizedBox(
          height: 270,
          child: Center(
            child: SizedBox(
              width: 250,
              height: 250,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  // Ürün görseli
                  Hero(
                    tag: 'product_image_${_product.id}',
                    child: Container(
                      width: 250,
                      height: 250,
                      decoration: BoxDecoration(
                        color: Theme.of(context).cardColor,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Theme.of(
                              context,
                            ).shadowColor.withValues(alpha: 0.1),
                            blurRadius: 5,
                            offset: const Offset(0, 4),
                            blurStyle: BlurStyle.normal,
                          ),
                        ],
                      ),
                      child: hasImage
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(20),
                              child: Image.file(
                                File(_product.imagePath!),
                                fit: BoxFit.cover,
                              ),
                            )
                          : const Icon(
                              Icons.inventory_2_outlined,
                              size: 64,
                              color: AppColors.textSecondary,
                            ),
                    ),
                  ),
                  // Stok badge
                  Positioned(
                    bottom: -10,
                    right: -10,
                    child: Container(
                      width: 70,
                      height: 70,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Theme.of(context).cardColor,
                        border: Border.all(color: stockColor, width: 2.5),
                        boxShadow: [
                          BoxShadow(
                            color: stockColor.withValues(alpha: 0.6),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            '${_product.quantity}',
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w900,
                              color: stockColor,
                            ),
                          ),
                          Text(
                            AppStrings.get(
                              'label_stock_control',
                              lang,
                            ).split(' ').first, // Just "STOK" usually
                            style: TextStyle(
                              fontSize: 7,
                              fontWeight: FontWeight.w700,
                              color: stockColor,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        Text(
          _product.title,
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: Theme.of(context).textTheme.headlineMedium?.color,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.primarySurface,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.category_outlined,
                    size: 14,
                    color: AppColors.primary,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    _product.category.toUpperCase(),
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primary,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
            ),
            if (_product.price > 0) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: AppColors.success.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.sell_outlined,
                      size: 14,
                      color: AppColors.success,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '₺${_product.price.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.success,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }

  // --- ORTA: Stok Giriş / Çıkış Butonları ---
  Widget _buildActionButtons(String lang) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        children: [
          Expanded(
            child: ElevatedButton.icon(
              onPressed: () => _showStockInDialog(lang),
              icon: const Icon(Icons.add_circle, size: 20),
              label: Text(AppStrings.get('btn_stock_in', lang)),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.success,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                textStyle: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 15,
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: ElevatedButton.icon(
              onPressed: () => _showStockOutDialog(lang),
              icon: const Icon(Icons.remove_circle, size: 20),
              label: Text(AppStrings.get('btn_stock_out', lang)),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.critical,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                textStyle: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 15,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- ALT: Hareket Geçmişi ---
  Widget _buildMovementHistory(String lang) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                AppStrings.get('label_history', lang),
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).textTheme.titleLarge?.color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          StreamBuilder<List<StockMovement>>(
            stream: _repository.watchMovementsForProduct(_product.id),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.all(32),
                    child: CircularProgressIndicator(),
                  ),
                );
              }

              final movements = snapshot.data ?? [];

              if (movements.isEmpty) {
                return Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(32),
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardColor,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      Icon(Icons.history, size: 40, color: Colors.grey[400]),
                      const SizedBox(height: 8),
                      Text(
                        AppStrings.get('msg_no_history', lang),
                        style: TextStyle(
                          color: Colors.grey[500],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                );
              }

              return ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                padding: const EdgeInsets.only(bottom: 32),
                itemCount: movements.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (context, index) {
                  final m = movements[index];
                  return _buildMovementTile(m, lang);
                },
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildMovementTile(StockMovement m, String lang) {
    final isPositive = m.type == MovementType.inbound;
    final color = isPositive ? AppColors.success : AppColors.critical;
    final icon = isPositive ? Icons.trending_up : Icons.trending_down;
    final changeText = isPositive
        ? '+${m.quantity.toInt()}'
        : '-${m.quantity.toInt()}';
    // Use localized date format
    final dateStr = DateFormat('dd MMM, HH:mm', lang).format(m.createdAt);

    IconData reasonIcon;
    Color reasonBg;
    String reasonDisplay;

    switch (m.reason) {
      case 'Sale':
      case 'Satış':
        reasonIcon = Icons.shopping_cart_outlined;
        reasonBg = AppColors.criticalBg;
        reasonDisplay = AppStrings.get('reason_sale', lang);
        break;
      case 'Damaged':
      case 'Hasarlı':
        reasonIcon = Icons.warning_amber_rounded;
        reasonBg = const Color(0xFFFFF3E0);
        reasonDisplay = AppStrings.get('reason_damaged', lang);
        break;
      case 'Lost':
      case 'Kayıp':
        reasonIcon = Icons.search_off;
        reasonBg = AppColors.criticalBg;
        reasonDisplay = AppStrings.get('reason_lost', lang);
        break;
      case 'Restock':
      case 'Stok Girişi':
        reasonIcon = Icons.local_shipping_outlined;
        reasonBg = AppColors.successBg;
        reasonDisplay = AppStrings.get('reason_stock_in', lang);
        break;
      case 'Return':
      case 'İade':
        reasonIcon = Icons.assignment_return_outlined;
        reasonBg = AppColors.successBg;
        reasonDisplay = AppStrings.get('reason_return', lang);
        break;
      case 'Initial Stock':
      case 'Başlangıç Stok':
        reasonIcon = Icons.inventory_2_outlined;
        reasonBg = AppColors.blueIconBg;
        reasonDisplay = AppStrings.get('reason_initial', lang);
        break;
      case 'Adjustment':
      case 'Düzeltme':
        reasonIcon = Icons.tune;
        reasonBg = const Color(0xFFFFF3E0);
        reasonDisplay = AppStrings.get('reason_correction', lang);
        break;
      default:
        reasonIcon = icon;
        reasonBg = color.withValues(alpha: 0.1);
        reasonDisplay = m.reason;
    }

    // Adapt reason background for dark mode if it's too light
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final finalReasonBg = isDark ? color.withValues(alpha: 0.15) : reasonBg;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
        border: isDark ? Border.all(color: Colors.white10) : null,
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: finalReasonBg,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(reasonIcon, color: color, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  reasonDisplay,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                    color: Theme.of(context).textTheme.bodyLarge?.color,
                  ),
                ),
                if (m.note != null && m.note!.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(
                      m.note!,
                      style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                    ),
                  ),
                const SizedBox(height: 2),
                Text(
                  m.performedBy != null
                      ? '$dateStr • ${m.performedBy}'
                      : dateStr,
                  style: TextStyle(
                    fontSize: 11,
                    color: Theme.of(context).hintColor,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            changeText,
            style: TextStyle(
              fontWeight: FontWeight.w900,
              fontSize: 16,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
