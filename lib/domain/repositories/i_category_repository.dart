import 'package:fpdart/fpdart.dart';
import '../../data/models/category_model.dart';

abstract class ICategoryRepository {
  /// Sistemdeki tüm kategorileri canlı olarak dinler (Arayüz listesi için)
  Stream<List<Category>> watchAllCategories();

  /// Senkronizasyon vb. işlemler için tek seferlik tüm kategorileri getirir
  Future<Either<String, List<Category>>> getAllCategories();

  /// Yeni bir kategori ekler veya varolanı günceller
  Future<Either<String, int>> upsertCategory(Category category);

  /// Bir kategoriyi (id bazında) siler
  Future<Either<String, Unit>> deleteCategory(int id);
}
