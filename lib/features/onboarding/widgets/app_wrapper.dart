import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../auth/widgets/auth_wrapper.dart';

class AppWrapper extends StatefulWidget {
  const AppWrapper({super.key});

  @override
  State<AppWrapper> createState() => _AppWrapperState();
}

class _AppWrapperState extends State<AppWrapper> {
  bool _isLoading = true;
  bool _hasSeenOnboarding = false;

  @override
  void initState() {
    super.initState();
    _checkAppStatus();
  }

  Future<void> _checkAppStatus() async {
    final prefs = await SharedPreferences.getInstance();
    final hasSeenOnboarding = prefs.getBool('hasSeenOnboarding') ?? false;

    setState(() {
      _hasSeenOnboarding = hasSeenOnboarding;
      _isLoading = false;
    });

    // Eğer onboarding görülmemişse, onboarding'e yönlendir
    if (!hasSeenOnboarding && mounted) {
      context.go('/onboarding');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    // Eğer onboarding görülmemişse, onboarding'e yönlendir
    if (!_hasSeenOnboarding) {
      return const SizedBox.shrink(); // Will redirect to onboarding
    }

    // Onboarding görülmüşse, auth durumunu kontrol et
    return const AuthWrapper();
  }
}
