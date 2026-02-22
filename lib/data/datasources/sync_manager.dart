import 'package:isar/isar.dart';
import 'package:flutter/foundation.dart' hide Category;
import 'package:internet_connection_checker_plus/internet_connection_checker_plus.dart';

import '../local/isar_db.dart';
import '../models/product_model.dart';
import '../models/stock_movement_model.dart';
import '../models/category_model.dart';
import '../models/profile_model.dart';
import 'remote/i_supabase_remote_datasource.dart';

class SyncManager {
  final ISupabaseRemoteDataSource _remoteDS;

  bool _isSyncing = false;

  SyncManager(this._remoteDS);

  /// İnternet geldiği anda tetiklenmesini istediğimiz başlangıç noktası
  Future<void> startSyncLoop() async {
    InternetConnection().onStatusChange.listen((InternetStatus status) {
      if (status == InternetStatus.connected) {
        syncData();
      }
    });

    // Uygulama açılışında direkt bi şansını dener
    if (await InternetConnection().hasInternetAccess) {
      syncData();
    }
  }

  /// Tüm Push ve Pull Operasyonunu yürüten ana fonksiyon
  Future<void> syncData() async {
    if (_isSyncing) return;
    _isSyncing = true;

    try {
      await _pushChanges();
      await _pullChanges();
    } catch (e) {
      // Sync hatası loglanabilir
      debugPrint("Sync Manager Error: $e");
    } finally {
      _isSyncing = false;
    }
  }

  // 1- LOKALDE BEKLEYENLERI (PENDING) BULUTA GÖNDER
  Future<void> _pushChanges() async {
    final isar = IsarDb.instance;
    final profile = await isar.profiles.where().findFirst();
    final tenantId = profile?.tenantId;
    if (tenantId == null) return; // Oturum veya profil yoksa push yapma

    // --- Category Push (create/update) ---
    final pendingCats = await isar.categorys
        .filter()
        .syncStatusEqualTo('pending_create')
        .or()
        .syncStatusEqualTo('pending_update')
        .findAll();

    for (var cat in pendingCats) {
      try {
        await _remoteDS.upsertCategory(cat, tenantId);
        await isar.writeTxn(() async {
          cat.syncStatus = 'synced';
          await isar.categorys.put(cat);
        });
      } catch (e) {
        debugPrint('Category Push Error (ID: ${cat.id}): $e');
      }
    }

    // --- Category Push (delete) ---
    final deletedCats = await isar.categorys
        .filter()
        .syncStatusEqualTo('pending_delete')
        .findAll();

    for (var cat in deletedCats) {
      try {
        await _remoteDS.deleteCategory(cat.syncId);
        await isar.writeTxn(() async {
          await isar.categorys.delete(cat.id);
        });
      } catch (e) {
        debugPrint('Category Delete Error (ID: ${cat.id}): $e');
      }
    }

    // --- Product Push ---
    final pendingProducts = await isar.products
        .filter()
        .syncStatusEqualTo('pending_create')
        .or()
        .syncStatusEqualTo('pending_update')
        .findAll();

    for (var prod in pendingProducts) {
      try {
        await _remoteDS.upsertProduct(prod, tenantId);

        await isar.writeTxn(() async {
          prod.syncStatus = 'synced';
          await isar.products.put(prod);
        });
      } catch (e) {
        debugPrint('Product Push Error (ID: ${prod.id}): $e');
      }
    }

    // --- Transaction Push ---
    final pendingTx = await isar.stockMovements
        .filter()
        .syncStatusEqualTo('pending_create')
        .findAll();

    for (var tx in pendingTx) {
      try {
        await tx.product.load(); // Bağlı ürünü belleğe yükle
        if (tx.product.value != null) {
          await _remoteDS.upsertTransaction(tx, tenantId);

          await isar.writeTxn(() async {
            tx.syncStatus = 'synced';
            await isar.stockMovements.put(tx);
          });
        } else {
          debugPrint(
            "Transaction Push Alert: Product value is null for Tx ID: ${tx.id}",
          );
        }
      } catch (e) {
        debugPrint("Transaction Push Error (ID: ${tx.id}): $e");
      }
    }
  }

  // 2- BULUTTAKI DEGISIKLIKLERI (PULL) LOKALE CEK
  Future<void> _pullChanges() async {
    try {
      final isar = IsarDb.instance;

      final lastCopiedProduct = await isar.products
          .where()
          .sortByUpdatedAtDesc()
          .findFirst();
      final lastSyncTime = lastCopiedProduct?.updatedAt;

      final remoteProducts = await _remoteDS.pullProductsAfter(lastSyncTime);

      for (var row in remoteProducts) {
        await isar.writeTxn(() async {
          final existing = await isar.products
              .filter()
              .syncIdEqualTo(row['id'])
              .findFirst();

          final Product p = existing ?? Product();
          p.syncId = row['id'];
          p.title = row['title'];
          p.barcode = row['barcode'];
          p.category = row['category'];
          p.quantity = (row['quantity'] as num).toDouble();
          p.minStockLevel = (row['min_stock_level'] as num).toDouble();
          p.price = (row['price'] as num? ?? 0).toDouble();
          p.imagePath = row['image_path'];
          p.isArchived = row['is_archived'] ?? false;
          p.createdAt = DateTime.parse(row['created_at']);
          p.updatedAt = DateTime.parse(row['updated_at']);
          p.syncStatus = 'synced';

          await isar.products.put(p);
        });
      }

      // --- Category Pull ---
      final lastCat = await isar.categorys
          .where()
          .sortByUpdatedAtDesc()
          .findFirst();
      final lastSyncCat = lastCat?.updatedAt;
      final remoteCats = await _remoteDS.pullCategoriesAfter(lastSyncCat);

      for (var row in remoteCats) {
        await isar.writeTxn(() async {
          final existing = await isar.categorys
              .filter()
              .syncIdEqualTo(row['id'])
              .findFirst();
          final Category c = existing ?? Category();
          c.syncId = row['id'];
          c.name = row['name'];
          c.colorHex = row['color_hex'];
          c.iconCodePoint = row['icon_code_point'];
          c.isArchived = row['is_archived'] ?? false;
          c.createdAt = DateTime.parse(row['created_at']);
          c.updatedAt = DateTime.parse(row['updated_at']);
          c.syncStatus = 'synced';
          await isar.categorys.put(c);
        });
      }

      // --- Transaction Pull ---
      final lastTx = await isar.stockMovements
          .where()
          .sortByCreatedAtDesc()
          .findFirst();
      final lastSyncTx = lastTx?.createdAt;
      final remoteTxs = await _remoteDS.pullTransactionsAfter(lastSyncTx);

      for (var row in remoteTxs) {
        await isar.writeTxn(() async {
          final existing = await isar.stockMovements
              .filter()
              .syncIdEqualTo(row['id'])
              .findFirst();

          if (existing == null) {
            final prod = await isar.products
                .filter()
                .syncIdEqualTo(row['product_sync_id'])
                .findFirst();

            if (prod != null) {
              final tx = StockMovement()
                ..syncId = row['id']
                ..product.value = prod
                ..productId = prod.id
                ..type = row['type'] == 'inbound'
                    ? MovementType.inbound
                    : MovementType.outbound
                ..quantity = (row['quantity'] as num).toDouble()
                ..reason = row['reason'] ?? ''
                ..note = row['note']
                ..performedBy = row['performed_by']
                ..createdAt = DateTime.parse(row['created_at'])
                ..syncStatus = 'synced';

              await isar.stockMovements.put(tx);
              await tx.product.save();
            }
          }
        });
      }
    } catch (e) {
      debugPrint("Pull Error: $e");
    }
  }
}
