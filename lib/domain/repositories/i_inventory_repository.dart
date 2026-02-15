import 'package:fpdart/fpdart.dart';
import '../../data/models/product_model.dart';
import '../../data/models/stock_movement_model.dart';
import '../../data/models/report_models.dart';

abstract class IInventoryRepository {
  /// Tüm ürünleri Stream olarak dinlemek için (Anlık UI güncellemeleri)
  Stream<List<Product>> watchAllProducts();

  /// Kritik stoktaki ürünleri dinlemek için
  Stream<List<Product>> watchCriticalProducts();

  /// Belirli bir ürünün veya tümünün son hareketlerini dinlemek için
  Stream<List<StockMovement>> watchRecentMovements({int limit = 5});

  /// Toplam hareket sayısını dinlemek için
  Stream<int> watchTotalMovementCount();

  /// Belirli bir ürünün tüm hareketlerini Stream olarak dinlemek için
  Stream<List<StockMovement>> watchMovementsForProduct(int productId);

  /// Tek seferlik tüm ürünleri getirir
  Future<Either<String, List<Product>>> getAllProducts();

  /// Barkoda göre ürün arar
  Future<Either<String, Product?>> getProductByBarcode(String barcode);

  /// ID'ye göre ürün arar
  Future<Either<String, Product?>> getProductById(int id);

  /// Yeni bir ürün ekler veya günceller
  Future<Either<String, int>> upsertProduct(Product product);

  /// Ürünü ID'si ile siler
  Future<Either<String, Unit>> deleteProduct(int id);

  /// Ürünün stok miktarını günceller ve bir stok hareketi kaydı oluşturur
  Future<Either<String, Unit>> adjustStock({
    required int productId,
    required double quantityChange,
    required String reason,
    String? note,
  });

  /// Tüm veritabanını temizler (Ayarlar sayfasındaki "Clear All Data" için)
  Future<Either<String, Unit>> clearAllData();

  /// Tek seferlik tüm stok hareketlerini getirir (CSV Export için)
  Future<Either<String, List<StockMovement>>> getAllMovements();

  /// Belirli bir tarihten itibaren toplam giren ürün sayısını döndürür
  Future<Either<String, int>> getTotalInbound({DateTime? since});

  /// Belirli bir tarihten itibaren toplam çıkan ürün sayısını döndürür
  Future<Either<String, int>> getTotalOutbound({DateTime? since});

  /// Kategorilere göre stok dağılımını döndürür
  Future<Either<String, List<CategoryCount>>> getCategoryDistribution();

  /// Son X gündeki günlük hareket özetini döndürür
  Future<Either<String, List<DailyMovement>>> getDailyMovements({
    required int days,
  });

  /// En çok hareket gören ürünleri (limit adedi kadar) döndürür
  Future<Either<String, List<TopProduct>>> getTopMovingProducts({
    int limit = 5,
  });
}
