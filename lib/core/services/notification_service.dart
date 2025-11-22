import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'local_notification_service.dart';
// Firebase removed due to persistent Gradle issues
// import 'firebase_service.dart';
import 'supabase_service.dart';

class NotificationService {
  // Send feeding reminder
  static Future<bool> sendFeedingReminder({
    required String userId,
    String? babyId,
    String? babyName,
  }) async {
    try {
      // Send via Supabase function (FCM)
      final success = await _sendViaSupabaseFunction(
        type: 'feeding_reminder',
        userId: userId,
        babyId: babyId,
        title: '🍼 Beslenme Zamanı',
        body: babyName != null
            ? '$babyName için beslenme zamanı geldi!'
            : 'Bebeğinizin beslenme zamanı geldi!',
        data: {'screen': 'feeding', 'babyName': babyName},
      );

      if (success) {
        return true;
      } else {
        // Fallback to local notification
        await LocalNotificationService.showFeedingReminder(
          babyName: babyName ?? 'Bebeğiniz',
          payload: 'feeding|$babyId',
        );
        return true;
      }
    } catch (e) {
      debugPrint('Feeding reminder error: $e');
      return false;
    }
  }

  // Send sleep reminder
  static Future<bool> sendSleepReminder({
    required String userId,
    String? babyId,
    String? babyName,
  }) async {
    try {
      await LocalNotificationService.showSleepReminder(
        babyName: babyName ?? 'Bebeğiniz',
        payload: 'sleep|$babyId',
      );

      return true;
    } catch (e) {
      debugPrint('Sleep reminder error: $e');
      return false;
    }
  }

  // Send diaper reminder
  static Future<bool> sendDiaperReminder({
    required String userId,
    String? babyId,
    String? babyName,
  }) async {
    try {
      await LocalNotificationService.showDiaperReminder(
        babyName: babyName ?? 'Bebeğiniz',
        payload: 'diaper|$babyId',
      );

      return true;
    } catch (e) {
      debugPrint('Diaper reminder error: $e');
      return false;
    }
  }

  // Send development reminder
  static Future<bool> sendDevelopmentReminder({
    required String userId,
    String? babyId,
    String? babyName,
  }) async {
    try {
      await LocalNotificationService.showDevelopmentReminder(
        babyName: babyName ?? 'Bebeğiniz',
        payload: 'development|$babyId',
      );

      return true;
    } catch (e) {
      debugPrint('Development reminder error: $e');
      return false;
    }
  }

  // Send daily summary
  static Future<bool> sendDailySummary({
    required String userId,
    String? babyId,
    String? babyName,
  }) async {
    try {
      await LocalNotificationService.showDailySummary(
        babyName: babyName ?? 'Bebeğiniz',
        payload: 'daily_summary|$babyId',
      );

      return true;
    } catch (e) {
      debugPrint('Daily summary error: $e');
      return false;
    }
  }

  // Send test notification
  static Future<bool> sendTestNotification({required String userId}) async {
    try {
      // Send via Supabase function (FCM)
      final success = await _sendViaSupabaseFunction(
        type: 'test',
        userId: userId,
        title: '🧪 Test Bildirimi',
        body: 'Firebase bildirim sistemi çalışıyor!',
        data: {'screen': 'test'},
      );

      if (success) {
        return true;
      } else {
        // Fallback to local notification
        await LocalNotificationService.showTestNotification();
        return true;
      }
    } catch (e) {
      debugPrint('Test notification error: $e');
      return false;
    }
  }

  // Send via Supabase function (FCM)
  static Future<bool> _sendViaSupabaseFunction({
    required String type,
    required String userId,
    String? babyId,
    required String title,
    required String body,
    Map<String, dynamic>? data,
  }) async {
    try {
      final response = await SupabaseService.client.functions.invoke(
        'send-notification',
        body: {
          'type': type,
          'userId': userId,
          'babyId': babyId,
          'title': title,
          'body': body,
          'data': data ?? {},
        },
      );

      if (response.status == 200) {
        return true;
      } else {
        debugPrint('FCM notification failed: ${response.status}');
        return false;
      }
    } catch (e) {
      debugPrint('FCM notification error: $e');
      return false;
    }
  }

  // Schedule feeding reminder
  static Future<bool> scheduleFeedingReminder({
    required String userId,
    String? babyId,
    String? babyName,
    required DateTime scheduledTime,
  }) async {
    try {
      await LocalNotificationService.scheduleNotification(
        id: 2001,
        title: '🍼 Beslenme Zamanı',
        body: '${babyName ?? 'Bebeğiniz'} için beslenme zamanı geldi!',
        scheduledDate: scheduledTime,
        payload: 'feeding|$babyId',
        notificationDetails:
            LocalNotificationService.getFeedingNotificationDetails(),
      );

      return true;
    } catch (e) {
      debugPrint('Schedule feeding reminder error: $e');
      return false;
    }
  }

  // Schedule sleep reminder
  static Future<bool> scheduleSleepReminder({
    required String userId,
    String? babyId,
    String? babyName,
    required DateTime scheduledTime,
  }) async {
    try {
      await LocalNotificationService.scheduleNotification(
        id: 2002,
        title: '😴 Uyku Zamanı',
        body: '${babyName ?? 'Bebeğiniz'} için uyku zamanı geldi!',
        scheduledDate: scheduledTime,
        payload: 'sleep|$babyId',
        notificationDetails:
            LocalNotificationService.getSleepNotificationDetails(),
      );

      return true;
    } catch (e) {
      debugPrint('Schedule sleep reminder error: $e');
      return false;
    }
  }

  // Cancel all reminders for a baby
  static Future<void> cancelBabyReminders({String? babyId}) async {
    try {
      if (babyId != null) {
        // Cancel specific baby reminders (IDs 2001-2999)
        for (int i = 2001; i <= 2999; i++) {
          await LocalNotificationService.cancelNotification(i);
        }
      } else {
        await LocalNotificationService.cancelAllNotifications();
      }
    } catch (e) {
      debugPrint('Cancel reminders error: $e');
    }
  }

  // Get pending notifications
  static Future<List<PendingNotificationRequest>>
  getPendingNotifications() async {
    try {
      return await LocalNotificationService.getPendingNotifications();
    } catch (e) {
      debugPrint('Get pending notifications error: $e');
      return [];
    }
  }
}
