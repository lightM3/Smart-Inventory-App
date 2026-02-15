import 'package:fpdart/fpdart.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../data/models/profile_model.dart';

abstract class IAuthRepository {
  /// Mevcut oturumdaki kullanıcı verisini Supabase'den çeker (senkron değil, anlık snapshot)
  User? getCurrentUser();

  /// Auth state değişikliklerini dinlemek için stream
  Stream<AuthState> get authStateChanges;

  /// E-posta ve şifre ile sisteme giriş yapar. Başarılıysa Profile döner
  Future<Either<String, Profile>> login({
    required String email,
    required String password,
  });

  /// Yeni kullanıcı kaydı oluşturur
  Future<Either<String, void>> register({
    required String email,
    required String password,
    required String fullName,
  });

  /// Sistemden çıkış yapar
  Future<Either<String, void>> logout();

  /// Aktif kullanıcının profilini (Role ve Tenant bilgileriyle) döndürür
  Future<Either<String, Profile?>> getCurrentProfile();

  /// Tüm personelleri listeler (RLS sayesinde sadece login olan tenant_id'nin personelleri gelir)
  Future<Either<String, List<Profile>>> getStaffList();

  /// Admin yetkisiyle (Service Role Key) yeni kullanıcı açar (otomatik olarak 123456 şifresiyle)
  Future<Either<String, void>> createStaff({
    required String fullName,
    required String email,
    required String role,
  });
}
