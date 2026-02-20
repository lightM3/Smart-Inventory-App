import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/service_locator.dart';
import '../../core/providers/settings_provider.dart';
import '../../core/utils/app_strings.dart';
import '../../domain/repositories/i_category_repository.dart';
import '../../data/models/category_model.dart';
import '../widgets/add_edit_category_sheet.dart';

class CategoriesPage extends StatelessWidget {
  const CategoriesPage({super.key});

  @override
  Widget build(BuildContext context) {
    final categoryRepo = getIt<ICategoryRepository>();
    final lang = Provider.of<SettingsProvider>(context).languageCode;

    return Scaffold(
      appBar: AppBar(
        title: Text(AppStrings.get('page_manage_categories', lang)),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _showAddCategorySheet(context),
          ),
        ],
      ),
      body: StreamBuilder<List<Category>>(
        stream: categoryRepo.watchAllCategories(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Text(
                '${AppStrings.get('categories_error', lang)}: ${snapshot.error}',
              ),
            );
          }

          final categories = snapshot.data ?? [];

          if (categories.isEmpty) {
            return Center(
              child: Text(
                AppStrings.get('categories_empty', lang),
                textAlign: TextAlign.center,
              ),
            );
          }

          return ListView.builder(
            itemCount: categories.length,
            padding: const EdgeInsets.all(16),
            itemBuilder: (context, index) {
              final cat = categories[index];
              return Card(
                elevation: 0,
                color: Theme.of(context).cardColor,
                margin: const EdgeInsets.only(bottom: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(
                    color: Theme.of(
                      context,
                    ).dividerColor.withValues(alpha: 0.5),
                  ),
                ),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: Color(
                      int.parse(cat.colorHex.replaceAll('#', '0xFF')),
                    ),
                    child: Icon(
                      IconData(cat.iconCodePoint, fontFamily: 'MaterialIcons'),
                      color: Colors.white,
                    ),
                  ),
                  title: Text(
                    cat.name,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit, color: Colors.blue),
                        onPressed: () =>
                            _showAddCategorySheet(context, category: cat),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () =>
                            _confirmDelete(context, cat, categoryRepo, lang),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  void _showAddCategorySheet(BuildContext context, {Category? category}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: AddEditCategorySheet(category: category),
      ),
    );
  }

  Future<void> _confirmDelete(
    BuildContext context,
    Category category,
    ICategoryRepository repo,
    String lang,
  ) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(AppStrings.get('dialog_delete_category_title', lang)),
        content: Text(
          '"${category.name}" ${AppStrings.get('dialog_delete_category_content', lang)}',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(AppStrings.get('btn_cancel', lang)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(
              AppStrings.get('btn_confirm_delete', lang),
              style: const TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final ext = await repo.deleteCategory(category.id);
      ext.fold(
        (err) => ScaffoldMessenger.of(
          // ignore: use_build_context_synchronously
          context,
        ).showSnackBar(SnackBar(content: Text(err))),
        (res) => null,
      );
    }
  }
}
