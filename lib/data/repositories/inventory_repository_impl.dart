import 'package:fpdart/fpdart.dart';
import 'package:isar/isar.dart';
import '../../domain/repositories/i_inventory_repository.dart';
import '../local/isar_db.dart';
import '../models/product_model.dart';
import '../models/stock_movement_model.dart';
import '../models/report_models.dart';
import '../../core/service_locator.dart';
import '../datasources/sync_manager.dart';
import 'package:uuid/uuid.dart';
import '../../domain/repositories/i_auth_repository.dart';
import '../datasources/remote/i_supabase_remote_datasource.dart';
import 'package:flutter/foundation.dart';

class InventoryRepositoryImpl implements IInventoryRepository {
  Isar get _db => IsarDb.instance;

  @override
  Stream<List<Product>> watchAllProducts() {
    return _db.products.where().watch(fireImmediately: true);
  }

  @override
  Stream<List<Product>> watchCriticalProducts() {
    return _db.products
        .where()
        .watch(fireImmediately: true)
        .map(
          (products) =>
              products.where((p) => p.quantity < p.minStockLevel).toList(),
        )
        .asBroadcastStream();
  }

  @override
  Stream<List<StockMovement>> watchRecentMovements({int limit = 5}) {
    return _db.stockMovements
        .where()
        .sortByCreatedAtDesc()
        .limit(limit)
        .watch(fireImmediately: true);
  }

  @override
  Stream<int> watchTotalMovementCount() {
    return _db.stockMovements
        .where()
        .watch(fireImmediately: true)
        .map((list) => list.length)
        .asBroadcastStream();
  }

  @override
  Stream<List<StockMovement>> watchMovementsForProduct(int productId) {
    return _db.stockMovements
        .filter()
        .productIdEqualTo(productId)
        .sortByCreatedAtDesc()
        .watch(fireImmediately: true);
  }

  @override
  Future<Either<String, List<Product>>> getAllProducts() async {
    try {
      final products = await _db.products.where().findAll();
      return Right(products);
    } catch (e) {
      return Left("Ürünler getirilirken hata oluştu: ${e.toString()}");
    }
  }

  @override
  Future<Either<String, Product?>> getProductByBarcode(String barcode) async {
    try {
      final product = await _db.products
          .filter()
          .barcodeEqualTo(barcode)
          .findFirst();
      return Right(product);
    } catch (e) {
      return Left("Barkod aranırken hata oluştu: ${e.toString()}");
    }
  }

  @override
  Future<Either<String, Product?>> getProductById(int id) async {
    try {
      final product = await _db.products.get(id);
      return Right(product);
    } catch (e) {
      return Left("Ürün aranırken hata oluştu: ${e.toString()}");
    }
  }

  @override
  Future<Either<String, int>> upsertProduct(Product product) async {
    try {
      final authRepo = getIt<IAuthRepository>();
      final profileRes = await authRepo.getCurrentProfile();
      final performedBy = profileRes.fold((l) => null, (r) => r?.fullName);

      /// Benzersiz barkod kontrolü (farklı bir ID için aynı barkod varsa uyarı ver)
      if (product.barcode != null && product.barcode!.isNotEmpty) {
        final existing = await _db.products
            .filter()
            .barcodeEqualTo(product.barcode)
            .findFirst();
        if (existing != null && existing.id != product.id) {
          return const Left("Bu barkod başka bir üründe zaten kayıtlı.");
        }
      }

      int id = 0;
      await _db.writeTxn(() async {
        final isNew = product.id == Isar.autoIncrement || product.id == 0;
        product.updatedAt = DateTime.now();

        if (isNew) {
          product.createdAt = DateTime.now();
          product.syncId = const Uuid().v4();
          product.syncStatus = 'pending_create';
        } else {
          product.syncStatus = 'pending_update';
        }

        id = await _db.products.put(product);

        // Yeni ürün ve miktar > 0 ise başlangıç hareketi ekle
        if (isNew && product.quantity > 0) {
          final initialMovement = StockMovement()
            ..product.value = product
            ..productId = id
            ..quantity = product.quantity
            ..type = MovementType.inbound
            ..reason = "Başlangıç Stoğu"
            ..performedBy = performedBy
            ..createdAt = DateTime.now()
            ..syncId = const Uuid().v4()
            ..syncStatus = 'pending_create';

          await _db.stockMovements.put(initialMovement);
          await initialMovement.product.save();
        }
      });

      // Kayıt başarılıysa Arka Planda Sync İşlemini Tetikle
      getIt<SyncManager>().syncData();

      return Right(id);
    } catch (e) {
      return Left("Ürün kaydedilemedi: ${e.toString()}");
    }
  }

  @override
  Future<Either<String, Unit>> deleteProduct(int id) async {
    try {
      final product = await _db.products.get(id);

      if (product != null) {
        try {
          await getIt<ISupabaseRemoteDataSource>().deleteProduct(
            product.syncId,
          );
        } catch (e) {
          debugPrint("Cloud veri silme hatası: $e");
        }
      }

      await _db.writeTxn(() async {
        // İlgili ürünün hareketlerini sil (Cascade Delete el ile yapılır Isar'da)
        await _db.stockMovements.filter().productIdEqualTo(id).deleteAll();
        await _db.products.delete(id);
      });
      return const Right(unit);
    } catch (e) {
      return Left("Ürün silinemedi: ${e.toString()}");
    }
  }

  @override
  Future<Either<String, Unit>> adjustStock({
    required int productId,
    required double quantityChange,
    required String reason,
    String? note,
  }) async {
    try {
      final authRepo = getIt<IAuthRepository>();
      final profileRes = await authRepo.getCurrentProfile();
      final performedBy = profileRes.fold((l) => null, (r) => r?.fullName);

      return await _db.writeTxn(() async {
        final product = await _db.products.get(productId);
        if (product == null) {
          return const Left("Hata: Ürün bulunamadı.");
        }

        final newQuantity = product.quantity + quantityChange;
        if (newQuantity < 0) {
          // Negatif stok engellemesi isteğe bağlıysa burası değiştirilebilir, şimdilik uyarıyoruz
          return const Left("Stok miktarı 0'ın altına düşemez!");
        }

        product.quantity = newQuantity;
        product.updatedAt = DateTime.now();
        product.syncStatus = 'pending_update';
        await _db.products.put(product);

        final movement = StockMovement()
          ..product.value = product
          ..productId = productId
          ..type = quantityChange > 0
              ? MovementType.inbound
              : MovementType.outbound
          ..quantity = quantityChange.abs()
          ..reason = reason
          ..note = note
          ..performedBy = performedBy
          ..createdAt = DateTime.now()
          ..syncId = const Uuid().v4()
          ..syncStatus = 'pending_create';

        await _db.stockMovements.put(movement);
        await movement.product.save(); // IsarLink'i kaydet

        return const Right(unit);
      });
    } catch (e) {
      return Left("Stok güncellenirken hata oluştu: ${e.toString()}");
    } finally {
      getIt<SyncManager>().syncData();
    }
  }

  @override
  Future<Either<String, Unit>> clearAllData() async {
    try {
      final authRepo = getIt<IAuthRepository>();
      final profileRes = await authRepo.getCurrentProfile();
      final tenantId = profileRes.fold((l) => null, (r) => r?.tenantId);

      if (tenantId != null) {
        try {
          await getIt<ISupabaseRemoteDataSource>().deleteAllTenantData(
            tenantId,
          );
        } catch (e) {
          debugPrint('Cloud veri silme hatası: $e');
        }
      }

      await _db.writeTxn(() async {
        await _db.products.clear();
        await _db.stockMovements.clear();
      });
      return const Right(unit);
    } catch (e) {
      return Left('Veriler temizlenirken hata oluştu: ${e.toString()}');
    }
  }

  @override
  Future<Either<String, List<StockMovement>>> getAllMovements() async {
    try {
      final movements = await _db.stockMovements
          .where()
          .sortByCreatedAtDesc()
          .findAll();
      return Right(movements);
    } catch (e) {
      return Left("Hareketler getirilirken hata oluştu: ${e.toString()}");
    }
  }

  @override
  Future<Either<String, int>> getTotalInbound({DateTime? since}) async {
    try {
      var query = _db.stockMovements.filter().typeEqualTo(MovementType.inbound);
      if (since != null) {
        query = query.createdAtGreaterThan(since);
      }
      final items = await query.findAll();
      final total = items.fold<double>(0, (sum, m) => sum + m.quantity);
      return Right(total.toInt());
    } catch (e) {
      return Left('Arama hatası: ${e.toString()}');
    }
  }

  @override
  Future<Either<String, int>> getTotalOutbound({DateTime? since}) async {
    try {
      var query = _db.stockMovements.filter().typeEqualTo(
        MovementType.outbound,
      );
      if (since != null) {
        query = query.createdAtGreaterThan(since);
      }
      final items = await query.findAll();
      final total = items.fold<double>(0, (sum, m) => sum + m.quantity);
      return Right(total.toInt());
    } catch (e) {
      return Left('Arama hatası: ${e.toString()}');
    }
  }

  @override
  Future<Either<String, List<CategoryCount>>> getCategoryDistribution() async {
    try {
      final products = await _db.products.where().findAll();
      final Map<String, CategoryCount> grouped = {};

      for (var p in products) {
        if (!grouped.containsKey(p.category)) {
          grouped[p.category] = CategoryCount(
            category: p.category,
            totalQuantity: 0,
            productCount: 0,
          );
        }
        final current = grouped[p.category]!;
        grouped[p.category] = CategoryCount(
          category: p.category,
          totalQuantity: current.totalQuantity + p.quantity.toInt(),
          productCount: current.productCount + 1,
        );
      }

      final result = grouped.values.toList()
        ..sort((a, b) => b.totalQuantity.compareTo(a.totalQuantity));
      return Right(result);
    } catch (e) {
      return Left('Arama hatası: ${e.toString()}');
    }
  }

  @override
  Future<Either<String, List<DailyMovement>>> getDailyMovements({
    required int days,
  }) async {
    try {
      final since = DateTime.now().subtract(Duration(days: days));
      final movements = await _db.stockMovements
          .filter()
          .createdAtGreaterThan(since)
          .findAll();

      final Map<DateTime, DailyMovement> grouped = {};

      for (int i = days - 1; i >= 0; i--) {
        final d = DateTime.now().subtract(Duration(days: i));
        final date = DateTime(d.year, d.month, d.day);
        grouped[date] = DailyMovement(date: date, totalIn: 0, totalOut: 0);
      }

      for (var m in movements) {
        final d = m.createdAt;
        final date = DateTime(d.year, d.month, d.day);
        if (grouped.containsKey(date)) {
          final current = grouped[date]!;
          if (m.type == MovementType.inbound) {
            grouped[date] = DailyMovement(
              date: current.date,
              totalIn: current.totalIn + m.quantity.toInt(),
              totalOut: current.totalOut,
            );
          } else {
            grouped[date] = DailyMovement(
              date: current.date,
              totalIn: current.totalIn,
              totalOut: current.totalOut + m.quantity.toInt(),
            );
          }
        }
      }

      final result = grouped.values.toList()
        ..sort((a, b) => a.date.compareTo(b.date));
      return Right(result);
    } catch (e) {
      return Left('Arama hatası: $e');
    }
  }

  @override
  Future<Either<String, List<TopProduct>>> getTopMovingProducts({
    int limit = 5,
  }) async {
    try {
      final movements = await _db.stockMovements.where().findAll();
      final Map<int, int> movementCounts = {};
      for (var m in movements) {
        movementCounts[m.productId] = (movementCounts[m.productId] ?? 0) + 1;
      }

      final sortedIds = movementCounts.keys.toList()
        ..sort((a, b) => movementCounts[b]!.compareTo(movementCounts[a]!));

      final topIds = sortedIds.take(limit).toList();
      final List<TopProduct> result = [];

      for (var id in topIds) {
        final p = await _db.products.get(id);
        if (p != null) {
          result.add(
            TopProduct(
              productId: p.id,
              productTitle: p.title,
              productBarcode: p.barcode,
              productImagePath: p.imagePath,
              movementCount: movementCounts[id]!,
            ),
          );
        }
      }

      return Right(result);
    } catch (e) {
      return Left('Hata: $e');
    }
  }
}
