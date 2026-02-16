import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/service_locator.dart';
import '../../domain/repositories/i_auth_repository.dart';
import 'login_page.dart';
import 'main_shell.dart';

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    final authRepo = getIt<IAuthRepository>();

    return StreamBuilder<AuthState>(
      stream: authRepo.authStateChanges,
      builder: (context, snapshot) {
        // StreamBuilder tetiklendiğinde güncel session durumunu kontrol et
        final session = authRepo.getCurrentUser();

        if (session != null) {
          return const MainShell();
        } else {
          return const LoginPage();
        }
      },
    );
  }
}
