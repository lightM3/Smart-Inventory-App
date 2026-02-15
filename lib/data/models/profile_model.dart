import 'package:isar/isar.dart';

part 'profile_model.g.dart';

@collection
class Profile {
  Id id = Isar.autoIncrement;

  @Index(unique: true, replace: true)
  late String userId;

  @Index(type: IndexType.value)
  late String tenantId;

  late String email;
  String? fullName;

  @Index(type: IndexType.value)
  late String role;

  late DateTime createdAt;
  late DateTime updatedAt;

  @Index(type: IndexType.value)
  late String syncStatus;

  Profile copyWith({
    Id? id,
    String? userId,
    String? tenantId,
    String? email,
    String? fullName,
    String? role,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? syncStatus,
  }) {
    return Profile()
      ..id = id ?? this.id
      ..userId = userId ?? this.userId
      ..tenantId = tenantId ?? this.tenantId
      ..email = email ?? this.email
      ..fullName = fullName ?? this.fullName
      ..role = role ?? this.role
      ..createdAt = createdAt ?? this.createdAt
      ..updatedAt = updatedAt ?? this.updatedAt
      ..syncStatus = syncStatus ?? this.syncStatus;
  }
}
