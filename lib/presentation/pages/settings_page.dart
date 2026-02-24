import 'package:provider/provider.dart';
import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/providers/settings_provider.dart';
import 'categories_page.dart';
import '../../core/service_locator.dart';
import '../../core/utils/app_strings.dart';
import '../../core/utils/export_helper.dart';
import '../../data/models/product_model.dart';
import '../../domain/repositories/i_inventory_repository.dart';
import '../../domain/repositories/i_auth_repository.dart';
import '../../data/models/profile_model.dart';
import 'package:fpdart/fpdart.dart' as fp;
import 'staff_management_page.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = Provider.of<SettingsProvider>(context);
    final lang = settings.languageCode;
    final isDark = settings.isDarkMode;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF141422) : AppColors.background,
      appBar: AppBar(title: Text(AppStrings.get('profile_title', lang))),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // --- HEADER ---
            _buildProfileHeader(isDark, lang, getIt<IAuthRepository>()),
            const SizedBox(height: 32),

            // --- PREFERENCES ---
            _buildSectionHeader(
              AppStrings.get('section_preferences', lang),
              isDark,
            ),
            const SizedBox(height: 12),
            Container(
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E1E2C) : Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  _buildSwitchTile(
                    title: AppStrings.get('pref_dark_mode', lang),
                    icon: Icons.dark_mode_outlined,
                    iconBg: const Color(0xFFE8EAF6),
                    iconColor: const Color(0xFF3F51B5),
                    value: isDark,
                    onChanged: (val) => settings.toggleTheme(val),
                    isDark: isDark,
                  ),
                  _buildDivider(isDark),
                  _buildLanguageTile(context, settings, lang, isDark),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // --- DATA MANAGEMENT ---
            _buildSectionHeader(AppStrings.get('section_data', lang), isDark),
            const SizedBox(height: 12),
            Container(
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E1E2C) : Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  FutureBuilder<fp.Either<String, Profile?>>(
                    future: getIt<IAuthRepository>().getCurrentProfile(),
                    builder: (context, snapshot) {
                      final profile = snapshot.data?.fold(
                        (l) => null,
                        (r) => r,
                      );
                      if (profile?.role == 'admin') {
                        return Column(
                          children: [
                            _buildActionTile(
                              title: AppStrings.get('btn_manage_staff', lang),
                              icon: Icons.manage_accounts,
                              iconBg: const Color(0xFFE8EAF6),
                              iconColor: const Color(0xFF3F51B5),
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        const StaffManagementPage(),
                                  ),
                                );
                              },
                              isDark: isDark,
                            ),
                            _buildDivider(isDark),
                            _buildActionTile(
                              title: AppStrings.get('btn_clear_data', lang),
                              icon: Icons.delete_outline,
                              iconBg: const Color(0xFFFFEBEE),
                              iconColor: const Color(0xFFE53935),
                              isDestructive: true,
                              onTap: () => _confirmClearData(context, lang),
                              isDark: isDark,
                            ),
                            _buildDivider(isDark),
                          ],
                        );
                      }
                      return const SizedBox.shrink();
                    },
                  ),
                  _buildActionTile(
                    title: AppStrings.get('btn_manage_categories', lang),
                    icon: Icons.category_rounded,
                    iconBg: const Color(0xFFFFF3E0),
                    iconColor: const Color(0xFFFF9800),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const CategoriesPage(),
                        ),
                      );
                    },
                    isDark: isDark,
                  ),
                  _buildDivider(isDark),
                  _buildActionTile(
                    title: AppStrings.get('btn_export_csv', lang),
                    icon: Icons.download_outlined,
                    iconBg: const Color(0xFFE8F5E9),
                    iconColor: const Color(0xFF43A047),
                    onTap: () async {
                      try {
                        final repository = getIt<IInventoryRepository>();
                        final result = await repository.getAllProducts();
                        List<Product> products = [];
                        result.fold(
                          (err) => throw Exception(err),
                          (data) => products = data,
                        );

                        if (products.isEmpty) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  AppStrings.get('msg_no_data_export', lang),
                                ),
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                          }
                          return;
                        }
                        await ExportHelper.exportProductsToCsv(products);
                      } catch (e) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                '${AppStrings.get('msg_error_prefix', lang)}$e',
                              ),
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        }
                      }
                    },
                    isDark: isDark,
                  ),
                  _buildDivider(isDark),
                  _buildActionTile(
                    title: AppStrings.get('btn_export_pdf', lang),
                    icon: Icons.picture_as_pdf,
                    iconBg: const Color(
                      0xFFFFEBEE,
                    ), // Example color, adjust as needed
                    iconColor: const Color(
                      0xFFE53935,
                    ), // Example color, adjust as needed
                    onTap: () async {
                      try {
                        final repository = getIt<IInventoryRepository>();
                        final result = await repository.getAllProducts();
                        List<Product> products = [];
                        result.fold(
                          (err) => throw Exception(err),
                          (data) => products = data,
                        );

                        if (products.isEmpty) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  AppStrings.get('msg_no_data_export', lang),
                                ),
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                          }
                          return;
                        }
                        await ExportHelper.exportProductsToPdf(products);
                      } catch (e) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                '${AppStrings.get('msg_error_prefix', lang)}$e',
                              ),
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        }
                      }
                    },
                    isDark: isDark,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // --- ABOUT ---
            _buildSectionHeader(AppStrings.get('section_about', lang), isDark),
            const SizedBox(height: 12),
            Container(
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E1E2C) : Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  _buildInfoTile(
                    title: AppStrings.get('about_version', lang),
                    value: 'v1.0.0',
                    icon: Icons.info_outline,
                    iconBg: const Color(0xFFE1F5FE),
                    iconColor: const Color(0xFF039BE5),
                    isDark: isDark,
                  ),
                  _buildDivider(isDark),
                  _buildActionTile(
                    title: AppStrings.get('about_app', lang),
                    icon: Icons.help_outline,
                    iconBg: const Color(0xFFF3E5F5),
                    iconColor: const Color(0xFF8E24AA),
                    onTap: () {}, // Info page open
                    isDark: isDark,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'SmartInventory Enterprise Edition',
              style: TextStyle(color: Colors.grey[400], fontSize: 12),
            ),
            const SizedBox(height: 16),
            // --- LOGOUT ---
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: () async {
                  final result = await getIt<IAuthRepository>().logout();
                  if (context.mounted) {
                    result.fold(
                      (err) => ScaffoldMessenger.of(
                        context,
                      ).showSnackBar(SnackBar(content: Text(err))),
                      (_) {}, // StreamBuilder will automatically hide MainShell
                    );
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.critical,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),

                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.logout),
                    const SizedBox(width: 8),
                    Text(
                      AppStrings.get('btn_logout', lang),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 70),
          ],
        ),
      ),
    );
  }

  // --- WIDGETS ---

  Widget _buildProfileHeader(
    bool isDark,
    String lang,
    IAuthRepository authRepo,
  ) {
    return FutureBuilder<fp.Either<String, Profile?>>(
      future: authRepo.getCurrentProfile(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final profile = snapshot.data?.fold((l) => null, (r) => r);
        final name = profile?.fullName ?? 'Bilinmeyen Kullanıcı';
        final email = profile?.email ?? '---';
        String roleText = AppStrings.get('role_admin', lang);
        if (profile?.role == 'cashier') roleText = 'Kasiyer';
        if (profile?.role == 'warehouse') roleText = 'Depo';

        return Column(
          children: [
            Stack(
              children: [
                CircleAvatar(
                  radius: 50,
                  backgroundColor: const Color(0xFFFFE0B2),
                  child: Icon(
                    Icons.person,
                    size: 60,
                    color: Colors.orange[800],
                  ),
                ),
                Positioned(
                  bottom: 0,
                  right: 4,
                  child: Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color: AppColors.success,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isDark ? const Color(0xFF141422) : Colors.white,
                        width: 3,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              name,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.successBg,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    roleText.toUpperCase(),
                    style: const TextStyle(
                      color: AppColors.success,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  email,
                  style: TextStyle(color: Colors.grey[500], fontSize: 14),
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  Widget _buildSectionHeader(String title, bool isDark) {
    return Container(
      alignment: Alignment.centerLeft,
      child: Text(
        title,
        style: TextStyle(
          color: isDark ? const Color(0xFF7C8DB0) : const Color(0xFF5C6B90),
          fontSize: 13,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _buildSwitchTile({
    required String title,
    required IconData icon,
    required Color iconBg,
    required Color iconColor,
    required bool value,
    required Function(bool) onChanged,
    required bool isDark,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          _buildIconBox(icon, iconBg, iconColor),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              title,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: isDark ? Colors.white : AppColors.textPrimary,
              ),
            ),
          ),
          Switch.adaptive(
            value: value,
            onChanged: onChanged,
            activeTrackColor: AppColors.primary,
          ),
        ],
      ),
    );
  }

  Widget _buildLanguageTile(
    BuildContext context,
    SettingsProvider settings,
    String lang,
    bool isDark,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          _buildIconBox(
            Icons.language,
            const Color(0xFFE8EAF6),
            const Color(0xFF3949AB),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              AppStrings.get('pref_language', lang),
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: isDark ? Colors.white : AppColors.textPrimary,
              ),
            ),
          ),
          DropdownButton<String>(
            value: settings.languageCode,
            dropdownColor: isDark ? const Color(0xFF1E1E2C) : Colors.white,
            underline: const SizedBox(),
            items: [
              DropdownMenuItem(
                value: 'tr',
                child: Text(
                  'Türkçe',
                  style: TextStyle(
                    color: isDark ? Colors.white : AppColors.textPrimary,
                  ),
                ),
              ),
              DropdownMenuItem(
                value: 'en',
                child: Text(
                  'English',
                  style: TextStyle(
                    color: isDark ? Colors.white : AppColors.textPrimary,
                  ),
                ),
              ),
            ],
            onChanged: (val) {
              if (val != null) settings.changeLanguage(val);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildActionTile({
    required String title,
    required IconData icon,
    required Color iconBg,
    required Color iconColor,
    required VoidCallback onTap,
    bool isDestructive = false,
    required bool isDark,
  }) {
    return InkWell(
      onTap: onTap,
      splashColor: Colors.transparent,
      highlightColor: Colors.transparent,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        child: Row(
          children: [
            _buildIconBox(icon, iconBg, iconColor),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: isDestructive
                      ? AppColors.critical
                      : (isDark ? Colors.white : AppColors.textPrimary),
                ),
              ),
            ),
            Icon(Icons.chevron_right, color: Colors.grey[400], size: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoTile({
    required String title,
    required String value,
    required IconData icon,
    required Color iconBg,
    required Color iconColor,
    required bool isDark,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      child: Row(
        children: [
          _buildIconBox(icon, iconBg, iconColor),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              title,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: isDark ? Colors.white : AppColors.textPrimary,
              ),
            ),
          ),
          Text(value, style: TextStyle(fontSize: 14, color: Colors.grey[500])),
        ],
      ),
    );
  }

  Widget _buildDivider(bool isDark) {
    return Divider(
      height: 1,
      thickness: 1,
      color: isDark ? Colors.white10 : Colors.grey[100],
      indent: 68, // Icon width + spacing
    );
  }

  Widget _buildIconBox(IconData icon, Color bg, Color color) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(10),
      ),
      alignment: Alignment.center,
      child: Icon(icon, color: color, size: 22),
    );
  }

  // --- LOGIC ---

  Future<void> _confirmClearData(BuildContext context, String lang) async {
    String confirmationText = '';
    final requiredText = lang == 'tr' ? 'ONAYLIYORUM' : 'CONFIRM';

    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setState) {
          final isButtonEnabled = confirmationText == requiredText;

          return AlertDialog(
            title: Text(AppStrings.get('dialog_clear_title', lang)),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(AppStrings.get('dialog_clear_content', lang)),
                const SizedBox(height: 16),
                TextField(
                  onChanged: (value) {
                    setState(() {
                      confirmationText = value;
                    });
                  },
                  decoration: InputDecoration(
                    hintText: requiredText,
                    border: const OutlineInputBorder(),
                    focusedBorder: const OutlineInputBorder(
                      borderSide: BorderSide(color: AppColors.critical),
                    ),
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: Text(AppStrings.get('btn_cancel', lang)),
              ),
              ElevatedButton(
                onPressed: isButtonEnabled
                    ? () => Navigator.pop(ctx, true)
                    : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.critical,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: AppColors.critical.withValues(
                    alpha: 0.5,
                  ),
                ),
                child: Text(AppStrings.get('btn_confirm_delete', lang)),
              ),
            ],
          );
        },
      ),
    );

    if (confirmed == true && context.mounted) {
      final repository = getIt<IInventoryRepository>();
      await repository.clearAllData();

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppStrings.get('msg_data_cleared', lang)),
            backgroundColor: AppColors.primary,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }
}
