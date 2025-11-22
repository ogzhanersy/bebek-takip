import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';

import 'core/theme/app_theme.dart';
import 'core/theme/app_colors.dart';
import 'core/services/supabase_service.dart';
import 'core/services/privacy_service.dart';
import 'core/services/local_notification_service.dart';
import 'core/services/ad_service.dart';
// Firebase permanently removed due to persistent Gradle issues
// import 'core/services/firebase_service.dart';
import 'features/onboarding/screens/onboarding_screen.dart';
import 'features/onboarding/widgets/app_wrapper.dart';
import 'features/splash/splash_screen.dart';
import 'features/splash/ad_screen.dart';
import 'features/auth/screens/forgot_password_screen.dart';
import 'features/auth/screens/reset_password_screen.dart';
import 'features/babies/screens/babies_screen.dart';
import 'features/babies/screens/add_baby_screen.dart';
import 'features/babies/screens/edit_baby_screen.dart';
import 'features/sleep/screens/sleep_screen.dart';
import 'features/feeding/screens/feeding_screen.dart';
import 'features/charts/screens/charts_screen.dart';
import 'features/vaccination/screens/vaccination_screen.dart';
import 'features/settings/screens/settings_screen.dart';
import 'features/settings/screens/profile_edit_screen.dart';
import 'features/memories/screens/memories_screen.dart';
import 'features/memories/screens/memory_edit_screen.dart';
import 'features/calendar/screens/calendar_screen.dart';
import 'features/home/screens/daily_summary_screen.dart';
import 'core/services/memory_service.dart';
import 'core/services/sync_service.dart';
import 'shared/providers/baby_provider.dart';
import 'shared/providers/tracking_provider.dart';
import 'shared/providers/theme_provider.dart';
import 'shared/providers/language_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Supabase
  await SupabaseService.initialize();

  // Handle deep links when app starts from terminated state
  // Supabase SDK automatically handles auth state changes

  // Initialize offline sync service
  await SyncService.initialize();

  // Initialize Local Notification Service
  await LocalNotificationService.initialize();

  // Initialize Ad Service
  await AdService.initialize();

  // Firebase permanently removed due to persistent Gradle issues
  // await FirebaseService.initialize();

  // Initialize Privacy Service
  await PrivacyService().initialize();

  // Set status bar style to match iOS design
  // Note: For Android 15+, edge-to-edge is handled in MainActivity
  // SystemChrome is only used for older Android versions to avoid deprecated APIs
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      // statusBarColor is deprecated in Android 15, but still needed for older versions
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      statusBarBrightness: Brightness.light,
      // systemNavigationBarColor is deprecated in Android 15, but still needed for older versions
      systemNavigationBarColor: AppColors.background,
      systemNavigationBarIconBrightness: Brightness.dark,
    ),
  );

  runApp(MyApp());
}

// Router configuration
final GoRouter _router = GoRouter(
  initialLocation: '/splash',
  redirect: (context, state) {
    // Handle deep links for Supabase auth callbacks
    final uri = state.uri;
    if (uri.scheme == 'babytracker' && uri.host == 'auth-callback') {
      // Supabase handles the session automatically
      // Just navigate to home - AuthWrapper will handle auth state
      return '/';
    }
    return null;
  },
  routes: [
    GoRoute(path: '/splash', builder: (context, state) => const SplashScreen()),
    GoRoute(path: '/ad', builder: (context, state) => const AdScreen()),
    GoRoute(path: '/', builder: (context, state) => const AppWrapper()),
    GoRoute(
      path: '/onboarding',
      builder: (context, state) => const OnboardingScreen(),
    ),
    GoRoute(
      path: '/forgot-password',
      builder: (context, state) => const ForgotPasswordScreen(),
    ),
    GoRoute(
      path: '/reset-password',
      builder: (context, state) => const ResetPasswordScreen(),
    ),
    GoRoute(path: '/babies', builder: (context, state) => const BabiesScreen()),
    GoRoute(path: '/sleep', builder: (context, state) => const SleepScreen()),
    GoRoute(
      path: '/feeding',
      builder: (context, state) => const FeedingScreen(),
    ),
    GoRoute(path: '/charts', builder: (context, state) => const ChartsScreen()),
    GoRoute(
      path: '/vaccination',
      builder: (context, state) => const VaccinationScreen(),
    ),
    GoRoute(
      path: '/memories',
      builder: (context, state) => const MemoriesScreen(),
    ),
    GoRoute(
      path: '/calendar',
      builder: (context, state) => const CalendarScreen(),
    ),
    GoRoute(
      path: '/daily-summary',
      builder: (context, state) => const DailySummaryScreen(),
    ),
    GoRoute(
      path: '/settings',
      builder: (context, state) => const SettingsScreen(),
    ),
    GoRoute(
      path: '/add-baby',
      builder: (context, state) => const AddBabyScreen(),
    ),
    GoRoute(
      path: '/edit-baby/:babyId',
      builder: (context, state) {
        final babyId = state.pathParameters['babyId']!;
        // Find baby by ID from BabyProvider
        return Consumer<BabyProvider>(
          builder: (context, babyProvider, child) {
            final baby = babyProvider.babies.firstWhere(
              (b) => b.id == babyId,
              orElse: () => throw Exception('Bebek bulunamadı'),
            );
            return EditBabyScreen(baby: baby);
          },
        );
      },
    ),
    GoRoute(
      path: '/profile/edit',
      builder: (context, state) => const ProfileEditScreen(fromPage: 'profile'),
    ),
    GoRoute(
      path: '/memory/edit/:memoryId',
      builder: (context, state) {
        final memoryId = state.pathParameters['memoryId']!;
        return FutureBuilder(
          future: MemoryService.getMemoryById(memoryId),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Scaffold(
                body: Center(child: CircularProgressIndicator()),
              );
            }

            if (snapshot.hasError || snapshot.data == null) {
              return Scaffold(
                appBar: AppBar(title: const Text('Hata')),
                body: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error, size: 64, color: Colors.red),
                      const SizedBox(height: 16),
                      Text('Anı bulunamadı: ${snapshot.error}'),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () => context.go('/memories'),
                        child: const Text('Anılara Dön'),
                      ),
                    ],
                  ),
                ),
              );
            }

            return MemoryEditScreen(memory: snapshot.data!);
          },
        );
      },
    ),
  ],
);

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> with WidgetsBindingObserver {
  late TrackingProvider _trackingProvider;
  late ThemeProvider _themeProvider;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _trackingProvider = TrackingProvider();
    _themeProvider = ThemeProvider();
    // Load sleep state when app starts
    _trackingProvider.loadSleepState();
    // Load theme preferences
    _themeProvider.loadPreferences();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    switch (state) {
      case AppLifecycleState.paused:
      case AppLifecycleState.detached:
        // App is going to background or being closed
        _trackingProvider.saveAppCloseTime();
        break;
      case AppLifecycleState.resumed:
        // App is coming back to foreground
        _trackingProvider.loadSleepState();
        break;
      case AppLifecycleState.inactive:
        // App is inactive but still visible
        break;
      case AppLifecycleState.hidden:
        // App is hidden
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => BabyProvider()),
        ChangeNotifierProvider(create: (_) => _trackingProvider),
        ChangeNotifierProvider(create: (_) => _themeProvider),
        ChangeNotifierProvider(create: (_) => LanguageProvider()),
      ],
      child: Consumer3<BabyProvider, TrackingProvider, ThemeProvider>(
        builder:
            (context, babyProvider, trackingProvider, themeProvider, child) {
              // Connect providers
              babyProvider.setTrackingProvider(trackingProvider);

              return MaterialApp.router(
                title: 'Bebek Takip',
                theme: AppTheme.lightTheme,
                darkTheme: AppTheme.darkTheme,
                themeMode: themeProvider.isDarkMode
                    ? ThemeMode.dark
                    : ThemeMode.light,
                routerConfig: _router,
                debugShowCheckedModeBanner: false,
                // Enable edge-to-edge for Android 15+ compatibility
                builder: (context, child) {
                  return MediaQuery(
                    data: MediaQuery.of(context).copyWith(
                      // Ensure text doesn't scale beyond readable limits
                      textScaler: TextScaler.linear(
                        MediaQuery.of(
                          context,
                        ).textScaler.scale(1.0).clamp(0.8, 1.2),
                      ),
                    ),
                    child: child!,
                  );
                },
              );
            },
      ),
    );
  }
}
