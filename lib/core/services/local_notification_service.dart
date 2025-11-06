import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;
import 'notification_handler_service.dart';

class LocalNotificationService {
  static final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  static bool _initialized = false;

  // Initialize the notification service
  static Future<void> initialize() async {
    if (_initialized) return;

    try {
      // Initialize timezone
      tz.initializeTimeZones();

      // Android initialization settings
      const androidSettings = AndroidInitializationSettings(
        '@mipmap/ic_launcher',
      );

      // iOS initialization settings
      const iosSettings = DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
      );

      const initSettings = InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
      );

      await _notifications.initialize(
        initSettings,
        onDidReceiveNotificationResponse: _onNotificationTapped,
      );

      // Request permissions
      await _requestPermissions();

      _initialized = true;
      debugPrint('✅ Local Notification Service initialized');
    } catch (e) {
      debugPrint('❌ Local Notification Service initialization error: $e');
    }
  }

  // Request notification permissions
  static Future<void> _requestPermissions() async {
    if (defaultTargetPlatform == TargetPlatform.android) {
      final androidPlugin = _notifications
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >();

      // Request notification permission
      await androidPlugin?.requestNotificationsPermission();

      // Request exact alarm permission for Android 12+ (API 31+)
      await androidPlugin?.requestExactAlarmsPermission();
    }
  }

  // Handle notification tap
  static void _onNotificationTapped(NotificationResponse response) {
    debugPrint('🔔 Notification tapped: ${response.payload}');
    NotificationHandlerService.handleNotificationTap(response.payload);
  }

  // Show immediate notification
  static Future<void> showNotification({
    required int id,
    required String title,
    required String body,
    String? payload,
    NotificationDetails? notificationDetails,
  }) async {
    try {
      await _notifications.show(
        id,
        title,
        body,
        notificationDetails ?? _getDefaultNotificationDetails(),
        payload: payload,
      );
      debugPrint('✅ Notification shown: $title');
    } catch (e) {
      debugPrint('❌ Show notification error: $e');
    }
  }

  // Schedule notification
  static Future<void> scheduleNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledDate,
    String? payload,
    NotificationDetails? notificationDetails,
  }) async {
    try {
      // Check if exact alarms are permitted
      if (defaultTargetPlatform == TargetPlatform.android) {
        final androidPlugin = _notifications
            .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin
            >();

        final canScheduleExactAlarms = await androidPlugin
            ?.canScheduleExactNotifications();
        debugPrint('🔍 Can schedule exact alarms: $canScheduleExactAlarms');

        if (canScheduleExactAlarms == false) {
          debugPrint('⚠️ Exact alarms not permitted, requesting permission...');
          await androidPlugin?.requestExactAlarmsPermission();
        }
      }

      await _notifications.zonedSchedule(
        id,
        title,
        body,
        tz.TZDateTime.from(scheduledDate, tz.local),
        notificationDetails ?? _getDefaultNotificationDetails(),
        payload: payload,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      );
      debugPrint('✅ Notification scheduled: $title at $scheduledDate');
    } catch (e) {
      debugPrint('❌ Schedule notification error: $e');
    }
  }

  // Cancel notification
  static Future<void> cancelNotification(int id) async {
    try {
      await _notifications.cancel(id);
      debugPrint('✅ Notification cancelled: $id');
    } catch (e) {
      debugPrint('❌ Cancel notification error: $e');
    }
  }

  // Cancel all notifications
  static Future<void> cancelAllNotifications() async {
    try {
      await _notifications.cancelAll();
      debugPrint('✅ All notifications cancelled');
    } catch (e) {
      debugPrint('❌ Cancel all notifications error: $e');
    }
  }

  // Get pending notifications
  static Future<List<PendingNotificationRequest>>
  getPendingNotifications() async {
    try {
      return await _notifications.pendingNotificationRequests();
    } catch (e) {
      debugPrint('❌ Get pending notifications error: $e');
      return [];
    }
  }

  // Default notification details
  static NotificationDetails _getDefaultNotificationDetails() {
    const androidDetails = AndroidNotificationDetails(
      'baby_tracker_channel',
      'Bebek Takip Bildirimleri',
      channelDescription: 'Notifications for baby tracking activities',
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    return const NotificationDetails(android: androidDetails, iOS: iosDetails);
  }

  // Feeding reminder notification
  static Future<void> showFeedingReminder({
    required String babyName,
    String? payload,
  }) async {
    await showNotification(
      id: 1001,
      title: '🍼 Beslenme Zamanı',
      body: '$babyName için beslenme zamanı geldi!',
      payload: payload ?? 'feeding',
      notificationDetails: getFeedingNotificationDetails(),
    );
  }

  // Sleep reminder notification
  static Future<void> showSleepReminder({
    required String babyName,
    String? payload,
  }) async {
    await showNotification(
      id: 1002,
      title: '😴 Uyku Zamanı',
      body: '$babyName için uyku zamanı geldi!',
      payload: payload ?? 'sleep',
      notificationDetails: getSleepNotificationDetails(),
    );
  }

  // Diaper reminder notification
  static Future<void> showDiaperReminder({
    required String babyName,
    String? payload,
  }) async {
    await showNotification(
      id: 1003,
      title: '👶 Alt Değişimi',
      body: '$babyName için alt değişimi zamanı geldi!',
      payload: payload ?? 'diaper',
      notificationDetails: getDiaperNotificationDetails(),
    );
  }

  // Development reminder notification
  static Future<void> showDevelopmentReminder({
    required String babyName,
    String? payload,
  }) async {
    await showNotification(
      id: 1004,
      title: '📏 Gelişim Takibi',
      body: '$babyName için gelişim ölçümü zamanı geldi!',
      payload: payload ?? 'development',
      notificationDetails: getDevelopmentNotificationDetails(),
    );
  }

  // Daily summary notification
  static Future<void> showDailySummary({
    required String babyName,
    String? payload,
  }) async {
    await showNotification(
      id: 1005,
      title: '📊 Günlük Özet',
      body: '$babyName için bugünkü aktiviteleri kontrol edin!',
      payload: payload ?? 'daily_summary',
      notificationDetails: getDailySummaryNotificationDetails(),
    );
  }

  // Test notification
  static Future<void> showTestNotification() async {
    await showNotification(
      id: 9999,
      title: '🧪 Test Bildirimi',
      body: 'Local bildirim sistemi çalışıyor!',
      payload: 'test',
    );
  }

  // Notification details for different types
  static NotificationDetails getFeedingNotificationDetails() {
    const androidDetails = AndroidNotificationDetails(
      'feeding_channel',
      'Beslenme Hatırlatıcıları',
      channelDescription: 'Beslenme zamanı hatırlatıcıları',
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
      color: Color(0xFF4CAF50), // Green
    );

    return const NotificationDetails(android: androidDetails);
  }

  static NotificationDetails getSleepNotificationDetails() {
    const androidDetails = AndroidNotificationDetails(
      'sleep_channel',
      'Uyku Hatırlatıcıları',
      channelDescription: 'Uyku zamanı hatırlatıcıları',
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
      color: Color(0xFF2196F3), // Blue
    );

    return const NotificationDetails(android: androidDetails);
  }

  static NotificationDetails getDiaperNotificationDetails() {
    const androidDetails = AndroidNotificationDetails(
      'diaper_channel',
      'Alt Değişimi Hatırlatıcıları',
      channelDescription: 'Alt değişimi hatırlatıcıları',
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
      color: Color(0xFFFF9800), // Orange
    );

    return const NotificationDetails(android: androidDetails);
  }

  static NotificationDetails getDevelopmentNotificationDetails() {
    const androidDetails = AndroidNotificationDetails(
      'development_channel',
      'Gelişim Hatırlatıcıları',
      channelDescription: 'Gelişim takibi hatırlatıcıları',
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
      color: Color(0xFF9C27B0), // Purple
    );

    return const NotificationDetails(android: androidDetails);
  }

  static NotificationDetails getDailySummaryNotificationDetails() {
    const androidDetails = AndroidNotificationDetails(
      'daily_summary_channel',
      'Günlük Özet',
      channelDescription: 'Günlük aktivite özetleri',
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
      color: Color(0xFF607D8B), // Blue Grey
    );

    return const NotificationDetails(android: androidDetails);
  }
}
