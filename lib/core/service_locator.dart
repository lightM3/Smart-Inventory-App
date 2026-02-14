import 'package:get_it/get_it.dart';
import 'package:smart_inventory/data/local/isar_db.dart';
import 'package:smart_inventory/domain/repositories/i_inventory_repository.dart';
import 'package:smart_inventory/data/repositories/inventory_repository_impl.dart';
import 'package:smart_inventory/domain/repositories/i_category_repository.dart';
import 'package:smart_inventory/data/repositories/category_repository_impl.dart';
import 'package:smart_inventory/data/datasources/remote/i_supabase_remote_datasource.dart';
import 'package:smart_inventory/data/datasources/remote/supabase_remote_datasource.dart';
import 'package:smart_inventory/data/datasources/sync_manager.dart';
import 'package:smart_inventory/domain/repositories/i_auth_repository.dart';
import 'package:smart_inventory/data/repositories/auth_repository_impl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final getIt = GetIt.instance;

Future<void> setupServiceLocator() async {
  // DB engine başlatılır
  await IsarDb.initialize();

  // IInventoryRepository kaydı oluşturulur
  // Repertuvar kayıtları oluşturulur
  getIt.registerLazySingleton<IInventoryRepository>(
    () => InventoryRepositoryImpl(),
  );
  getIt.registerLazySingleton<ICategoryRepository>(
    () => CategoryRepositoryImpl(),
  );

  // Supabase ve SyncManager
  getIt.registerLazySingleton<ISupabaseRemoteDataSource>(
    () => SupabaseRemoteDataSource(),
  );
  getIt.registerLazySingleton<SyncManager>(
    () => SyncManager(getIt<ISupabaseRemoteDataSource>()),
  );

  // Auth nesnesi (Supabase ile birlikte)
  getIt.registerLazySingleton<IAuthRepository>(
    () => AuthRepositoryImpl(Supabase.instance.client),
  );
}
