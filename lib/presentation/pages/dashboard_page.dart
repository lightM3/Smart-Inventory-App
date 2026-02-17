import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/providers/settings_provider.dart';
import '../../core/service_locator.dart';
import '../../core/utils/app_strings.dart';
import '../../core/utils/number_formatter.dart';
import '../../data/models/product_model.dart';
import '../../data/models/stock_movement_model.dart';
import '../../domain/repositories/i_auth_repository.dart';
import '../../domain/repositories/i_inventory_repository.dart';
import '../widgets/stat_card.dart';
import '../widgets/activity_tile.dart';
import 'product_details_page.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  final IInventoryRepository _repository = getIt<IInventoryRepository>();
  String _userName = '';

  late final Stream<List<Product>> _productsStream;
  late final Stream<List<Product>> _criticalProductsStream;
  late final Stream<List<StockMovement>> _recentMovementsStream;
  late final Stream<int> _movementCountStream;

  @override
  void initState() {
    super.initState();
    _loadUserProfile();

    _productsStream = _repository.watchAllProducts();
    _criticalProductsStream = _repository.watchCriticalProducts();
    _recentMovementsStream = _repository.watchRecentMovements(limit: 5);
    _movementCountStream = _repository.watchTotalMovementCount();
  }

  Future<void> _loadUserProfile() async {
    final authRepo = getIt<IAuthRepository>();
    final profileRes = await authRepo.getCurrentProfile();
    profileRes.fold((l) => null, (profile) {
      if (profile != null && mounted) {
        setState(() {
          _userName = profile.fullName ?? '';
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final lang = Provider.of<SettingsProvider>(context).languageCode;
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 80),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(context, lang),
            const SizedBox(height: 24),
            _buildStatsGrid(lang),
            const SizedBox(height: 24),
            _buildDailySummarySection(context, lang),
            const SizedBox(height: 24),
            _buildRecentActivitySection(lang),
          ],
        ),
      ),
    );
  }

  // Header - Karşılama + Bildirim Zili
  Widget _buildHeader(BuildContext context, String lang) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              AppStrings.get('dashboard_welcome', lang),
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).hintColor,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              _userName.isNotEmpty
                  ? AppStrings.get('dashboard_hello', lang)
                        .replaceAll('Yönetici', _userName)
                        .replaceAll('Admin', _userName)
                  : AppStrings.get('dashboard_hello', lang),
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
                fontSize: 24,
              ),
            ),
          ],
        ),
        // Bildirim zili + kırmızı nokta
        StreamBuilder<List<Product>>(
          stream: _criticalProductsStream,
          builder: (context, snapshot) {
            final hasCritical = snapshot.hasData && snapshot.data!.isNotEmpty;
            return GestureDetector(
              onTap: () {
                if (hasCritical) {
                  _showNotificationsBottomSheet(context, snapshot.data!, lang);
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        AppStrings.get('dashboard_all_stock_ok', lang),
                      ),
                      backgroundColor: AppColors.success,
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              },
              child: Stack(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Theme.of(context).cardColor,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Theme.of(
                            context,
                          ).shadowColor.withValues(alpha: 0.05),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Icon(
                      Icons.notifications_outlined,
                      color: Theme.of(context).textTheme.bodyMedium?.color,
                      size: 24,
                    ),
                  ),
                  if (hasCritical)
                    Positioned(
                      top: 6,
                      right: 6,
                      child: Container(
                        width: 10,
                        height: 10,
                        decoration: const BoxDecoration(
                          color: AppColors.critical,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildStatsGrid(String lang) {
    return RepaintBoundary(
      child: StreamBuilder<List<Product>>(
        stream: _productsStream,
        builder: (context, snapshot) {
          final products = snapshot.data ?? [];
          final totalItems = products.length;
          final criticalCount = products
              .where((p) => p.quantity < p.minStockLevel)
              .length;
          final totalQuantity = products
              .fold<double>(0, (sum, p) => sum + p.quantity)
              .toInt();

          return StreamBuilder<int>(
            stream: _movementCountStream,
            builder: (context, movementSnapshot) {
              final movementCount = movementSnapshot.data ?? 0;

              return GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: 1.1,
                children: [
                  StatCard(
                    icon: Icons.inventory_2,
                    iconColor: AppColors.blueIcon,
                    iconBgColor: AppColors.blueIconBg,
                    title: AppStrings.get('card_total_products', lang),
                    value: NumberFormatter.formatCount(totalItems),
                  ),
                  StatCard(
                    icon: Icons.warning_outlined,
                    iconColor: AppColors.redIcon,
                    iconBgColor: AppColors.redIconBg,
                    title: AppStrings.get('card_critical_stock', lang),
                    value: '$criticalCount',
                    valueColor: AppColors.critical,
                  ),
                  StatCard(
                    icon: Icons.diamond_outlined,
                    iconColor: AppColors.tealIcon,
                    iconBgColor: AppColors.tealIconBg,
                    title: AppStrings.get('card_total_quantity', lang),
                    value: NumberFormatter.formatCompact(totalQuantity),
                  ),
                  StatCard(
                    icon: Icons.receipt_long,
                    iconColor: AppColors.purpleIcon,
                    iconBgColor: AppColors.purpleIconBg,
                    title: AppStrings.get('card_transactions', lang),
                    value: '$movementCount',
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }

  // Günlük Aksiyon Özeti
  Widget _buildDailySummarySection(BuildContext context, String lang) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppStrings.get('dashboard_daily_summary', lang),
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        const SizedBox(height: 12),
        StreamBuilder<int>(
          stream: _movementCountStream,
          builder: (context, snapshot) {
            final now = DateTime.now();
            final startOfDay = DateTime(now.year, now.month, now.day);

            return FutureBuilder(
              future: Future.wait([
                _repository.getTotalInbound(since: startOfDay),
                _repository.getTotalOutbound(since: startOfDay),
              ]),
              builder: (ctx, AsyncSnapshot<List<dynamic>> asyncSnapshot) {
                int inbound = 0;
                int outbound = 0;

                if (asyncSnapshot.hasData) {
                  final inRes = asyncSnapshot.data![0];
                  final outRes = asyncSnapshot.data![1];
                  inbound = inRes.getOrElse((_) => 0);
                  outbound = outRes.getOrElse((_) => 0);
                }

                // Gösterilecek Mesaj
                final hasActivity = (inbound > 0 || outbound > 0);
                final String summaryText = hasActivity
                    ? AppStrings.get('summary_activity', lang)
                          .replaceAll('{in}', inbound.toString())
                          .replaceAll('{out}', outbound.toString())
                    : AppStrings.get('summary_no_activity', lang);

                final Color cardColor = Theme.of(context).cardColor;

                return Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: cardColor,
                    borderRadius: BorderRadius.circular(16),
                    border: hasActivity
                        ? null
                        : Border.all(color: Colors.grey.withValues(alpha: 0.2)),
                    boxShadow: [
                      BoxShadow(
                        color: Theme.of(
                          context,
                        ).shadowColor.withValues(alpha: 0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: hasActivity
                              ? AppColors.primary.withValues(alpha: 0.1)
                              : Colors.grey.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          hasActivity
                              ? Icons.auto_graph_rounded
                              : Icons.bedtime_outlined,
                          color: hasActivity ? AppColors.primary : Colors.grey,
                          size: 28,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Text(
                          summaryText,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: Theme.of(context).textTheme.bodyLarge?.color,
                            height: 1.4,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            );
          },
        ),
      ],
    );
  }

  // Son İşlemler
  Widget _buildRecentActivitySection(String lang) {
    return RepaintBoundary(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            AppStrings.get('dashboard_recent_activity', lang),
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
          const SizedBox(height: 16),
          Container(
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Theme.of(context).shadowColor.withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            padding: const EdgeInsets.all(16),
            child: StreamBuilder<List<StockMovement>>(
              stream: _recentMovementsStream,
              builder: (context, snapshot) {
                final movements = snapshot.data ?? [];
                if (movements.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Text(
                        AppStrings.get('dashboard_no_activity', lang),
                        style: TextStyle(
                          color: Theme.of(context).hintColor,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  );
                }
                return Column(
                  children: movements.map((m) {
                    final timeAgo = _formatTimeAgo(m.createdAt, lang);
                    final productTitle =
                        m.product.value?.title ??
                        AppStrings.get('deleted_product', lang);
                    return Column(
                      children: [
                        if (movements.indexOf(m) > 0) const Divider(height: 24),
                        ActivityTile(
                          productName: productTitle,
                          activityType: m.reason,
                          timeAgo: timeAgo,
                          quantityChange: m.type == MovementType.inbound
                              ? m.quantity.toInt()
                              : -m.quantity.toInt(),
                        ),
                      ],
                    );
                  }).toList(),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  String _formatTimeAgo(DateTime date, String lang) {
    final diff = DateTime.now().difference(date);
    if (diff.inMinutes < 1) return AppStrings.get('time_just_now', lang);
    if (diff.inMinutes < 60) {
      return '${diff.inMinutes} ${AppStrings.get('time_min_ago', lang)}';
    }
    if (diff.inHours < 24) {
      return '${diff.inHours} ${AppStrings.get('time_hour_ago', lang)}';
    }
    if (diff.inDays < 7) {
      return '${diff.inDays} ${AppStrings.get('time_day_ago', lang)}';
    }
    return '${date.day}/${date.month}/${date.year}';
  }

  void _showNotificationsBottomSheet(
    BuildContext context,
    List<Product> criticalProducts,
    String lang,
  ) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Row(
                  children: [
                    const Icon(
                      Icons.warning_rounded,
                      color: AppColors.critical,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      AppStrings.get('card_critical_stock', lang),
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.criticalBg,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${criticalProducts.length}',
                        style: const TextStyle(
                          color: AppColors.critical,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Flexible(
                child: ListView.separated(
                  shrinkWrap: true,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 8,
                  ),
                  itemCount: criticalProducts.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (ctx, index) {
                    final product = criticalProducts[index];
                    return Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Theme.of(context).cardColor,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: AppColors.critical.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: AppColors.criticalBg,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(
                              Icons.inventory_2_outlined,
                              color: AppColors.critical,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  product.title,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '${AppStrings.get('label_current_stock', lang)}: ${product.quantity.toInt()} / ${product.minStockLevel.toInt()}',
                                  style: TextStyle(
                                    color: Theme.of(context).hintColor,
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: const Icon(
                              Icons.arrow_forward_ios,
                              color: AppColors.primary,
                              size: 16,
                            ),
                            onPressed: () {
                              Navigator.pop(ctx);
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) =>
                                      ProductDetailsPage(product: product),
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
