import 'package:isar/isar.dart';
import 'product_model.dart';

part 'stock_movement_model.g.dart';

enum MovementType {
  inbound, // Stok Girişi
  outbound, // Stok Çıkışı
}

@collection
class StockMovement {
  Id id = Isar.autoIncrement;

  // Isar'da ilişkisel yapı için IsarLink kullanılır
  final product = IsarLink<Product>();

  @Index(type: IndexType.value)
  late int productId; // Eski sorgularla uyumluluk için veya referans için basit ID

  @enumerated
  late MovementType type;

  late double quantity;

  late String reason;

  String? note;

  @Index(type: IndexType.value)
  late DateTime createdAt;

  /// Supabase ile sekronizasyonda eşleşmeyi sağlayacak UUID
  @Index(unique: true, replace: true)
  late String syncId;

  /// 'synced', 'pending_create', 'pending_update', 'pending_delete'
  @Index(type: IndexType.value)
  late String syncStatus;

  /// İşlemi gerçekleştiren personelin adı (opsiyonel)
  String? performedBy;
}
