import 'package:isar/isar.dart';

part 'category_model.g.dart';

@collection
class Category {
  Id id = Isar.autoIncrement;

  @Index(type: IndexType.value)
  late String name;

  late String colorHex;

  late int iconCodePoint;

  late DateTime createdAt;

  late DateTime updatedAt;

  @Index(type: IndexType.value)
  bool isArchived = false;

  /// Supabase ile sekronizasyonda eşleşmeyi sağlayacak UUID
  @Index(unique: true, replace: true)
  late String syncId;

  /// 'synced', 'pending_create', 'pending_update', 'pending_delete'
  @Index(type: IndexType.value)
  late String syncStatus;
}
