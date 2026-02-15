import 'package:isar/isar.dart';

part 'product_model.g.dart';

@collection
class Product {
  Id id = Isar.autoIncrement;

  @Index(type: IndexType.value)
  late String title;

  @Index(unique: true, replace: true)
  String? barcode;

  @Index(type: IndexType.value)
  late String category;

  late double quantity;

  late double minStockLevel;

  /// Birim satış fiyatı
  double price = 0.0;

  String? imagePath;

  late DateTime createdAt;

  late DateTime updatedAt;

  @Index(type: IndexType.value)
  bool isArchived = false;

  /// Supabase ile sekronizasyonda eşleşmeyi sağlayacak UUID (Lokal Id int değişebilir)
  @Index(unique: true, replace: true)
  late String syncId;

  /// 'synced', 'pending_create', 'pending_update', 'pending_delete'
  @Index(type: IndexType.value)
  late String syncStatus;

  /// Kolay kopyalama için copyWith metodu
  Product copyWith({
    Id? id,
    String? title,
    String? barcode,
    String? category,
    double? quantity,
    double? minStockLevel,
    double? price,
    String? imagePath,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isArchived,
    String? syncId,
    String? syncStatus,
  }) {
    final newProduct = Product()
      ..id = id ?? this.id
      ..title = title ?? this.title
      ..barcode = barcode ?? this.barcode
      ..category = category ?? this.category
      ..quantity = quantity ?? this.quantity
      ..minStockLevel = minStockLevel ?? this.minStockLevel
      ..price = price ?? this.price
      ..imagePath = imagePath ?? this.imagePath
      ..createdAt = createdAt ?? this.createdAt
      ..updatedAt = updatedAt ?? this.updatedAt
      ..isArchived = isArchived ?? this.isArchived
      ..syncId = syncId ?? this.syncId
      ..syncStatus = syncStatus ?? this.syncStatus;
    return newProduct;
  }
}
