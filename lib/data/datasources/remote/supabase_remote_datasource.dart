import 'package:supabase_flutter/supabase_flutter.dart' as supa;
import '../../models/product_model.dart';
import '../../models/stock_movement_model.dart';
import '../../models/category_model.dart';
import 'i_supabase_remote_datasource.dart';

class SupabaseRemoteDataSource implements ISupabaseRemoteDataSource {
  final supa.SupabaseClient _supabase;

  SupabaseRemoteDataSource() : _supabase = supa.Supabase.instance.client;

  @override
  Future<void> upsertProduct(Product product, String tenantId) async {
    await _supabase.from('products').upsert({
      'id': product.syncId,
      'tenant_id': tenantId,
      'title': product.title,
      'barcode': product.barcode,
      'category': product.category,
      'quantity': product.quantity,
      'min_stock_level': product.minStockLevel,
      'price': product.price,
      'image_path': product.imagePath,
      'is_archived': product.isArchived,
      'created_at': product.createdAt.toIso8601String(),
      'updated_at': product.updatedAt.toIso8601String(),
    });
  }

  @override
  Future<void> upsertCategory(Category category, String tenantId) async {
    await _supabase.from('categories').upsert({
      'id': category.syncId,
      'tenant_id': tenantId,
      'name': category.name,
      'color_hex': category.colorHex,
      'icon_code_point': category.iconCodePoint,
      'is_archived': category.isArchived,
      'created_at': category.createdAt.toIso8601String(),
      'updated_at': category.updatedAt.toIso8601String(),
    });
  }

  @override
  Future<void> upsertTransaction(
    StockMovement movement,
    String tenantId,
  ) async {
    await _supabase.from('transactions').upsert({
      'id': movement.syncId,
      'tenant_id': tenantId,
      'product_sync_id': movement.product.value?.syncId,
      'type': movement.type == MovementType.inbound ? 'inbound' : 'outbound',
      'quantity': movement.quantity,
      'reason': movement.reason,
      'note': movement.note,
      'performed_by': movement.performedBy,
      'created_at': movement.createdAt.toIso8601String(),
    });
  }

  @override
  Future<List<Map<String, dynamic>>> pullProductsAfter(
    DateTime? lastSync,
  ) async {
    // Sadece is_archived olmayan ürünleri çek
    var query = _supabase.from('products').select().eq('is_archived', false);
    if (lastSync != null) {
      query = query.gt('updated_at', lastSync.toIso8601String());
    }
    final result = await query;
    return List<Map<String, dynamic>>.from(result);
  }

  @override
  Future<List<Map<String, dynamic>>> pullTransactionsAfter(
    DateTime? lastSync,
  ) async {
    var query = _supabase.from('transactions').select();
    if (lastSync != null) {
      query = query.gt('created_at', lastSync.toIso8601String());
    }
    final result = await query;
    return List<Map<String, dynamic>>.from(result);
  }

  @override
  Future<List<Map<String, dynamic>>> pullCategoriesAfter(
    DateTime? lastSync,
  ) async {
    // Sadece is_archived olmayan kategorileri çek
    var query = _supabase.from('categories').select().eq('is_archived', false);
    if (lastSync != null) {
      query = query.gt('updated_at', lastSync.toIso8601String());
    }
    final result = await query;
    return List<Map<String, dynamic>>.from(result);
  }

  @override
  Future<void> deleteAllTenantData(String tenantId) async {
    // İlgili tenant'a ait stok hareketlerini ve ürünleri siler.
    // Kategorilere dokunulmaz.
    await _supabase.from('transactions').delete().eq('tenant_id', tenantId);
    await _supabase.from('products').delete().eq('tenant_id', tenantId);
  }

  @override
  Future<void> deleteProduct(String syncId) async {
    await _supabase.from('products').delete().eq('id', syncId);
  }

  @override
  Future<void> deleteCategory(String syncId) async {
    await _supabase.from('categories').delete().eq('id', syncId);
  }
}
