import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/service_locator.dart';
import '../../core/providers/settings_provider.dart';
import '../../core/utils/app_strings.dart';
import '../../domain/repositories/i_inventory_repository.dart';
import 'add_edit_product_page.dart';
import 'dashboard_page.dart';
import 'inventory_page.dart';
import 'reports_page.dart';
import 'scanner_page.dart';
import 'settings_page.dart';
import 'product_details_page.dart';

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _currentIndex = 0;

  final List<Widget> _pages = [
    const DashboardPage(),
    const InventoryPage(),
    const ReportsPage(),
    const SettingsPage(),
  ];

  Future<void> _openScanner() async {
    final code = await Navigator.push<String>(
      context,
      MaterialPageRoute(builder: (_) => const ScannerPage()),
    );
    if (code != null && mounted) {
      final repository = getIt<IInventoryRepository>();
      final result = await repository.getProductByBarcode(code);

      if (mounted) {
        result.fold(
          (err) {
            // Hata durumu, opsiyonel olarak snackbar gösterilebilir
          },
          (existing) {
            if (existing != null) {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ProductDetailsPage(product: existing),
                ),
              );
            } else {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => AddEditProductPage(barcode: code),
                ),
              );
            }
          },
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _currentIndex, children: _pages),
      extendBody: true,
      floatingActionButton: AnimatedScale(
        scale: _currentIndex == 1 ? 1.0 : 0.0,
        duration: const Duration(milliseconds: 800),
        curve: Curves.easeOutBack,
        child: FloatingActionButton(
          backgroundColor: AppColors.primary,
          onPressed: _openScanner,
          shape: const CircleBorder(),
          elevation: 8,
          child: const Icon(
            Icons.qr_code_scanner,
            color: Colors.white,
            size: 28,
          ),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: AnimatedContainer(
        duration: const Duration(milliseconds: 850),
        height: 85.0,
        child: BottomAppBar(
          shape: _currentIndex == 1 ? const CircularNotchedRectangle() : null,
          notchMargin: _currentIndex == 1 ? 8.0 : 0.0,
          color:
              Theme.of(context).bottomAppBarTheme.color ??
              Theme.of(context).cardColor,
          elevation: 20,
          clipBehavior: Clip.antiAlias,
          padding: EdgeInsets.zero,
          child: Row(
            children: [
              Expanded(
                child: _buildNavItem(
                  Icons.home_outlined,
                  Icons.home,
                  AppStrings.get('nav_home', _getLang(context)),
                  0,
                ),
              ),
              Expanded(
                child: _buildNavItem(
                  Icons.inventory_2_outlined,
                  Icons.inventory_2,
                  AppStrings.get('nav_inventory', _getLang(context)),
                  1,
                ),
              ),

              AnimatedSize(
                duration: const Duration(milliseconds: 600),
                curve: Curves.easeInOutCubic,
                child: SizedBox(width: _currentIndex == 1 ? 92.0 : 0.0),
              ),

              Expanded(
                child: _buildNavItem(
                  Icons.bar_chart_outlined,
                  Icons.bar_chart,
                  AppStrings.get('nav_reports', _getLang(context)),
                  2,
                ),
              ),
              Expanded(
                child: _buildNavItem(
                  Icons.settings_outlined,
                  Icons.settings,
                  AppStrings.get('nav_settings', _getLang(context)),
                  3,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _getLang(BuildContext context) {
    return Provider.of<SettingsProvider>(context).languageCode;
  }

  Widget _buildNavItem(
    IconData icon,
    IconData activeIcon,
    String label,
    int index,
  ) {
    final isSelected = _currentIndex == index;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {
        setState(() {
          _currentIndex = index;
        });
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            transitionBuilder: (child, anim) =>
                ScaleTransition(scale: anim, child: child),
            child: Icon(
              isSelected ? activeIcon : icon,
              key: ValueKey<bool>(isSelected),
              color: isSelected ? AppColors.primary : AppColors.textSecondary,
              size: 24,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              color: isSelected ? AppColors.primary : AppColors.textSecondary,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }
}
