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
      debugPrint('📤 Sending feeding reminder for: ${babyName ?? 'Baby'}');

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
        debugPrint('✅ Feeding reminder sent successfully');
        return true;
      } else {
        // Fallback to local notification
        await LocalNotificationService.showFeedingReminder(
          babyName: babyName ?? 'Bebeğiniz',
          payload: 'feeding|$babyId',
        );
        debugPrint('✅ Feeding reminder sent via local notification');
        return true;
      }
    } catch (e) {
      debugPrint('❌ Feeding reminder error: $e');
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
      debugPrint('📤 Sending sleep reminder for: ${babyName ?? 'Baby'}');

      await LocalNotificationService.showSleepReminder(
        babyName: babyName ?? 'Bebeğiniz',
        payload: 'sleep|$babyId',
      );

      debugPrint('✅ Sleep reminder sent successfully');
      return true;
    } catch (e) {
      debugPrint('❌ Sleep reminder error: $e');
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
      debugPrint('📤 Sending diaper reminder for: ${babyName ?? 'Baby'}');

      await LocalNotificationService.showDiaperReminder(
        babyName: babyName ?? 'Bebeğiniz',
        payload: 'diaper|$babyId',
      );

      debugPrint('✅ Diaper reminder sent successfully');
      return true;
    } catch (e) {
      debugPrint('❌ Diaper reminder error: $e');
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
      debugPrint('📤 Sending development reminder for: ${babyName ?? 'Baby'}');

      await LocalNotificationService.showDevelopmentReminder(
        babyName: babyName ?? 'Bebeğiniz',
        payload: 'development|$babyId',
      );

      debugPrint('✅ Development reminder sent successfully');
      return true;
    } catch (e) {
      debugPrint('❌ Development reminder error: $e');
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
      debugPrint('📤 Sending daily summary for: ${babyName ?? 'Baby'}');

      await LocalNotificationService.showDailySummary(
        babyName: babyName ?? 'Bebeğiniz',
        payload: 'daily_summary|$babyId',
      );

      debugPrint('✅ Daily summary sent successfully');
      return true;
    } catch (e) {
      debugPrint('❌ Daily summary error: $e');
      return false;
    }
  }

  // Send test notification
  static Future<bool> sendTestNotification({required String userId}) async {
    try {
      debugPrint('📤 Sending test notification');

      // Send via Supabase function (FCM)
      final success = await _sendViaSupabaseFunction(
        type: 'test',
        userId: userId,
        title: '🧪 Test Bildirimi',
        body: 'Firebase bildirim sistemi çalışıyor!',
        data: {'screen': 'test'},
      );

      if (success) {
        debugPrint('✅ Test notification sent successfully');
        return true;
      } else {
        // Fallback to local notification
        await LocalNotificationService.showTestNotification();
        debugPrint('✅ Test notification sent via local notification');
        return true;
      }
    } catch (e) {
      debugPrint('❌ Test notification error: $e');
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
        final result = response.data as Map<String, dynamic>;
        debugPrint(
          '✅ FCM notification sent successfully: ${result['messageId']}',
        );
        return true;
      } else {
        debugPrint('❌ FCM notification failed: ${response.status}');
        return false;
      }
    } catch (e) {
      debugPrint('❌ FCM notification error: $e');
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
      debugPrint(
        '⏰ Scheduling feeding reminder for: ${babyName ?? 'Baby'} at $scheduledTime',
      );

      await LocalNotificationService.scheduleNotification(
        id: 2001,
        title: '🍼 Beslenme Zamanı',
        body: '${babyName ?? 'Bebeğiniz'} için beslenme zamanı geldi!',
        scheduledDate: scheduledTime,
        payload: 'feeding|$babyId',
        notificationDetails:
            LocalNotificationService.getFeedingNotificationDetails(),
      );

      debugPrint('✅ Feeding reminder scheduled successfully');
      return true;
    } catch (e) {
      debugPrint('❌ Schedule feeding reminder error: $e');
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
      debugPrint(
        '⏰ Scheduling sleep reminder for: ${babyName ?? 'Baby'} at $scheduledTime',
      );

      await LocalNotificationService.scheduleNotification(
        id: 2002,
        title: '😴 Uyku Zamanı',
        body: '${babyName ?? 'Bebeğiniz'} için uyku zamanı geldi!',
        scheduledDate: scheduledTime,
        payload: 'sleep|$babyId',
        notificationDetails:
            LocalNotificationService.getSleepNotificationDetails(),
      );

      debugPrint('✅ Sleep reminder scheduled successfully');
      return true;
    } catch (e) {
      debugPrint('❌ Schedule sleep reminder error: $e');
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
        debugPrint('✅ Baby reminders cancelled for: $babyId');
      } else {
        await LocalNotificationService.cancelAllNotifications();
        debugPrint('✅ All reminders cancelled');
      }
    } catch (e) {
      debugPrint('❌ Cancel reminders error: $e');
    }
  }

  // Get pending notifications
  static Future<List<PendingNotificationRequest>>
  getPendingNotifications() async {
    try {
      return await LocalNotificationService.getPendingNotifications();
    } catch (e) {
      debugPrint('❌ Get pending notifications error: $e');
      return [];
    }
  }
}
