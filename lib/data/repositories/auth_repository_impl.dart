import 'package:fpdart/fpdart.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:isar/isar.dart';
import '../../domain/repositories/i_auth_repository.dart';
import '../models/profile_model.dart';
import '../local/isar_db.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class AuthRepositoryImpl implements IAuthRepository {
  final SupabaseClient _supabase;
  Isar get _db => IsarDb.instance;

  AuthRepositoryImpl(this._supabase);

  @override
  User? getCurrentUser() {
    return _supabase.auth.currentUser;
  }

  @override
  Stream<AuthState> get authStateChanges => _supabase.auth.onAuthStateChange;

  @override
  Future<Either<String, Profile>> login({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );

      if (response.user == null) {
        return const Left('Giriş başarısız oldu.');
      }

      // Supabase'den profile verisini çekme
      final profileData = await _supabase
          .from('profiles')
          .select()
          .eq('id', response.user!.id)
          .maybeSingle();

      if (profileData == null) {
        return const Left('Kullanıcı profili bulunamadı.');
      }

      final profile = Profile()
        ..userId = profileData['id'] as String
        ..tenantId = profileData['tenant_id'] as String
        ..email = profileData['email'] as String
        ..fullName = profileData['full_name'] as String?
        ..role = profileData['role'] as String
        ..createdAt = DateTime.parse(profileData['created_at'].toString())
        ..updatedAt = DateTime.parse(profileData['updated_at'].toString())
        ..syncStatus = 'synced';

      // Locale profili kaydetme
      await _db.writeTxn(() async {
        await _db.profiles.putByUserId(profile);
      });

      return Right(profile);
    } on AuthException catch (e) {
      return Left(e.message);
    } catch (e) {
      return Left('Beklenmeyen bir hata oluştu: $e');
    }
  }

  @override
  Future<Either<String, void>> register({
    required String email,
    required String password,
    required String fullName,
  }) async {
    try {
      final response = await _supabase.auth.signUp(
        email: email,
        password: password,
        data: {'full_name': fullName},
      );

      if (response.user == null) {
        return const Left('Kayıt başarısız oldu.');
      }

      return const Right(null);
    } on AuthException catch (e) {
      return Left(e.message);
    } catch (e) {
      return Left('Beklenmeyen bir hata oluştu: $e');
    }
  }

  @override
  Future<Either<String, void>> logout() async {
    try {
      await _supabase.auth.signOut();
      return const Right(null);
    } catch (e) {
      return Left('Çıkış yapılırken hata oluştu: $e');
    }
  }

  @override
  Future<Either<String, Profile?>> getCurrentProfile() async {
    try {
      final user = getCurrentUser();
      if (user == null) return const Right(null);

      final localProfile = await _db.profiles.getByUserId(user.id);

      if (localProfile != null) {
        return Right(localProfile);
      }

      // Yerelde yoksa uzaktan dene
      final profileData = await _supabase
          .from('profiles')
          .select()
          .eq('id', user.id)
          .maybeSingle();

      if (profileData == null) {
        return const Right(null);
      }

      final profile = Profile()
        ..userId = profileData['id'] as String
        ..tenantId = profileData['tenant_id'] as String
        ..email = profileData['email'] as String
        ..fullName = profileData['full_name'] as String?
        ..role = profileData['role'] as String
        ..createdAt = DateTime.parse(profileData['created_at'].toString())
        ..updatedAt = DateTime.parse(profileData['updated_at'].toString())
        ..syncStatus = 'synced';

      await _db.writeTxn(() async {
        await _db.profiles.putByUserId(profile);
      });

      return Right(profile);
    } catch (e) {
      return Left('Profil alınırken hata oluştu: $e');
    }
  }

  @override
  Future<Either<String, List<Profile>>> getStaffList() async {
    try {
      final profileResult = await getCurrentProfile();
      return profileResult.fold((err) => Left(err), (profile) async {
        if (profile == null) return const Left('Profil bulunamadı.');

        final response = await _supabase
            .from('profiles')
            .select()
            .eq('tenant_id', profile.tenantId);

        final List<Profile> staffList = (response as List)
            .map(
              (e) => Profile()
                ..userId = e['id']
                ..tenantId = e['tenant_id']
                ..email = e['email']
                ..fullName = e['full_name'] as String?
                ..role = e['role']
                ..createdAt = DateTime.parse(e['created_at'].toString())
                ..updatedAt = DateTime.parse(e['updated_at'].toString())
                ..syncStatus = 'synced',
            )
            .toList();

        return Right(staffList);
      });
    } catch (e) {
      return Left('Personeller getirilirken hata oluştu: $e');
    }
  }

  @override
  Future<Either<String, void>> createStaff({
    required String fullName,
    required String email,
    required String role,
  }) async {
    try {
      final roleKey = dotenv.env['SUPABASE_SERVICE_ROLE_KEY'];
      if (roleKey == null || roleKey.isEmpty) {
        return const Left('Supabase Service Role Key yapılandırılmamış.');
      }

      final profileResult = await getCurrentProfile();
      final adminProfile = profileResult.fold((l) => null, (r) => r);
      if (adminProfile == null || adminProfile.role != 'admin') {
        return const Left('Bu işlem için admin yetkisi gereklidir.');
      }

      final adminClient = SupabaseClient(dotenv.env['SUPABASE_URL']!, roleKey);

      // Admin API ile kullanıcı oluştur (Mevcut admin hesabından çıkış yapmaz)
      final res = await adminClient.auth.admin.createUser(
        AdminUserAttributes(
          email: email,
          password: '123456',
          emailConfirm: true,
        ),
      );

      if (res.user == null) {
        return const Left('Kullanıcı oluşturulamadı.');
      }

      // Oluşan kullanıcının profilini otomatik olarak profiles tablosuna ekle
      await adminClient.from('profiles').insert({
        'id': res.user!.id,
        'tenant_id': adminProfile.tenantId,
        'full_name': fullName,
        'email': email,
        'role': role,
      });

      return const Right(null);
    } on AuthException catch (e) {
      return Left(e.message);
    } catch (e) {
      return Left('Beklenmeyen bir hata oluştu: $e');
    }
  }
}
