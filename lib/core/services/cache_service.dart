import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class CacheService {
  static String _todayKey(String babyId, DateTime date) {
    final d = DateTime(date.year, date.month, date.day);
    return 'today_cache_${babyId}_${d.toIso8601String()}';
  }

  static Future<void> saveTodayData({
    required String babyId,
    required DateTime date,
    required List<Map<String, dynamic>> sleeps,
    required List<Map<String, dynamic>> feedings,
    required List<Map<String, dynamic>> diapers,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final payload = {
      'saved_at': DateTime.now().toIso8601String(),
      'sleeps': sleeps,
      'feedings': feedings,
      'diapers': diapers,
    };
    await prefs.setString(_todayKey(babyId, date), jsonEncode(payload));
  }

  static Future<Map<String, dynamic>?> loadTodayData({
    required String babyId,
    required DateTime date,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_todayKey(babyId, date));
    if (raw == null) return null;
    try {
      return jsonDecode(raw) as Map<String, dynamic>;
    } catch (_) {
      return null;
    }
  }
}
