import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import '../../core/constants/app_colors.dart';
import '../../core/service_locator.dart';
import '../../data/models/product_model.dart';
import '../../domain/repositories/i_inventory_repository.dart';
import 'scanner_page.dart';

import 'package:provider/provider.dart';
import '../../core/utils/app_strings.dart';
import '../../core/providers/settings_provider.dart';
import '../../domain/repositories/i_category_repository.dart';
import '../../data/models/category_model.dart';

class AddEditProductPage extends StatefulWidget {
  final Product? productToEdit;
  final String? barcode;

  const AddEditProductPage({super.key, this.productToEdit, this.barcode});

  bool get isEditing => productToEdit != null;

  @override
  State<AddEditProductPage> createState() => _AddEditProductPageState();
}

class _AddEditProductPageState extends State<AddEditProductPage> {
  // ... existing fields ...
  final _formKey = GlobalKey<FormState>();
  final IInventoryRepository _repository = getIt<IInventoryRepository>();

  final ICategoryRepository _categoryRepo = getIt<ICategoryRepository>();

  late TextEditingController _nameController;
  late TextEditingController _barcodeController;
  late TextEditingController _quantityTextController;
  late TextEditingController _priceController;
  int _quantity = 0;
  int _minStock = 5;
  String _selectedCategory = 'Genel';
  String? _imagePath;
  bool _isSaving = false;

  List<Category> _categories = [];

  @override
  void initState() {
    super.initState();
    _loadCategories();
    final product = widget.productToEdit;

    _nameController = TextEditingController(text: product?.title ?? '');
    _barcodeController = TextEditingController(
      text: product?.barcode ?? widget.barcode ?? '',
    );
    _quantity = product?.quantity.toInt() ?? 0;
    _minStock = product?.minStockLevel.toInt() ?? 5;
    _selectedCategory = product?.category ?? 'Genel';
    _imagePath = product?.imagePath;
    _quantityTextController = TextEditingController(text: '$_quantity');
    _priceController = TextEditingController(
      text: product?.price != null && product!.price > 0
          ? product.price.toStringAsFixed(2)
          : '',
    );
  }

  Future<void> _loadCategories() async {
    final result = await _categoryRepo.getAllCategories();
    result.fold((err) => null, (data) {
      if (mounted) {
        setState(() {
          _categories = data;
          // Seçili kategori listede yoksa geçici olarak ekle (Görsel tutarlılık için)
          if (!_categories.any((c) => c.name == _selectedCategory)) {
            _categories.add(
              Category()
                ..name = _selectedCategory
                ..colorHex = "#9E9E9E"
                ..iconCodePoint = Icons.category.codePoint,
            );
          }
        });
      }
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _barcodeController.dispose();
    _quantityTextController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(String lang) async {
    final picker = ImagePicker();
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.camera_alt, color: AppColors.primary),
                title: Text(AppStrings.get('source_camera', lang)),
                onTap: () => Navigator.pop(ctx, ImageSource.camera),
              ),
              ListTile(
                leading: const Icon(
                  Icons.photo_library,
                  color: AppColors.primary,
                ),
                title: Text(AppStrings.get('source_gallery', lang)),
                onTap: () => Navigator.pop(ctx, ImageSource.gallery),
              ),
            ],
          ),
        ),
      ),
    );

    if (source == null) return;

    final picked = await picker.pickImage(
      source: source,
      maxWidth: 800,
      imageQuality: 85,
    );
    if (picked == null || !mounted) return;

    // Görseli uygulama dizinine kopyala
    final appDir = await getApplicationDocumentsDirectory();
    final imagesDir = Directory(p.join(appDir.path, 'product_images'));
    if (!await imagesDir.exists()) {
      await imagesDir.create(recursive: true);
    }
    final ext = p.extension(picked.path);
    final fileName = 'product_${DateTime.now().millisecondsSinceEpoch}$ext';
    final savedFile = await File(
      picked.path,
    ).copy(p.join(imagesDir.path, fileName));

    setState(() => _imagePath = savedFile.path);
  }

  Future<void> _scanBarcode() async {
    final result = await Navigator.push<String>(
      context,
      MaterialPageRoute(builder: (_) => const ScannerPage()),
    );
    if (result != null && mounted) {
      setState(() => _barcodeController.text = result);
    }
  }

  Future<void> _saveProduct(String lang) async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    try {
      String title = _nameController.text.trim();
      String? barcode = _barcodeController.text.trim().isEmpty
          ? null
          : _barcodeController.text.trim();

      if (widget.isEditing) {
        final updated = widget.productToEdit!.copyWith(
          title: title,
          barcode: barcode,
          quantity: _quantity.toDouble(),
          minStockLevel: _minStock.toDouble(),
          price:
              double.tryParse(_priceController.text.replaceAll(',', '.')) ??
              0.0,
          category: _selectedCategory,
          imagePath: _imagePath,
          updatedAt: DateTime.now(),
        );
        final result = await _repository.upsertProduct(updated);
        result.fold((err) => throw Exception(err), (_) => null);
      } else {
        final newProduct = Product()
          ..title = title
          ..barcode = barcode
          ..quantity = _quantity.toDouble()
          ..minStockLevel = _minStock.toDouble()
          ..price =
              double.tryParse(_priceController.text.replaceAll(',', '.')) ?? 0.0
          ..category = _selectedCategory
          ..imagePath = _imagePath
          ..createdAt = DateTime.now()
          ..updatedAt = DateTime.now();

        final result = await _repository.upsertProduct(newProduct);
        result.fold((err) => throw Exception(err), (_) => null);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.isEditing
                  ? '${_nameController.text} ${AppStrings.get('msg_updated', lang)}'
                  : '${_nameController.text} ${AppStrings.get('msg_added', lang)}',
            ),
            behavior: SnackBarBehavior.floating,
            backgroundColor: AppColors.success,
          ),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${AppStrings.get('msg_error_prefix', lang)}$e'),
            behavior: SnackBarBehavior.floating,
            backgroundColor: AppColors.critical,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final lang = Provider.of<SettingsProvider>(context).languageCode;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
        surfaceTintColor: Theme.of(context).appBarTheme.surfaceTintColor,
        elevation: 0,
        leading: TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(
            AppStrings.get('btn_cancel_caps', lang),
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 14,
            ),
          ),
        ),
        leadingWidth: 80,
        centerTitle: true,
        title: Text(
          widget.isEditing
              ? AppStrings.get('title_edit_product', lang)
              : AppStrings.get('title_add_product', lang),
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 18,
            color: Theme.of(context).textTheme.titleLarge?.color,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
        child: Form(
          key: _formKey,
          autovalidateMode: AutovalidateMode.onUserInteraction,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildImageUpload(lang),
              const SizedBox(height: 24),
              _buildNameField(lang),
              const SizedBox(height: 20),
              _buildCategoryDropdown(lang),
              const SizedBox(height: 20),
              _buildPriceField(lang),
              const SizedBox(height: 20),
              _buildBarcodeField(lang),
              const SizedBox(height: 28),
              _buildStockControlSection(lang),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
      bottomNavigationBar: _buildSaveButton(lang),
    );
  }

  // Görsel yükleme alanı
  Widget _buildImageUpload(String lang) {
    return Center(
      child: GestureDetector(
        onTap: () => _pickImage(lang),
        child: Container(
          width: 160,
          height: 140,
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: Theme.of(context).dividerColor,
              width: 1.5,
              strokeAlign: BorderSide.strokeAlignInside,
            ),
          ),
          child: _imagePath != null
              ? Stack(
                  fit: StackFit.expand,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(15),
                      child: Image.file(File(_imagePath!), fit: BoxFit.cover),
                    ),
                    Positioned(
                      top: 4,
                      right: 4,
                      child: GestureDetector(
                        onTap: () => setState(() => _imagePath = null),
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: const BoxDecoration(
                            color: Colors.black54,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.close,
                            color: Colors.white,
                            size: 16,
                          ),
                        ),
                      ),
                    ),
                  ],
                )
              : Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.camera_alt_outlined,
                        color: AppColors.primary,
                        size: 28,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      textAlign: TextAlign.center,
                      AppStrings.get('text_upload_image', lang),
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(height: 2),
                  ],
                ),
        ),
      ),
    );
  }

  // Ürün adı
  Widget _buildNameField(String lang) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppStrings.get('label_product_name', lang),
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Theme.of(context).textTheme.bodyMedium?.color,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: _nameController,
          style: TextStyle(
            color: Theme.of(context).textTheme.bodyMedium?.color,
            fontSize: 14,
          ),
          textCapitalization: TextCapitalization.words,
          decoration: _inputDecoration(
            hintText: AppStrings.get('hint_product_name', lang),
          ),
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return AppStrings.get('err_name_required', lang);
            }
            if (value.trim().length < 2) {
              return AppStrings.get('err_name_length', lang);
            }
            return null;
          },
        ),
      ],
    );
  }

  // Fiyat alanı
  Widget _buildPriceField(String lang) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppStrings.get('label_price', lang),
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Theme.of(context).textTheme.bodyMedium?.color,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: _priceController,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          style: TextStyle(
            color: Theme.of(context).textTheme.bodyMedium?.color,
            fontSize: 14,
          ),
          decoration: _inputDecoration(
            hintText: AppStrings.get('hint_price', lang),
            prefixIcon: const Padding(
              padding: EdgeInsets.only(left: 12, right: 8),
              child: Icon(
                Icons.attach_money_rounded,
                color: AppColors.success,
                size: 20,
              ),
            ),
          ),
          validator: (value) {
            if (value != null && value.isNotEmpty) {
              final parsed = double.tryParse(value.replaceAll(',', '.'));
              if (parsed == null || parsed < 0) {
                return AppStrings.get('err_price_invalid', lang);
              }
            }
            return null;
          },
        ),
      ],
    );
  }

  // Kategori seçimi
  Widget _buildCategoryDropdown(String lang) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppStrings.get('label_category', lang),
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Theme.of(context).textTheme.bodyMedium?.color,
          ),
        ),
        const SizedBox(height: 8),
        _categories.isEmpty
            ? const Center(child: CircularProgressIndicator())
            : DropdownButtonFormField<String>(
                initialValue: _selectedCategory,
                style: TextStyle(
                  color: Theme.of(context).textTheme.bodyMedium?.color,
                  fontSize: 14,
                ),
                decoration: _inputDecoration(
                  hintText: AppStrings.get('hint_category', lang),
                ),
                icon: const Icon(
                  Icons.keyboard_arrow_down,
                  color: AppColors.primary,
                ),
                borderRadius: BorderRadius.circular(12),
                items: _categories
                    .map(
                      (cat) => DropdownMenuItem(
                        value: cat.name,
                        child: Row(
                          children: [
                            Icon(
                              IconData(
                                cat.iconCodePoint,
                                fontFamily: 'MaterialIcons',
                              ),
                              color: Color(
                                int.parse(cat.colorHex.replaceAll('#', '0xFF')),
                              ),
                              size: 18,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              cat.name,
                              style: TextStyle(
                                fontSize: 14,
                                color: Theme.of(
                                  context,
                                ).textTheme.bodyMedium?.color,
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                    .toList(),
                onChanged: (value) {
                  if (value != null) setState(() => _selectedCategory = value);
                },
              ),
      ],
    );
  }

  // Barkod alanı + tarayıcı ikonu
  Widget _buildBarcodeField(String lang) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppStrings.get('label_barcode', lang),
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Theme.of(context).textTheme.bodyMedium?.color,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: _barcodeController,
          style: TextStyle(
            color: Theme.of(context).textTheme.bodyMedium?.color,
            fontSize: 14,
          ),
          keyboardType: TextInputType.number,
          decoration: _inputDecoration(
            hintText: AppStrings.get('hint_barcode', lang),
            suffixIcon: IconButton(
              icon: const Icon(Icons.qr_code_scanner, color: AppColors.primary),
              onPressed: _scanBarcode,
            ),
          ),
        ),
      ],
    );
  }

  // Stok kontrol bölümü
  Widget _buildStockControlSection(String lang) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppStrings.get('label_stock_control', lang),
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: Colors.grey[500],
            letterSpacing: 1,
          ),
        ),
        const SizedBox(height: 16),
        // Miktar seçici
        Text(
          AppStrings.get('label_initial_stock', lang),
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Theme.of(context).textTheme.bodyMedium?.color,
          ),
        ),
        const SizedBox(height: 8),
        _buildStepper(
          value: _quantity,
          onChanged: (val) => setState(() {
            _quantity = val;
            _quantityTextController.text = '$val';
          }),
          controller: _quantityTextController,
        ),
        const SizedBox(height: 20),
        // Min stok seviyesi
        Text(
          AppStrings.get('label_min_stock_warning', lang),
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Theme.of(context).textTheme.bodyMedium?.color,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          initialValue: '$_minStock',
          style: TextStyle(
            color: Theme.of(context).textTheme.bodyMedium?.color,
            fontSize: 14,
          ),
          keyboardType: TextInputType.number,
          decoration: _inputDecoration(
            hintText: '0',
            prefixIcon: const Padding(
              padding: EdgeInsets.only(left: 12, right: 8),
              child: Icon(
                Icons.warning_amber_rounded,
                color: AppColors.warning,
                size: 20,
              ),
            ),
          ),
          onChanged: (value) {
            _minStock = int.tryParse(value) ?? 5;
          },
        ),
        const SizedBox(height: 6),
        Text(
          AppStrings.get('hint_stock_warning', lang),
          style: TextStyle(fontSize: 12, color: Colors.grey[400]),
        ),
      ],
    );
  }

  // [-] value [+] stepper widget
  Widget _buildStepper({
    required int value,
    required ValueChanged<int> onChanged,
    required TextEditingController controller,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
      child: Row(
        children: [
          // Azalt
          IconButton(
            onPressed: value > 0 ? () => onChanged(value - 1) : null,
            icon: const Icon(Icons.remove, size: 20),
            style: IconButton.styleFrom(
              backgroundColor: Theme.of(context).cardColor,
              foregroundColor: AppColors.primary,
              disabledForegroundColor: Colors.grey[300],
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
          // Miktar (hem göster hem düzenle)
          Expanded(
            child: TextField(
              controller: controller,
              textAlign: TextAlign.center,
              keyboardType: TextInputType.number,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).textTheme.bodyMedium?.color,
              ),
              decoration: const InputDecoration(
                border: InputBorder.none,
                contentPadding: EdgeInsets.zero,
              ),
              onChanged: (text) {
                final parsed = int.tryParse(text);
                if (parsed != null && parsed >= 0) {
                  setState(() => _quantity = parsed);
                }
              },
            ),
          ),
          // Artır
          IconButton(
            onPressed: () => onChanged(value + 1),
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
    );
  }

  // Save butonu (bottomNavigationBar)
  Widget _buildSaveButton(String lang) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 8, 24, 12),
        child: SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton(
            onPressed: _isSaving ? null : () => _saveProduct(lang),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              disabledBackgroundColor: AppColors.primary.withValues(alpha: 0.5),
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              textStyle: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            child: _isSaving
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : Text(
                    widget.isEditing
                        ? AppStrings.get('btn_update_product', lang)
                        : AppStrings.get('btn_save', lang),
                  ),
          ),
        ),
      ),
    );
  }

  // Ortak input decoration
  InputDecoration _inputDecoration({
    required String hintText,
    Widget? suffixIcon,
    Widget? prefixIcon,
  }) {
    return InputDecoration(
      hintText: hintText,
      hintStyle: TextStyle(color: Colors.grey[400], fontSize: 14),
      suffixIcon: suffixIcon,
      prefixIcon: prefixIcon,
      prefixIconConstraints: const BoxConstraints(minWidth: 40),
      filled: true,
      fillColor: Theme.of(context).cardColor,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.critical, width: 1.5),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.critical, width: 1.5),
      ),
      errorStyle: const TextStyle(color: AppColors.critical, fontSize: 12),
    );
  }
}
