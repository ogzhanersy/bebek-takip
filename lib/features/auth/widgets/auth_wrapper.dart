import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/services/supabase_service.dart';
import '../screens/auth_screen.dart';
import '../../home/screens/home_screen.dart';

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;

        // Geri tuşuna basıldığında uygulamayı kapatma
        // Bunun yerine ana sayfaya git veya mevcut sayfada kal
        final user = SupabaseService.currentUser;
        if (user != null) {
          // Kullanıcı giriş yapmışsa ana sayfaya git
          context.go('/');
        }
        // Kullanıcı giriş yapmamışsa auth ekranında kal
      },
      child: StreamBuilder<AuthState>(
        stream: SupabaseService.authStateChanges,
        initialData: null,
        builder: (context, snapshot) {
          // Show loading while checking auth state
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }

          // Check auth state from snapshot first, then fallback to current user
          final authState = snapshot.data;
          // If recovery deep link opened, navigate to reset password screen
          if (authState?.event == AuthChangeEvent.passwordRecovery) {
            // Navigate once
            Future.microtask(() => context.go('/reset-password'));
          }
          final user = authState?.session?.user ?? SupabaseService.currentUser;

          // Remove verbose debug prints in production

          // Daha katı kontrol - hem user hem de session olmalı
          final hasValidSession = user != null && authState?.session != null;

          if (hasValidSession) {
            // User is authenticated, show main app
            return const HomeScreen();
          } else {
            // User is not authenticated, show auth screen
            return const AuthScreen();
          }
        },
      ),
    );
  }
}
