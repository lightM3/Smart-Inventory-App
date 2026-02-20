import 'package:flutter/material.dart';
import '../../core/service_locator.dart';
import '../../domain/repositories/i_category_repository.dart';
import '../../data/models/category_model.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';

class AddEditCategorySheet extends StatefulWidget {
  final Category? category;

  const AddEditCategorySheet({super.key, this.category});

  @override
  State<AddEditCategorySheet> createState() => _AddEditCategorySheetState();
}

class _AddEditCategorySheetState extends State<AddEditCategorySheet> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameCtrl;

  Color _selectedColor = Colors.blue;
  int _selectedIconCode = Icons.category.codePoint;

  // Örnek ikon listesi
  final List<IconData> _iconList = [
    Icons.category,
    Icons.shopping_cart,
    Icons.electrical_services,
    Icons.fastfood,
    Icons.local_drink,
    Icons.checkroom,
    Icons.directions_car,
    Icons.home,
    Icons.spa,
    Icons.sports_soccer,
    Icons.medical_services,
    Icons.menu_book,
    Icons.pets,
    Icons.hardware,
    Icons.card_giftcard,
    Icons.science,
  ];

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.category?.name ?? '');
    if (widget.category != null) {
      _selectedColor = Color(
        int.parse(widget.category!.colorHex.replaceAll('#', '0xFF')),
      );
      _selectedIconCode = widget.category!.iconCodePoint;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              widget.category == null
                  ? 'Yeni Kategori Ekle'
                  : 'Kategoriyi Düzenle',
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),

            TextFormField(
              controller: _nameCtrl,
              decoration: const InputDecoration(
                labelText: 'Kategori Adı',
                border: OutlineInputBorder(),
              ),
              validator: (val) =>
                  val == null || val.isEmpty ? 'Kategori adı giriniz' : null,
            ),
            const SizedBox(height: 16),

            // Renk Seçici Butonu
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Renk Seçimi'),
              trailing: CircleAvatar(backgroundColor: _selectedColor),
              onTap: _showColorPicker,
            ),

            const Divider(),
            const Text(
              'İkon Seçimi',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),

            SizedBox(
              height: 120,
              child: GridView.builder(
                scrollDirection: Axis.horizontal,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                ),
                itemCount: _iconList.length,
                itemBuilder: (context, index) {
                  final icon = _iconList[index];
                  final isSelected = icon.codePoint == _selectedIconCode;
                  return InkWell(
                    onTap: () =>
                        setState(() => _selectedIconCode = icon.codePoint),
                    child: Container(
                      margin: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? _selectedColor.withValues(alpha: 0.2)
                            : null,
                        border: isSelected
                            ? Border.all(color: _selectedColor, width: 2)
                            : null,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        icon,
                        color: isSelected ? _selectedColor : Colors.grey,
                      ),
                    ),
                  );
                },
              ),
            ),

            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _saveCategory,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                backgroundColor: _selectedColor,
                foregroundColor: Colors.white,
              ),
              child: Text(widget.category == null ? 'Ekle' : 'Güncelle'),
            ),
          ],
        ),
      ),
    );
  }

  void _showColorPicker() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Renk Seç'),
        content: SingleChildScrollView(
          child: BlockPicker(
            pickerColor: _selectedColor,
            onColorChanged: (color) => setState(() => _selectedColor = color),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Tamam'),
          ),
        ],
      ),
    );
  }

  void _saveCategory() async {
    if (_formKey.currentState!.validate()) {
      final strColor =
          '#${_selectedColor.toARGB32().toRadixString(16).substring(2, 8).toUpperCase()}';

      final cat = widget.category ?? Category()
        ..name = _nameCtrl.text.trim()
        ..colorHex = strColor
        ..iconCodePoint = _selectedIconCode;

      if (widget.category != null) {
        cat.name = _nameCtrl.text.trim();
        cat.colorHex = strColor;
        cat.iconCodePoint = _selectedIconCode;
      }

      final repo = getIt<ICategoryRepository>();
      final result = await repo.upsertCategory(cat);

      result.fold(
        (err) => ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(err))),
        (id) => Navigator.pop(context),
      );
    }
  }
}
