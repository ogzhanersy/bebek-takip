import 'package:go_router/go_router.dart';
import 'package:flutter/material.dart';

class NotificationHandlerService {
  static final GlobalKey<NavigatorState> _navigatorKey =
      GlobalKey<NavigatorState>();

  // Set the navigator key (should be called from main.dart)
  static void setNavigatorKey(GlobalKey<NavigatorState> key) {
    _navigatorKey.currentState?.context;
  }

  // Handle notification tap
  static void handleNotificationTap(String? payload) {
    debugPrint('🔔 Notification tapped with payload: $payload');

    if (payload == null || payload.isEmpty) return;

    try {
      final context = _navigatorKey.currentContext;
      if (context == null) {
        debugPrint('❌ Navigator context not available');
        return;
      }

      // Parse payload format: "type|babyId" or "type"
      final parts = payload.split('|');
      final type = parts[0];

      switch (type) {
        case 'feeding':
          context.go('/feeding');
          break;
        case 'sleep':
          context.go('/sleep');
          break;
        case 'diaper':
          context.go('/home'); // Diaper tracking is on home screen
          break;
        case 'development':
          context.go('/home'); // Development tracking is on home screen
          break;
        case 'daily_summary':
          context.go('/daily-summary');
          break;
        case 'memories':
          context.go('/memories');
          break;
        case 'vaccination':
          context.go('/vaccination');
          break;
        case 'charts':
          context.go('/charts');
          break;
        case 'settings':
          context.go('/settings');
          break;
        default:
          debugPrint('❌ Unknown notification type: $type');
          // Default to home screen
          context.go('/home');
      }

      debugPrint('✅ Navigated to: $type');
    } catch (e) {
      debugPrint('❌ Navigation error: $e');
    }
  }

  // Get navigator key for use in main.dart
  static GlobalKey<NavigatorState> get navigatorKey => _navigatorKey;
}
