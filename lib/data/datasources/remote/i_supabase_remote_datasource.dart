import '../../models/product_model.dart';
import '../../models/stock_movement_model.dart';
import '../../models/category_model.dart';

abstract class ISupabaseRemoteDataSource {
  Future<void> upsertProduct(Product product, String tenantId);
  Future<void> upsertTransaction(StockMovement movement, String tenantId);
  Future<void> upsertCategory(Category category, String tenantId);
  Future<List<Map<String, dynamic>>> pullProductsAfter(DateTime? lastSync);
  Future<List<Map<String, dynamic>>> pullTransactionsAfter(DateTime? lastSync);
  Future<List<Map<String, dynamic>>> pullCategoriesAfter(DateTime? lastSync);

  /// İlgili Tenant'ın buluttaki tüm verilerini temizler.
  Future<void> deleteAllTenantData(String tenantId);

  /// Buluttan tek bir ürünü siler (SyncId üzerinden)
  Future<void> deleteProduct(String syncId);

  /// Buluttan tek bir kategoriyi siler (SyncId üzerinden)
  Future<void> deleteCategory(String syncId);
}
