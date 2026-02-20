import 'package:flutter/material.dart';
import 'package:isar/isar.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/service_locator.dart';
import '../../core/providers/settings_provider.dart';
import '../../core/utils/app_strings.dart';
import '../../data/models/product_model.dart';
import '../../domain/repositories/i_inventory_repository.dart';
import '../widgets/product_list_tile.dart';
import '../widgets/empty_state_widget.dart';
import 'product_details_page.dart';

class InventoryPage extends StatefulWidget {
  const InventoryPage({super.key});

  @override
  State<InventoryPage> createState() => _InventoryPageState();
}

class _InventoryPageState extends State<InventoryPage> {
  final IInventoryRepository _repository = getIt<IInventoryRepository>();
  final TextEditingController _searchController = TextEditingController();

  String _searchQuery = '';
  String _selectedCategory = '';
  String _sortBy = 'Name';
  bool _sortAscending = true; // Artan = true, Azalan = false

  late final Stream<List<Product>> _productsStream;

  @override
  void initState() {
    super.initState();
    _productsStream = _repository.watchAllProducts();
    // Dile göre doğru 'Tümü' / 'All' değerini alıyoruz.
    // (Context initState'de güvenle okunabilir)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        final lang = Provider.of<SettingsProvider>(
          context,
          listen: false,
        ).languageCode;
        setState(() => _selectedCategory = AppStrings.get('filter_all', lang));
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // Filtreleme ve sıralama mantığı
  //Drift'ten watchAllProducts() ile tüm ürünler alınıyor, sonra _filterAndSort() ile UI tarafında filtreleniyor.
  //kullanıcı her harf yazdığında yeni bir DB sorgusu atmak yerine, bellekteki listeyi anlık filtrelemek çok daha hızlı.

  String _getLang() {
    return Provider.of<SettingsProvider>(context, listen: false).languageCode;
  }

  List<Product> _filterAndSort(List<Product> allProducts) {
    var filtered = List<Product>.from(allProducts);
    final lang = _getLang();

    // Arama filtresi
    if (_searchQuery.isNotEmpty) {
      final query = _searchQuery.toLowerCase();
      filtered = filtered
          .where(
            (p) =>
                p.title.toLowerCase().contains(query) ||
                (p.barcode?.toLowerCase().contains(query) ?? false),
          )
          .toList();
    }

    // Kategori filtresi
    if (_selectedCategory != AppStrings.get('filter_all', lang)) {
      filtered = filtered
          .where((p) => p.category == _selectedCategory)
          .toList();
    }

    // Sıralama
    switch (_sortBy) {
      case 'Name':
        filtered.sort((a, b) => a.title.compareTo(b.title));
        break;
      case 'Quantity':
        filtered.sort((a, b) => a.quantity.compareTo(b.quantity));
        break;
      case 'Category':
        filtered.sort((a, b) => a.category.compareTo(b.category));
        break;
    }
    if (!_sortAscending) filtered = filtered.reversed.toList();

    return filtered;
  }

  String _sortDisplayName(String key) {
    final lang = _getLang();
    switch (key) {
      case 'Name':
        return AppStrings.get('sort_name', lang);
      case 'Quantity':
        return AppStrings.get('sort_quantity', lang);
      case 'Category':
        return AppStrings.get('sort_category', lang);
      default:
        return key;
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Product>>(
      stream: _productsStream,
      builder: (context, snapshot) {
        final allProducts = snapshot.data ?? [];
        final lang = Provider.of<SettingsProvider>(context).languageCode;
        final filteredProducts = _filterAndSort(allProducts);

        final categories = [
          AppStrings.get('filter_all', lang),
          ...allProducts.map((p) => p.category).toSet(),
        ];

        return Stack(
          children: [
            CustomScrollView(
              slivers: [
                // Sayfa başlığı
                SliverToBoxAdapter(
                  child: SafeArea(
                    bottom: false,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                      child: Center(
                        child: Text(
                          AppStrings.get('app_title', lang),
                          style: Theme.of(context).textTheme.titleLarge
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ),
                ),
                // Sticky Search + Filter
                SliverAppBar(
                  pinned: true,
                  floating: true,
                  snap: true,
                  backgroundColor: Theme.of(context).scaffoldBackgroundColor,
                  surfaceTintColor: Theme.of(context).scaffoldBackgroundColor,
                  elevation: 0,
                  toolbarHeight: 0,
                  bottom: PreferredSize(
                    preferredSize: const Size.fromHeight(112),
                    child: Column(
                      children: [
                        // Arama çubuğu
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: TextField(
                            controller: _searchController,
                            onChanged: (value) =>
                                setState(() => _searchQuery = value),
                            decoration: InputDecoration(
                              hintText: AppStrings.get(
                                'hint_search_scan',
                                lang,
                              ),
                              hintStyle: TextStyle(
                                color: Theme.of(context).hintColor,
                                fontSize: 14,
                              ),
                              prefixIcon: Icon(
                                Icons.search,
                                color: Theme.of(
                                  context,
                                ).iconTheme.color?.withValues(alpha: 0.5),
                              ),

                              filled: true,
                              fillColor: Theme.of(context).cardColor,
                              contentPadding: const EdgeInsets.symmetric(
                                vertical: 12,
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide.none,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        // Kategori çipleri
                        SizedBox(
                          height: 40,
                          child: ListView.separated(
                            scrollDirection: Axis.horizontal,
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            itemCount: categories.length,
                            separatorBuilder: (_, __) =>
                                const SizedBox(width: 8),
                            itemBuilder: (context, index) {
                              final cat = categories.elementAt(index);
                              final isSelected = cat == _selectedCategory;
                              return FilterChip(
                                label: Text(
                                  cat,
                                  style: TextStyle(
                                    color: isSelected
                                        ? Colors.white
                                        : Theme.of(
                                            context,
                                          ).textTheme.bodyMedium?.color,
                                    fontWeight: FontWeight.w500,
                                    fontSize: 13,
                                  ),
                                ),
                                selected: isSelected,
                                onSelected: (_) =>
                                    setState(() => _selectedCategory = cat),
                                selectedColor: AppColors.primary,
                                backgroundColor: Theme.of(context).cardColor,
                                side: BorderSide(
                                  color: isSelected
                                      ? AppColors.primary
                                      : Theme.of(context).dividerColor,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                showCheckmark: false,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                ),
                              );
                            },
                          ),
                        ),
                        const SizedBox(height: 8),
                      ],
                    ),
                  ),
                ),

                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '${filteredProducts.length} ${AppStrings.get('label_showing_items', lang)}',
                          style: Theme.of(context).textTheme.labelSmall
                              ?.copyWith(
                                fontWeight: FontWeight.w600,
                                letterSpacing: 0.5,
                                color: Theme.of(context).hintColor,
                              ),
                        ),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            PopupMenuButton<String>(
                              onSelected: (value) =>
                                  setState(() => _sortBy = value),
                              offset: const Offset(0, 36),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    '${AppStrings.get('label_sort', lang)}: ${_sortDisplayName(_sortBy)}',
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodyMedium
                                        ?.copyWith(fontWeight: FontWeight.w500),
                                  ),
                                  const Icon(Icons.arrow_drop_down, size: 20),
                                ],
                              ),
                              itemBuilder: (_) => [
                                PopupMenuItem(
                                  value: 'Name',
                                  child: Text(
                                    AppStrings.get('sort_name', lang),
                                  ),
                                ),
                                PopupMenuItem(
                                  value: 'Quantity',
                                  child: Text(
                                    AppStrings.get('sort_quantity', lang),
                                  ),
                                ),
                                PopupMenuItem(
                                  value: 'Category',
                                  child: Text(
                                    AppStrings.get('sort_category', lang),
                                  ),
                                ),
                              ],
                            ),
                            // Yön değiştirme butonu
                            GestureDetector(
                              onTap: () => setState(
                                () => _sortAscending = !_sortAscending,
                              ),
                              child: Padding(
                                padding: const EdgeInsets.only(left: 4),
                                child: AnimatedRotation(
                                  turns: _sortAscending ? 0 : 0.5,
                                  duration: const Duration(milliseconds: 250),
                                  child: Icon(
                                    Icons.keyboard_double_arrow_up,
                                    size: 20,
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.primary,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

                if (snapshot.connectionState == ConnectionState.waiting)
                  const SliverFillRemaining(
                    child: Center(child: CircularProgressIndicator()),
                  )
                else if (allProducts.isEmpty)
                  SliverFillRemaining(
                    child: EmptyStateWidget(
                      icon: Icons.inventory_2_outlined,
                      title: AppStrings.get('empty_inventory_title', lang),
                      subtitle: AppStrings.get(
                        'empty_inventory_subtitle',
                        lang,
                      ),
                    ),
                  )
                else if (filteredProducts.isEmpty)
                  SliverFillRemaining(
                    child: EmptyStateWidget(
                      icon: Icons.search_off,
                      title: AppStrings.get('empty_search_title', lang),
                      subtitle: AppStrings.get('empty_search_subtitle', lang),
                    ),
                  )
                else
                  SliverList(
                    delegate: SliverChildBuilderDelegate((context, index) {
                      final product = filteredProducts[index];
                      return RepaintBoundary(
                        child: ProductListTile(
                          product: product,
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) =>
                                    ProductDetailsPage(product: product),
                              ),
                            );
                          },
                          onDelete: () async {
                            final scaffoldMessenger = ScaffoldMessenger.of(
                              context,
                            );
                            await _repository.deleteProduct(product.id);
                            if (mounted) {
                              scaffoldMessenger.hideCurrentSnackBar();
                              scaffoldMessenger.showSnackBar(
                                SnackBar(
                                  content: Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          '${product.title} ${AppStrings.get('msg_deleted', lang)}',
                                        ),
                                      ),
                                      TextButton(
                                        onPressed: () async {
                                          scaffoldMessenger
                                              .hideCurrentSnackBar();
                                          final newProduct = product.copyWith();
                                          newProduct.id = Isar.autoIncrement;
                                          await _repository.upsertProduct(
                                            newProduct,
                                          );
                                        },
                                        style: TextButton.styleFrom(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 8,
                                          ),
                                          minimumSize: Size.zero,
                                          tapTargetSize:
                                              MaterialTapTargetSize.shrinkWrap,
                                          foregroundColor: AppColors.primary,
                                        ),
                                        child: Text(
                                          AppStrings.get('btn_undo', lang),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      IconButton(
                                        icon: const Icon(
                                          Icons.close,
                                          color: AppColors.primary,
                                          size: 20,
                                        ),
                                        padding: EdgeInsets.zero,
                                        constraints: const BoxConstraints(),
                                        onPressed: () {
                                          scaffoldMessenger
                                              .hideCurrentSnackBar();
                                        },
                                      ),
                                    ],
                                  ),
                                  behavior: SnackBarBehavior.floating,
                                  duration: const Duration(
                                    days: 365,
                                  ), // Kullanıcı kapatana kadar kalır
                                ),
                              );
                            }
                          },
                        ),
                      );
                    }, childCount: filteredProducts.length),
                  ),

                const SliverPadding(padding: EdgeInsets.only(bottom: 80)),
              ],
            ),
          ],
        );
      },
    );
  }
}
