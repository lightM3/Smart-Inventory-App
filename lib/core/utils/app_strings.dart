class AppStrings {
  static const Map<String, Map<String, String>> _localizedValues = {
    'tr': {
      // Nav & Titles
      'nav_home': 'Ana Sayfa',
      'nav_inventory': 'Envanter',
      'nav_reports': 'Raporlar',
      'nav_settings': 'Ayarlar',
      'app_title': 'SmartInventory',

      // Auth (Login)
      'login_title': 'Hoş Geldiniz',
      'login_subtitle': 'Sisteme erişmek için giriş yapın.',
      'label_email': 'E-posta Adresi',
      'hint_email': 'ornek@sirket.com',
      'err_email_invalid': 'Geçerli bir e-posta girin.',
      'label_password': 'Şifre',
      'hint_password': '••••••••',
      'err_password_short': 'Şifre en az 6 karakter olmalıdır.',
      'btn_login': 'Giriş Yap',

      // Settings Page
      'profile_title': 'Profil',
      'role_admin': 'Yönetici',
      'status_active': 'AKTİF',
      'section_preferences': 'TERCİHLER',
      'pref_dark_mode': 'Karanlık Mod',
      'pref_language': 'Dil / Language',
      'section_data': 'VERİ YÖNETİMİ',
      'btn_export_csv': 'CSV Olarak Dışa Aktar',
      'btn_export_pdf': 'PDF Olarak Dışa Aktar',
      'btn_manage_staff': 'Personelleri Yönet',
      'btn_manage_categories': 'Kategorileri Yönet',
      'btn_clear_data': 'Tüm Ürünleri Sıfırla',
      'dialog_clear_title': 'Tüm Ürünleri Sıfırla',
      'dialog_clear_content':
          'Bu işlem kayıtlı tüm ürünleri ve stok hareketlerini geri dönülemez şekilde silecektir. Kategorileriniz silinmeyecektir.\n\nDevam etmek için aşağıdaki alana "ONAYLIYORUM" yazın.',
      'section_security': 'GÜVENLİK',
      'pref_biometric': 'Biyometrik Kilit',
      'section_about': 'HAKKINDA',
      'about_version': 'Uygulama Sürümü',
      'about_app': 'SmartInventory Hakkında',
      'btn_logout': 'Çıkış Yap',
      'btn_cancel': 'İptal',
      'btn_confirm_delete': 'Sil',
      'msg_export_success': 'Dosya hazırlandı',

      // Categories Page
      'page_manage_categories': 'Kategorileri Yönet',
      'categories_empty':
          'Henüz kategori eklemediniz.\nSağ üstten "+" butonuna tıklayarak başlayın.',
      'categories_error': 'Bir hata oluştu',
      'dialog_delete_category_title': 'Silmeyi Onayla',
      'dialog_delete_category_content':
          'kategorisini silmek istediğinize emin misiniz?\n\n(Bu kategoriye sahip ürünlerin kategorisi "Genel" olarak güncellenir)',

      // Staff Management Page
      'page_manage_staff': 'Personel Yönetimi',
      'staff_retry': 'Tekrar Dene',
      'staff_empty': 'Henüz başka personel yok.',
      'staff_add_fab': 'Personel Ekle',
      'staff_role_admin': 'YÖNETİCİ',
      'staff_role_warehouse': 'DEPO',
      'staff_role_cashier': 'KASİYER',
      'staff_unnamed': 'İsimsiz Personel',
      'staff_add_title': 'Yeni Personel Ekle',
      'staff_add_subtitle':
          'Personelin şifresi otomatik olarak "123456" tanımlanacaktır.',
      'staff_label_name': 'Ad Soyad',
      'staff_err_name': 'Ad soyad zorunludur',
      'staff_label_email': 'E-posta',
      'staff_err_email_empty': 'E-posta zorunludur',
      'staff_err_email_invalid': 'Geçerli bir e-posta girin',
      'staff_role_label': 'Yetki Türü',
      'staff_role_cashier_label': 'Kasiyer',
      'staff_role_warehouse_label': 'Depo\nGörevlisi',
      'staff_save': 'Personeli Kaydet',
      'staff_created_msg': 'Personel başarıyla oluşturuldu! Şifresi: 123456',

      // Inventory & Dashboard (Common)
      'dashboard_welcome': 'HOŞ GELDİN!!',
      'dashboard_hello': 'Merhaba, Yönetici',
      'btn_add_manually': 'Manuel Ekle',
      'card_total_products': 'Toplam Ürün',
      'card_critical_stock': 'Kritik Stok',
      'card_total_value': 'Toplam Değer',
      'card_total_quantity': 'Toplam Miktar',
      'card_transactions': 'Toplam Hareket',
      'dashboard_critical_warnings': 'Uyarıları',
      'dashboard_all_stock_ok': 'Tüm stoklar yeterli seviyede! ✅',
      'dashboard_recent_activity': 'Son Hareketler',
      'dashboard_no_activity': 'Henüz stok hareketi yok',
      'dashboard_daily_summary': 'Günün Özeti',
      'summary_no_activity': 'Bugün depo sıfır hareket! İşler sakin geçiyor.',
      'summary_activity':
          'Bugün depoya {in} adet ürün girdi, {out} adet çıkış yapıldı.',

      // Time Formatting
      'time_just_now': 'Az önce',
      'time_min_ago': 'dk önce',
      'time_hour_ago': 'saat önce',
      'time_day_ago': 'gün önce',

      // Inventory Page
      'filter_all': 'Tümü',
      'hint_search_scan': 'Ürün ara veya tara...',
      'label_showing_items': 'ÜRÜN GÖSTERİLİYOR',
      'label_sort': 'Sırala',
      'sort_name': 'İsim',
      'sort_quantity': 'Miktar',
      'sort_category': 'Kategori',
      'empty_inventory_title': 'Henüz ürün yok',
      'empty_inventory_subtitle':
          'İlk ürününüzü ekleyerek stok takibine başlayın!',
      'empty_search_title': 'Sonuç bulunamadı',
      'empty_search_subtitle':
          'Arama kriterlerinize uygun ürün bulunamadı. Farklı bir arama deneyin.',
      'msg_deleted': 'silindi',
      'btn_undo': 'Geri Al',

      // Scanner Page
      'scanner_title': 'Barkod Tara',
      'scanner_hint': 'Barkodu çerçevenin içine hizalayın.',
      'deleted_product': 'Silinmiş Ürün',

      // Dialogs
      'dialog_update_stock_title': 'Stok Miktarını Güncelle',
      'label_min_level': 'Min. seviye',
      'btn_update': 'Güncelle',

      // Reports Page
      'reports_title': 'Analitik',
      'range_7_days': 'Son 7 Gün',
      'range_30_days': 'Bu Ay',
      'range_90_days': 'Son Çeyrek',
      'label_inbound': 'GİRİŞ',
      'label_outbound': 'ÇIKIŞ',
      'label_units_period': 'Bu dönemdeki birimler',
      'chart_category_dist': 'Kategori Dağılımı',
      'chart_weekly_movements': 'Haftalık Hareketler',
      'chart_top_products': 'En Aktif Ürünler',
      'legend_in': 'Giriş',
      'legend_out': 'Çıkış',
      'label_total': 'TOPLAM',
      'unit_items': 'Adet',
      'unit_types': 'Çeşit',
      'unit_units': 'birim',
      'label_high_activity': 'Yüksek Hareketlilik',
      'empty_category_chart':
          'Kategoriler oluşturulduğunda\nburada grafik görünecek',
      'empty_weekly_chart':
          'Stok hareketleri oluşturulduğunda\nburada grafik görünecek',
      'empty_top_products':
          'Ürün hareketleri başladığında\nen aktif ürünler burada görünecek',

      // Settings & Export
      'msg_no_data_export': 'Dışa aktarılacak veri yok.',
      'csv_header_id': 'ID',
      'csv_header_name': 'Ürün Adı',
      'csv_header_category': 'Kategori',
      'csv_header_quantity': 'Miktar',
      'csv_header_barcode': 'Barkod',
      'msg_backup_prefix': 'SmartInventory Yedek',
      'msg_error_prefix': 'Hata: ',
      'msg_data_cleared': 'Veriler silindi',

      // Product Add/Edit & Details
      'title_add_product': 'Ürün Ekle',
      'title_edit_product': 'Ürün Düzenle',
      'title_product_details': 'Ürün Detayları',
      'btn_cancel_caps': 'İptal', // used in AppBar leading
      'btn_save': 'Ürünü Kaydet',
      'btn_update_product': 'Ürünü Güncelle',
      'label_product_name': 'Ürün Adı',
      'hint_product_name': 'Örn: Smart Watch Gen 4',
      'err_name_required': 'Ürün adı zorunludur',
      'err_name_length': 'Ürün adı en az 2 karakter olmalıdır',
      'label_category': 'Kategori',
      'hint_category': 'Kategori seçiniz',
      'label_barcode': 'Barkod Numarası',
      'hint_barcode': 'Barkod tarayın veya girin',
      'label_stock_control': 'STOK KONTROLU',
      'label_initial_stock': 'Başlangıç Miktarı',
      'label_min_stock_warning': 'Min. Stok Uyarısı',
      'hint_stock_warning':
          'Stok miktarı bu rakamın altına düştüğünde uyarı verir.',
      'text_upload_image': 'Görsel yüklemek için dokunun',
      'source_camera': 'Kamera',
      'source_gallery': 'Galeri',
      'msg_added': 'eklendi',
      'msg_updated': 'güncellendi',

      // Stock Operations
      'btn_stock_in': 'Stok Giriş',
      'btn_stock_out': 'Stok Çıkış',
      'label_amount': 'Miktar',
      'label_reason': 'Sebep',
      'label_note': 'Not ekle (isteğe bağlı)',
      'label_current_stock': 'Mevcut:',
      'label_price': 'Fiyat (₺)',
      'hint_price': 'Örn: 29.99',
      'err_price_invalid': 'Geçerli bir fiyat giriniz.',
      'label_history': 'Stok Hareket Geçmişi',
      'msg_no_history': 'Henüz hareket yok',
      'msg_over_limit': '⚠ Mevcut stoktan fazla çıkarıyorsunuz!',
      'btn_add_amount': 'adet ekle',
      'btn_remove_amount': 'adet çıkar',

      // Stock Reasons
      'reason_stock_in': 'Stok Girişi',
      'reason_return': 'İade',
      'reason_correction': 'Düzeltme',
      'reason_sale': 'Satış',
      'reason_damaged': 'Hasarlı',
      'reason_lost': 'Kayıp',
      'reason_initial': 'Başlangıç Stok',
    },
    'en': {
      // Nav & Titles
      'nav_home': 'Home',
      'nav_inventory': 'Inventory',
      'nav_reports': 'Reports',
      'nav_settings': 'Settings',
      'app_title': 'SmartInventory',

      // Auth (Login)
      'login_title': 'Welcome!!',
      'login_subtitle': 'Please log in to your account.',
      'label_email': 'Email Address',
      'hint_email': 'example@company.com',
      'err_email_invalid': 'Please enter a valid email.',
      'label_password': 'Password',
      'hint_password': '••••••••',
      'err_password_short': 'Password must be at least 6 characters.',
      'btn_login': 'Log In',

      // Settings Page
      'profile_title': 'Profile',
      'role_admin': 'Admin',
      'status_active': 'ACTIVE',
      'section_dw': 'PREFERENCES',
      'pref_dark_mode': 'Dark Mode',
      'pref_language': 'Language / Dil',
      'section_data': 'DATA MANAGEMENT',
      'btn_export_csv': 'Export to CSV',
      'btn_export_pdf': 'Export as PDF',
      'btn_manage_staff': 'Manage Staff',
      'btn_manage_categories': 'Manage Categories',
      'btn_clear_data': 'Clear All Products',
      'dialog_clear_title': 'Clear All Products',
      'dialog_clear_content':
          'This action will irreversibly delete all saved products and stock movements. Your categories will not be deleted.\n\nType "CONFIRM" in the field below to proceed.',
      'section_security': 'SECURITY',
      'pref_biometric': 'Biometric Lock',
      'section_about': 'ABOUT',
      'about_version': 'App Version',
      'about_app': 'About SmartInventory',
      'btn_logout': 'Log Out',
      'btn_cancel': 'Cancel',
      'btn_confirm_delete': 'Delete',
      'msg_export_success': 'File ready',

      // Categories Page
      'page_manage_categories': 'Manage Categories',
      'categories_empty':
          'No categories yet.\nTap the "+" button in the top right to get started.',
      'categories_error': 'An error occurred',
      'dialog_delete_category_title': 'Confirm Delete',
      'dialog_delete_category_content':
          'category? All products in this category will be moved to "General".',

      // Staff Management Page
      'page_manage_staff': 'Staff Management',
      'staff_retry': 'Retry',
      'staff_empty': 'No other staff members yet.',
      'staff_add_fab': 'Add Staff',
      'staff_role_admin': 'ADMIN',
      'staff_role_warehouse': 'WAREHOUSE',
      'staff_role_cashier': 'CASHIER',
      'staff_unnamed': 'Unnamed Staff',
      'staff_add_title': 'Add New Staff',
      'staff_add_subtitle':
          'The staff member\'s password will be automatically set to "123456".',
      'staff_label_name': 'Full Name',
      'staff_err_name': 'Full name is required',
      'staff_label_email': 'Email',
      'staff_err_email_empty': 'Email is required',
      'staff_err_email_invalid': 'Please enter a valid email',
      'staff_role_label': 'Role',
      'staff_role_cashier_label': 'Cashier',
      'staff_role_warehouse_label': 'Warehouse\nStaff',
      'staff_save': 'Save Staff Member',
      'staff_created_msg':
          'Staff member created successfully! Password: 123456',

      // Inventory & Dashboard (Common)
      'dashboard_welcome': 'Welcome!!',
      'dashboard_hello': 'Hello, Admin',
      'btn_add_manually': 'Add Manually',
      'card_total_products': 'Total Products',
      'card_critical_stock': 'Critical Stock',
      'card_total_value': 'Total Value',
      'card_total_quantity': 'Total Quantity',
      'card_transactions': 'Total Transactions',
      'dashboard_critical_warnings': 'Warnings',
      'dashboard_all_stock_ok': 'All stock levels are good! ✅',
      'dashboard_recent_activity': 'Recent Activity',
      'dashboard_no_activity': 'No stock movements yet',
      'dashboard_daily_summary': 'Daily Summary',
      'summary_no_activity': 'No stock movements today. A quiet day!',
      'summary_activity':
          'Today {in} products entered, {out} products left the inventory.',

      // Time Formatting
      'time_just_now': 'Just now',
      'time_min_ago': 'm ago',
      'time_hour_ago': 'h ago',
      'time_day_ago': 'd ago',

      // Inventory Page
      'filter_all': 'All',
      'hint_search_scan': 'Search or scan product...',
      'label_showing_items': 'ITEMS SHOWING',
      'label_sort': 'Sort by',
      'sort_name': 'Name',
      'sort_quantity': 'Quantity',
      'sort_category': 'Category',
      'empty_inventory_title': 'No products yet',
      'empty_inventory_subtitle':
          'Add your first product to start tracking stock!',
      'empty_search_title': 'No results found',
      'empty_search_subtitle':
          'No products found matching your search. Try a different query.',
      'msg_deleted': 'deleted',
      'btn_undo': 'Undo',

      // Scanner Page
      'scanner_title': 'Scan Barcode',
      'scanner_hint': 'Align the barcode within the frame.',
      'deleted_product': 'Deleted Product',

      // Dialogs
      'dialog_update_stock_title': 'Update Stock Quantity',
      'label_min_level': 'Min. level',
      'btn_update': 'Update',

      // Reports Page
      'reports_title': 'Analytics',
      'range_7_days': 'Last 7 Days',
      'range_30_days': 'This Month',
      'range_90_days': 'Last Quarter',
      'label_inbound': 'INBOUND',
      'label_outbound': 'OUTBOUND',
      'label_units_period': 'Units this period',
      'chart_category_dist': 'Category Distribution',
      'chart_weekly_movements': 'Weekly Movements',
      'chart_top_products': 'Top Moving Products',
      'legend_in': 'In',
      'legend_out': 'Out',
      'label_total': 'TOTAL',
      'unit_items': 'Items',
      'unit_types': 'Types',
      'unit_units': 'units',
      'label_high_activity': 'High Activity',
      'empty_category_chart':
          'Chart will appear here\nwhen categories are created',
      'empty_weekly_chart':
          'Chart will appear here\nwhen stock movements occur',
      'empty_top_products':
          'Top active products will appear here\nwhen movements start',

      // Settings & Export
      'msg_no_data_export': 'No data to export.',
      'csv_header_id': 'ID',
      'csv_header_name': 'Product Name',
      'csv_header_category': 'Category',
      'csv_header_quantity': 'Quantity',
      'csv_header_barcode': 'Barcode',
      'msg_backup_prefix': 'SmartInventory Backup',
      'msg_error_prefix': 'Error: ',
      'msg_data_cleared': 'Data cleared',

      // Product Add/Edit & Details
      'title_add_product': 'Add Product',
      'title_edit_product': 'Edit Product',
      'title_product_details': 'Product Details',
      'btn_cancel_caps': 'Cancel',
      'btn_save': 'Save Product',
      'btn_update_product': 'Update Product',
      'label_product_name': 'Product Name',
      'hint_product_name': 'Ex: Smart Watch Gen 4',
      'err_name_required': 'Product name is required',
      'err_name_length': 'Product name must be at least 2 characters',
      'label_category': 'Category',
      'hint_category': 'Select category',
      'label_barcode': 'Barcode Number',
      'hint_barcode': 'Scan or enter barcode',
      'label_stock_control': 'STOCK CONTROL',
      'label_initial_stock': 'Initial Quantity',
      'label_min_stock_warning': 'Min. Stock Warning',
      'hint_stock_warning': 'Warns when stock falls below this amount.',
      'text_upload_image': 'Tap to upload image',
      'source_camera': 'Camera',
      'source_gallery': 'Gallery',
      'msg_added': 'added',
      'msg_updated': 'updated',

      // Stock Operations
      'btn_stock_in': 'Stock In',
      'btn_stock_out': 'Stock Out',
      'label_amount': 'Amount',
      'label_reason': 'Reason',
      'label_note': 'Add note (optional)',
      'label_current_stock': 'Current',
      'label_price': 'Price (₺)',
      'hint_price': 'e.g. 29.99',
      'err_price_invalid': 'Please enter a valid price.',
      'label_history': 'Stock Movement History',
      'msg_no_history': 'No movements yet',
      'msg_over_limit': '⚠ Exceeds current stock!',
      'btn_add_amount': 'units add',
      'btn_remove_amount': 'units remove',

      // Stock Reasons
      'reason_stock_in': 'Restock',
      'reason_return': 'Return',
      'reason_correction': 'Adjustment',
      'reason_sale': 'Sale',
      'reason_damaged': 'Damaged',
      'reason_lost': 'Lost',
      'reason_initial': 'Initial Stock',
    },
  };

  static String get(String key, String langCode) {
    return _localizedValues[langCode]?[key] ??
        _localizedValues['tr']?[key] ??
        key;
  }
}
