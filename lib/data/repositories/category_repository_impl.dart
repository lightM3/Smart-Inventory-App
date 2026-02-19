import 'package:fpdart/fpdart.dart';
import 'package:isar/isar.dart';
import '../../domain/repositories/i_category_repository.dart';
import '../local/isar_db.dart';
import '../models/category_model.dart';
import 'package:uuid/uuid.dart';

import '../../core/service_locator.dart';
import '../datasources/sync_manager.dart';

class CategoryRepositoryImpl implements ICategoryRepository {
  Isar get _db => IsarDb.instance;

  @override
  Stream<List<Category>> watchAllCategories() {
    return _db.categorys
        .where()
        .filter()
        .isArchivedEqualTo(false) // Sadece silinmemiş olanları getir
        .sortByCreatedAt()
        .watch(fireImmediately: true);
  }

  @override
  Future<Either<String, List<Category>>> getAllCategories() async {
    try {
      final categories = await _db.categorys
          .where()
          .filter()
          .isArchivedEqualTo(false)
          .findAll();
      return Right(categories);
    } catch (e) {
      return Left("Kategoriler getirilirken hata: $e");
    }
  }

  @override
  Future<Either<String, int>> upsertCategory(Category category) async {
    try {
      int id = 0;
      await _db.writeTxn(() async {
        final isNew = category.id == Isar.autoIncrement || category.id == 0;
        category.updatedAt = DateTime.now();

        if (isNew) {
          category.createdAt = DateTime.now();
          category.syncId = const Uuid().v4();
          category.syncStatus = 'pending_create';
        } else {
          category.syncStatus = 'pending_update';
        }

        id = await _db.categorys.put(category);
      });

      // Arka planda anında buluta yedeklemeyi tetikliyoruz
      getIt<SyncManager>().syncData();

      return Right(id);
    } catch (e) {
      return Left("Kategori kaydedilemedi: $e");
    }
  }

  @override
  Future<Either<String, Unit>> deleteCategory(int id) async {
    try {
      await _db.writeTxn(() async {
        final category = await _db.categorys.get(id);
        if (category != null) {
          // Supabase'den de silinmesi için pending_delete olarak işaretle
          // SyncManager bu durumu görünce buluttan hard-delete yapar, sonra lokali temizler
          category.syncStatus = 'pending_delete';
          category.isArchived = true;
          category.updatedAt = DateTime.now();
          await _db.categorys.put(category);
        }
      });

      // Anında sync tetikle
      getIt<SyncManager>().syncData();

      return const Right(unit);
    } catch (e) {
      return Left('Kategori silinirken hata oluştu: $e');
    }
  }
}
