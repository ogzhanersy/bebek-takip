import '../../shared/models/sleep_model.dart';
import 'supabase_service.dart';

class SleepService {
  static const String tableName = 'sleep_records';

  // Get sleep records for a baby
  static Future<List<Sleep>> getSleepRecords(
    String babyId, {
    int? limit,
  }) async {
    try {
      var query = SupabaseService.from(
        tableName,
      ).select().eq('baby_id', babyId).order('start_time', ascending: false);

      if (limit != null) {
        query = query.limit(limit);
      }

      final response = await query;

      return (response as List).map((json) => Sleep.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Uyku kayıtları yüklenirken hata oluştu: $e');
    }
  }

  // Get active sleep session
  static Future<Sleep?> getActiveSleep(String babyId) async {
    try {
      final response = await SupabaseService.from(tableName)
          .select()
          .eq('baby_id', babyId)
          .isFilter('end_time', null)
          .order('start_time', ascending: false)
          .maybeSingle();

      if (response == null) return null;
      return Sleep.fromJson(response);
    } catch (e) {
      throw Exception('Aktif uyku kaydı yüklenirken hata oluştu: $e');
    }
  }

  // Start sleep session
  static Future<Sleep> startSleep(String babyId, {String? notes}) async {
    try {
      final sleep = Sleep(
        babyId: babyId,
        startTime: DateTime.now(),
        notes: notes,
      );

      final response = await SupabaseService.from(
        tableName,
      ).insert(sleep.toJson()).select().single();

      return Sleep.fromJson(response);
    } catch (e) {
      throw Exception('Uyku kaydı başlatılırken hata oluştu: $e');
    }
  }

  // Save past sleep record (with start and end times)
  static Future<Sleep> savePastSleep(
    String babyId,
    DateTime startTime,
    DateTime endTime, {
    String? notes,
  }) async {
    try {
      final sleep = Sleep(
        babyId: babyId,
        startTime: startTime,
        endTime: endTime,
        notes: notes,
      );

      final response = await SupabaseService.from(
        tableName,
      ).insert(sleep.toJson()).select().single();

      return Sleep.fromJson(response);
    } catch (e) {
      throw Exception('Geçmiş uyku kaydı kaydedilirken hata oluştu: $e');
    }
  }

  // End sleep session
  static Future<Sleep> endSleep(String sleepId) async {
    try {
      final response = await SupabaseService.from(tableName)
          .update({
            'end_time': DateTime.now().toIso8601String(),
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', sleepId)
          .select()
          .single();

      return Sleep.fromJson(response);
    } catch (e) {
      throw Exception('Uyku kaydı bitirilirken hata oluştu: $e');
    }
  }

  // Update sleep record
  static Future<Sleep> updateSleep(Sleep sleep) async {
    try {
      final response = await SupabaseService.from(
        tableName,
      ).update(sleep.toJson()).eq('id', sleep.id).select().single();

      return Sleep.fromJson(response);
    } catch (e) {
      throw Exception('Uyku kaydı güncellenirken hata oluştu: $e');
    }
  }

  // Delete sleep record
  static Future<void> deleteSleep(String sleepId) async {
    try {
      await SupabaseService.from(tableName).delete().eq('id', sleepId);
    } catch (e) {
      throw Exception('Uyku kaydı silinirken hata oluştu: $e');
    }
  }

  // Get sleep records for date range
  static Future<List<Sleep>> getSleepRecordsForDateRange(
    String babyId,
    DateTime startDate,
    DateTime endDate,
  ) async {
    try {
      final response = await SupabaseService.from(tableName)
          .select()
          .eq('baby_id', babyId)
          .gte('start_time', startDate.toIso8601String())
          .lte('start_time', endDate.toIso8601String())
          .order('start_time', ascending: false);

      return (response as List).map((json) => Sleep.fromJson(json)).toList();
    } catch (e) {
      throw Exception(
        'Tarih aralığı için uyku kayıtları yüklenirken hata oluştu: $e',
      );
    }
  }

  // Get today's sleep records
  static Future<List<Sleep>> getTodaySleepRecords(String babyId) async {
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);
    final endOfDay = DateTime(now.year, now.month, now.day, 23, 59, 59);

    return getSleepRecordsForDateRange(babyId, startOfDay, endOfDay);
  }

  // Get total sleep time for today
  static Future<Duration> getTotalSleepToday(String babyId) async {
    try {
      final sleepRecords = await getTodaySleepRecords(babyId);
      Duration totalSleep = Duration.zero;

      for (final sleep in sleepRecords) {
        if (sleep.duration != null) {
          totalSleep += sleep.duration!;
        }
      }

      return totalSleep;
    } catch (e) {
      throw Exception(
        'Günlük toplam uyku süresi hesaplanırken hata oluştu: $e',
      );
    }
  }
}
