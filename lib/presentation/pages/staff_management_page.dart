import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/providers/settings_provider.dart';
import '../../core/service_locator.dart';
import '../../core/utils/app_strings.dart';
import '../../domain/repositories/i_auth_repository.dart';
import '../../data/models/profile_model.dart';

class StaffManagementPage extends StatefulWidget {
  const StaffManagementPage({super.key});

  @override
  State<StaffManagementPage> createState() => _StaffManagementPageState();
}

class _StaffManagementPageState extends State<StaffManagementPage> {
  final _authRepo = getIt<IAuthRepository>();
  List<Profile> _staffList = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadStaff();
  }

  Future<void> _loadStaff() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final result = await _authRepo.getStaffList();
    if (mounted) {
      result.fold(
        (err) => setState(() {
          _errorMessage = err;
          _isLoading = false;
        }),
        (staff) => setState(() {
          _staffList = staff;
          _isLoading = false;
        }),
      );
    }
  }

  void _showAddStaffSheet(String lang) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _AddStaffBottomSheet(lang: lang),
    ).then((value) {
      if (value == true) {
        _loadStaff();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final settings = Provider.of<SettingsProvider>(context);
    final isDark = settings.isDarkMode;
    final lang = settings.languageCode;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF141422) : AppColors.background,
      appBar: AppBar(
        title: Text(AppStrings.get('page_manage_staff', lang)),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _loadStaff),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.error_outline,
                    size: 48,
                    color: AppColors.critical,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    _errorMessage!,
                    style: TextStyle(
                      color: isDark ? Colors.white : AppColors.textPrimary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _loadStaff,
                    child: Text(AppStrings.get('staff_retry', lang)),
                  ),
                ],
              ),
            )
          : _staffList.isEmpty
          ? Center(
              child: Text(
                AppStrings.get('staff_empty', lang),
                style: TextStyle(
                  color: isDark ? Colors.white70 : Colors.grey[600],
                ),
              ),
            )
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: _staffList.length,
              separatorBuilder: (context, index) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final profile = _staffList[index];
                return _buildStaffCard(profile, isDark, lang);
              },
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddStaffSheet(lang),
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.person_add, color: Colors.white),
        label: Text(
          AppStrings.get('staff_add_fab', lang),
          style: const TextStyle(color: Colors.white),
        ),
      ),
    );
  }

  Widget _buildStaffCard(Profile profile, bool isDark, String lang) {
    Color roleColor;
    String roleLabel;

    switch (profile.role) {
      case 'admin':
        roleColor = const Color(0xFF8E24AA);
        roleLabel = AppStrings.get('staff_role_admin', lang);
        break;
      case 'warehouse':
        roleColor = const Color(0xFF0288D1);
        roleLabel = AppStrings.get('staff_role_warehouse', lang);
        break;
      default:
        roleColor = const Color(0xFF43A047);
        roleLabel = AppStrings.get('staff_role_cashier', lang);
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E2C) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: roleColor.withValues(alpha: 0.1),
            radius: 24,
            child: Icon(Icons.person, color: roleColor, size: 28),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  profile.fullName ?? AppStrings.get('staff_unnamed', lang),
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  profile.email,
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: roleColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: roleColor.withValues(alpha: 0.3)),
            ),
            child: Text(
              roleLabel,
              style: TextStyle(
                color: roleColor,
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AddStaffBottomSheet extends StatefulWidget {
  final String lang;
  const _AddStaffBottomSheet({required this.lang});

  @override
  State<_AddStaffBottomSheet> createState() => _AddStaffBottomSheetState();
}

class _AddStaffBottomSheetState extends State<_AddStaffBottomSheet> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  String _selectedRole = 'cashier';
  bool _isSaving = false;

  final _authRepo = getIt<IAuthRepository>();

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _saveStaff() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);
    FocusScope.of(context).unfocus();

    final result = await _authRepo.createStaff(
      fullName: _nameController.text.trim(),
      email: _emailController.text.trim(),
      role: _selectedRole,
    );

    if (!mounted) return;
    setState(() => _isSaving = false);

    result.fold(
      (err) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(err), backgroundColor: AppColors.critical),
        );
      },
      (_) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppStrings.get('staff_created_msg', widget.lang)),
            backgroundColor: AppColors.success,
          ),
        );
        Navigator.pop(context, true);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final lang = widget.lang;

    return Container(
      margin: EdgeInsets.only(
        top: 40,
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E2C) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 24),
                  decoration: BoxDecoration(
                    color: Colors.grey[400],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Text(
                AppStrings.get('staff_add_title', lang),
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : AppColors.textPrimary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                AppStrings.get('staff_add_subtitle', lang),
                style: const TextStyle(
                  fontSize: 13,
                  color: AppColors.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: AppStrings.get('staff_label_name', lang),
                  prefixIcon: const Icon(Icons.person_outline),
                ),
                validator: (val) => (val == null || val.isEmpty)
                    ? AppStrings.get('staff_err_name', lang)
                    : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: InputDecoration(
                  labelText: AppStrings.get('staff_label_email', lang),
                  prefixIcon: const Icon(Icons.alternate_email),
                ),
                validator: (val) {
                  if (val == null || val.isEmpty) {
                    return AppStrings.get('staff_err_email_empty', lang);
                  }
                  if (!val.contains('@')) {
                    return AppStrings.get('staff_err_email_invalid', lang);
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),
              Text(
                AppStrings.get('staff_role_label', lang),
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: _buildRoleCard(
                      'cashier',
                      AppStrings.get('staff_role_cashier_label', lang),
                      Icons.point_of_sale,
                      isDark,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildRoleCard(
                      'warehouse',
                      AppStrings.get('staff_role_warehouse_label', lang),
                      Icons.inventory_2_outlined,
                      isDark,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: _isSaving ? null : _saveStaff,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isSaving
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : Text(
                        AppStrings.get('staff_save', lang),
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRoleCard(String role, String label, IconData icon, bool isDark) {
    final isSelected = _selectedRole == role;
    return GestureDetector(
      onTap: () => setState(() => _selectedRole = role),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primary.withValues(alpha: 0.1)
              : Colors.transparent,
          border: Border.all(
            color: isSelected
                ? AppColors.primary
                : (isDark ? Colors.white24 : Colors.grey[300]!),
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Icon(icon, color: isSelected ? AppColors.primary : Colors.grey),
            const SizedBox(height: 8),
            Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected
                    ? AppColors.primary
                    : (isDark ? Colors.white70 : AppColors.textPrimary),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
