import 'dart:async';
import 'dart:io';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/service_locator.dart';
import '../../core/providers/settings_provider.dart';
import '../../core/utils/app_strings.dart';
import '../../data/models/report_models.dart';
import '../../domain/repositories/i_inventory_repository.dart';

// Sabit kategori renkleri — tutarlı görsel deneyim
const Map<String, Color> categoryColors = {
  // Türkçe
  'Elektronik': Color(0xFF5C6BC0),
  'Aksesuar': Color(0xFF26A69A),
  'Çevre Birimleri': Color(0xFFFF7043),
  'Depolama': Color(0xFF7E57C2),
  'Mobilya': Color(0xFF42A5F5),
  'Gıda': Color(0xFFEC407A),
  'Ofis Malzemeleri': Color(0xFFFFA726),
  'Hammadde': Color(0xFF8D6E63),
  'Diğer': Color(0xFF78909C),
  // Eski İngilizce kayıtlar için backward compat
  'Electronics': Color(0xFF5C6BC0),
  'Accessories': Color(0xFF26A69A),
  'Peripherals': Color(0xFFFF7043),
  'Storage': Color(0xFF7E57C2),
  'Furniture': Color(0xFF42A5F5),
  'Grocery': Color(0xFFEC407A),
  'Office Supplies': Color(0xFFFFA726),
  'Raw Materials': Color(0xFF8D6E63),
  'Other': Color(0xFF78909C),
};

Color _getCategoryColor(String category, int index) {
  return categoryColors[category] ??
      [
        const Color(0xFF5C6BC0),
        const Color(0xFF26A69A),
        const Color(0xFFFF7043),
        const Color(0xFF7E57C2),
        const Color(0xFF42A5F5),
        const Color(0xFFEC407A),
        const Color(0xFFFFA726),
        const Color(0xFF66BB6A),
      ][index % 8];
}

class ReportsPage extends StatefulWidget {
  const ReportsPage({super.key});

  @override
  State<ReportsPage> createState() => _ReportsPageState();
}

class _ReportsPageState extends State<ReportsPage> {
  final IInventoryRepository _repository = getIt<IInventoryRepository>();

  String _getLang() {
    return Provider.of<SettingsProvider>(
      context,
    ).languageCode; // listen: true by default
  }

  // Date Range: 7, 30, 90 gün
  int _selectedDays = 7;
  // _dateRanges moved to _buildDateRangeChips for localization

  // Data
  int _inbound = 0;
  int _outbound = 0;
  List<CategoryCount> _categories = [];
  List<DailyMovement> _dailyMovements = [];
  List<TopProduct> _topProducts = [];
  bool _isLoading = true;

  // Subscriptions for real-time updates
  final List<StreamSubscription> _subscriptions = [];

  @override
  void initState() {
    super.initState();
    // Hem ürünlerdeki hem de hareketlerdeki değişiklikleri dinle
    // Not: watch metodlarında fireImmediately: true olduğu için ilk yükleme otomatik yapılacak
    _subscriptions.add(
      _repository.watchAllProducts().listen((_) {
        _loadData();
      }),
    );
    _subscriptions.add(
      _repository.watchRecentMovements(limit: 1).listen((_) {
        _loadData();
      }),
    );
  }

  @override
  void dispose() {
    for (var sub in _subscriptions) {
      sub.cancel();
    }
    super.dispose();
  }

  Future<void> _loadData() async {
    // Avoid setting loading state if it's a background refresh
    if (_categories.isEmpty && mounted) {
      setState(() => _isLoading = true);
    }

    final since = DateTime.now().subtract(Duration(days: _selectedDays));

    final results = await Future.wait([
      _repository.getTotalInbound(since: since),
      _repository.getTotalOutbound(since: since),
      _repository.getCategoryDistribution(),
      _repository.getDailyMovements(
        days: _selectedDays > 14 ? 14 : _selectedDays,
      ),
      _repository.getTopMovingProducts(limit: 5),
    ]);

    int inboundData = 0;
    int outboundData = 0;
    List<CategoryCount> categoriesData = [];
    List<DailyMovement> dailyData = [];
    List<TopProduct> topData = [];

    results[0].fold((err) => null, (val) => inboundData = val as int);
    results[1].fold((err) => null, (val) => outboundData = val as int);
    results[2].fold(
      (err) => null,
      (val) => categoriesData = val as List<CategoryCount>,
    );
    results[3].fold(
      (err) => null,
      (val) => dailyData = val as List<DailyMovement>,
    );
    results[4].fold((err) => null, (val) => topData = val as List<TopProduct>);

    if (mounted) {
      setState(() {
        _inbound = inboundData;
        _outbound = outboundData;
        _categories = categoriesData;
        _dailyMovements = dailyData;
        _topProducts = topData;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildHeader(),
                    const SizedBox(height: 20),
                    _buildDateRangeChips(),
                    const SizedBox(height: 20),
                    _buildSummaryCards(),
                    const SizedBox(height: 24),
                    _buildCategoryPieChart(),
                    const SizedBox(height: 24),
                    _buildWeeklyBarChart(),
                    const SizedBox(height: 24),
                    _buildTopMovingProducts(),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
      ),
    );
  }

  // === HEADER ===
  Widget _buildHeader() {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: AppColors.primarySurface,
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(
            Icons.bar_chart_rounded,
            color: AppColors.primary,
            size: 24,
          ),
        ),
        const SizedBox(width: 12),
        Text(
          AppStrings.get('reports_title', _getLang()),
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Theme.of(context).textTheme.headlineMedium?.color,
          ),
        ),
      ],
    );
  }

  // === DATE RANGE CHIPS ===
  Widget _buildDateRangeChips() {
    final lang = _getLang();
    final dateRanges = [
      {'label': AppStrings.get('range_7_days', lang), 'days': 7},
      {'label': AppStrings.get('range_30_days', lang), 'days': 30},
      {'label': AppStrings.get('range_90_days', lang), 'days': 90},
    ];

    return SizedBox(
      height: 38,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: dateRanges.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final range = dateRanges[index];
          final isSelected = range['days'] == _selectedDays;
          return ChoiceChip(
            label: Text(
              range['label'] as String,
              style: TextStyle(
                color: isSelected
                    ? Colors.white
                    : Theme.of(context).textTheme.bodyMedium?.color,
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
            selected: isSelected,
            onSelected: (_) {
              setState(() => _selectedDays = range['days'] as int);
              _loadData();
            },
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
            padding: const EdgeInsets.symmetric(horizontal: 12),
          );
        },
      ),
    );
  }

  // === SUMMARY CARDS ===
  Widget _buildSummaryCards() {
    final hasData = _inbound > 0 || _outbound > 0;
    final total = _inbound + _outbound;
    final inPercent = total > 0 ? ((_inbound / total) * 100).round() : 0;
    final outPercent = total > 0 ? ((_outbound / total) * 100).round() : 0;
    final lang = _getLang();

    return Row(
      children: [
        Expanded(
          child: _summaryCard(
            icon: Icons.trending_up_rounded,
            iconBg: AppColors.successBg,
            iconColor: AppColors.success,
            label: AppStrings.get('label_inbound', lang),
            value: hasData ? _formatNumber(_inbound) : '—',
            percent: hasData ? '$inPercent%' : '',
            percentColor: AppColors.success,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _summaryCard(
            icon: Icons.trending_down_rounded,
            iconBg: AppColors.warningBg,
            iconColor: AppColors.warning,
            label: AppStrings.get('label_outbound', lang),
            value: hasData ? _formatNumber(_outbound) : '—',
            percent: hasData ? '$outPercent%' : '',
            percentColor: AppColors.critical,
          ),
        ),
      ],
    );
  }

  Widget _summaryCard({
    required IconData icon,
    required Color iconBg,
    required Color iconColor,
    required String label,
    required String value,
    required String percent,
    required Color percentColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).shadowColor.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Theme.of(context).brightness == Brightness.dark
                      ? iconColor.withValues(alpha: 0.15)
                      : iconBg,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: iconColor, size: 20),
              ),
              const Spacer(),
              if (percent.isNotEmpty)
                Text(
                  percent,
                  style: TextStyle(
                    color: percentColor,
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            value,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: Theme.of(context).hintColor,
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            AppStrings.get('label_units_period', _getLang()),
            style: TextStyle(fontSize: 11, color: Theme.of(context).hintColor),
          ),
        ],
      ),
    );
  }

  // === CATEGORY PIE CHART ===
  Widget _buildCategoryPieChart() {
    final lang = _getLang();
    return RepaintBoundary(
      child: _buildSection(
        title: AppStrings.get('chart_category_dist', lang),
        child: _categories.isEmpty
            ? _emptyPlaceholder(AppStrings.get('empty_category_chart', lang))
            : SizedBox(
                height: 200,
                child: Row(
                  children: [
                    // Pie Chart
                    SizedBox(
                      width: 140,
                      height: 140,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          PieChart(
                            PieChartData(
                              sections: _categories.asMap().entries.map((e) {
                                final i = e.key;
                                final c = e.value;
                                return PieChartSectionData(
                                  value: c.totalQuantity.toDouble(),
                                  color: _getCategoryColor(c.category, i),
                                  radius: 22,
                                  showTitle: false,
                                );
                              }).toList(),
                              sectionsSpace: 2,
                              centerSpaceRadius: 44,
                            ),
                          ),
                          Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                AppStrings.get('label_total', lang),
                                style: TextStyle(
                                  fontSize: 9,
                                  fontWeight: FontWeight.w700,
                                  color: Theme.of(context).hintColor,
                                  letterSpacing: 0.5,
                                ),
                              ),
                              Text(
                                _formatNumber(
                                  _categories.fold<int>(
                                    0,
                                    (sum, item) => sum + item.totalQuantity,
                                  ),
                                ),
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.primary,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 24),
                    // Legend
                    Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: _categories.asMap().entries.map((e) {
                          final i = e.key;
                          final c = e.value;
                          final total = _categories.fold<int>(
                            0,
                            (sum, item) => sum + item.totalQuantity,
                          );
                          final pct = total > 0
                              ? ((c.totalQuantity / total) * 100).round()
                              : 0;
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 5),
                            child: Row(
                              children: [
                                Container(
                                  width: 10,
                                  height: 10,
                                  decoration: BoxDecoration(
                                    color: _getCategoryColor(c.category, i),
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        c.category,
                                        style: TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w500,
                                          color: Theme.of(
                                            context,
                                          ).textTheme.bodyMedium?.color,
                                        ),
                                      ),
                                      Text(
                                        '${_formatNumber(c.totalQuantity)} ${AppStrings.get('unit_items', lang)} (${c.productCount} ${AppStrings.get('unit_types', lang)})',
                                        style: TextStyle(
                                          fontSize: 10,
                                          color: Theme.of(context).hintColor,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Text(
                                  '$pct%',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                    color: Theme.of(
                                      context,
                                    ).textTheme.bodyMedium?.color,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }

  // === WEEKLY BAR CHART ===
  Widget _buildWeeklyBarChart() {
    final hasData = _dailyMovements.any((d) => d.totalIn > 0 || d.totalOut > 0);
    final lang = _getLang();

    return RepaintBoundary(
      child: _buildSection(
        title: AppStrings.get('chart_weekly_movements', lang),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _legendDot(AppColors.primary, AppStrings.get('legend_in', lang)),
            const SizedBox(width: 12),
            _legendDot(
              const Color(0xFFFF7043),
              AppStrings.get('legend_out', lang),
            ),
          ],
        ),
        child: !hasData
            ? _emptyPlaceholder(AppStrings.get('empty_weekly_chart', lang))
            : SizedBox(
                height: 200,
                child: BarChart(
                  BarChartData(
                    alignment: BarChartAlignment.spaceAround,
                    maxY: _calcMaxY(),
                    barTouchData: BarTouchData(
                      touchTooltipData: BarTouchTooltipData(
                        getTooltipItem: (group, groupIndex, rod, rodIndex) {
                          final label = rodIndex == 0
                              ? AppStrings.get('legend_in', lang)
                              : AppStrings.get('legend_out', lang);
                          return BarTooltipItem(
                            '$label: ${rod.toY.toInt()}',
                            const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                              fontSize: 12,
                            ),
                          );
                        },
                      ),
                    ),
                    titlesData: FlTitlesData(
                      leftTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                      rightTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                      topTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          getTitlesWidget: (value, meta) {
                            final index = value.toInt();
                            if (index < 0 || index >= _dailyMovements.length) {
                              return const SizedBox.shrink();
                            }
                            final day = _dailyMovements[index].date;
                            return Padding(
                              padding: const EdgeInsets.only(top: 8),
                              child: Text(
                                DateFormat('E').format(day).substring(0, 3),
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Theme.of(context).hintColor,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            );
                          },
                          reservedSize: 28,
                        ),
                      ),
                    ),
                    gridData: FlGridData(
                      show: true,
                      drawVerticalLine: false,
                      horizontalInterval: _calcMaxY() / 4,
                      getDrawingHorizontalLine: (value) => FlLine(
                        color: Theme.of(context).brightness == Brightness.dark
                            ? Theme.of(
                                context,
                              ).dividerColor.withValues(alpha: 0.15)
                            : Theme.of(
                                context,
                              ).dividerColor.withValues(alpha: 0.1),
                        strokeWidth: 1,
                      ),
                    ),
                    borderData: FlBorderData(show: false),
                    barGroups: _dailyMovements.asMap().entries.map((e) {
                      final i = e.key;
                      final d = e.value;
                      return BarChartGroupData(
                        x: i,
                        barRods: [
                          BarChartRodData(
                            toY: d.totalIn.toDouble(),
                            color: AppColors.primary,
                            width: 10,
                            borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(4),
                            ),
                          ),
                          BarChartRodData(
                            toY: d.totalOut.toDouble(),
                            color: const Color(0xFFFF7043),
                            width: 10,
                            borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(4),
                            ),
                          ),
                        ],
                        barsSpace: 3,
                      );
                    }).toList(),
                  ),
                ),
              ),
      ),
    );
  }

  double _calcMaxY() {
    double max = 10;
    for (final d in _dailyMovements) {
      if (d.totalIn > max) max = d.totalIn.toDouble();
      if (d.totalOut > max) max = d.totalOut.toDouble();
    }
    return max * 1.2;
  }

  // === TOP MOVING PRODUCTS ===
  Widget _buildTopMovingProducts() {
    final lang = _getLang();
    return RepaintBoundary(
      child: _buildSection(
        title: AppStrings.get('chart_top_products', lang),
        child: _topProducts.isEmpty
            ? _emptyPlaceholder(AppStrings.get('empty_top_products', lang))
            : Column(
                children: _topProducts.asMap().entries.map((e) {
                  final i = e.key;
                  final p = e.value;
                  final hasImage =
                      p.productImagePath != null &&
                      File(p.productImagePath!).existsSync();
                  return Column(
                    children: [
                      if (i > 0) const Divider(height: 20),
                      Row(
                        children: [
                          // Ürün görseli
                          hasImage
                              ? CircleAvatar(
                                  radius: 22,
                                  backgroundImage: ResizeImage(
                                    FileImage(File(p.productImagePath!)),
                                    width: 150,
                                  ),
                                )
                              : CircleAvatar(
                                  radius: 22,
                                  backgroundColor: AppColors.primarySurface,
                                  child: const Icon(
                                    Icons.inventory_2,
                                    color: AppColors.primary,
                                    size: 20,
                                  ),
                                ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  p.productTitle,
                                  style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 14,
                                    color: Theme.of(
                                      context,
                                    ).textTheme.bodyMedium?.color,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                if (p.productBarcode != null)
                                  Text(
                                    'SKU: ${p.productBarcode}',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: Theme.of(context).hintColor,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                '${p.movementCount} ${AppStrings.get('unit_units', lang)}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                  color: AppColors.primary,
                                ),
                              ),
                              Text(
                                AppStrings.get('label_high_activity', lang),
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Theme.of(context).hintColor,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  );
                }).toList(),
              ),
      ),
    );
  }

  // === ORTAK WIDGET'LAR ===

  Widget _buildSection({
    required String title,
    required Widget child,
    Widget? trailing,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).shadowColor.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (trailing != null) trailing,
            ],
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }

  Widget _emptyPlaceholder(String message) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 40),
      child: Column(
        children: [
          Icon(
            Icons.analytics_outlined,
            size: 48,
            color: Theme.of(context).disabledColor,
          ),
          const SizedBox(height: 12),
          Text(
            message,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              color: Theme.of(context).hintColor,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _legendDot(Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(fontSize: 12, color: Theme.of(context).hintColor),
        ),
      ],
    );
  }

  String _formatNumber(int n) {
    if (n >= 1000) {
      return '${(n / 1000).toStringAsFixed(1)}k';
    }
    return n.toString();
  }
}
