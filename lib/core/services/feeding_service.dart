import '../../shared/models/feeding_model.dart';
import 'supabase_service.dart';

class FeedingService {
  static const String tableName = 'feeding_records';

  // Get feeding records for a baby
  static Future<List<Feeding>> getFeedingRecords(
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

      return (response as List).map((json) => Feeding.fromJson(json)).toList();
    } catch (e) {
      rethrow;
    }
  }

  // Create a new feeding record
  static Future<Feeding> createFeeding(Feeding feeding) async {
    try {
      final response = await SupabaseService.from(
        tableName,
      ).insert(feeding.toJson()).select().single();

      return Feeding.fromJson(response);
    } catch (e) {
      rethrow;
    }
  }

  // Get active feeding session
  static Future<Feeding?> getActiveFeeding(String babyId) async {
    try {
      final response = await SupabaseService.from(tableName)
          .select()
          .eq('baby_id', babyId)
          .isFilter('end_time', null)
          .order('start_time', ascending: false)
          .maybeSingle();

      if (response == null) return null;
      return Feeding.fromJson(response);
    } catch (e) {
      throw Exception('Aktif beslenme kaydı yüklenirken hata oluştu: $e');
    }
  }

  // Start feeding session
  static Future<Feeding> startFeeding(
    String babyId,
    FeedingType type, {
    int? amount,
    String? side,
    String? notes,
  }) async {
    try {
      final feeding = Feeding(
        babyId: babyId,
        type: type,
        startTime: DateTime.now(),
        amount: amount,
        side: side,
        notes: notes,
      );

      final response = await SupabaseService.from(
        tableName,
      ).insert(feeding.toJson()).select().single();

      return Feeding.fromJson(response);
    } catch (e) {
      throw Exception('Beslenme kaydı başlatılırken hata oluştu: $e');
    }
  }

  // End feeding session
  static Future<Feeding> endFeeding(String feedingId) async {
    try {
      final response = await SupabaseService.from(tableName)
          .update({
            'end_time': DateTime.now().toUtc().toIso8601String(),
            'updated_at': DateTime.now().toUtc().toIso8601String(),
          })
          .eq('id', feedingId)
          .select()
          .single();

      return Feeding.fromJson(response);
    } catch (e) {
      throw Exception('Beslenme kaydı bitirilirken hata oluştu: $e');
    }
  }

  // Add quick feeding record (with end time)
  static Future<Feeding> addQuickFeeding(
    String babyId,
    FeedingType type,
    Duration duration, {
    int? amount,
    String? side,
    String? notes,
  }) async {
    try {
      final startTime = DateTime.now().subtract(duration);
      final feeding = Feeding(
        babyId: babyId,
        type: type,
        startTime: startTime,
        endTime: DateTime.now(),
        amount: amount,
        side: side,
        notes: notes,
      );

      final response = await SupabaseService.from(
        tableName,
      ).insert(feeding.toJson()).select().single();

      return Feeding.fromJson(response);
    } catch (e) {
      throw Exception('Hızlı beslenme kaydı eklenirken hata oluştu: $e');
    }
  }

  // Update feeding record
  static Future<Feeding> updateFeeding(Feeding feeding) async {
    try {
      final response = await SupabaseService.from(
        tableName,
      ).update(feeding.toJson()).eq('id', feeding.id).select().single();

      return Feeding.fromJson(response);
    } catch (e) {
      throw Exception('Beslenme kaydı güncellenirken hata oluştu: $e');
    }
  }

  // Delete feeding record
  static Future<void> deleteFeeding(String feedingId) async {
    try {
      await SupabaseService.from(tableName).delete().eq('id', feedingId);
    } catch (e) {
      throw Exception('Beslenme kaydı silinirken hata oluştu: $e');
    }
  }

  // Get feeding records for date range
  static Future<List<Feeding>> getFeedingRecordsForDateRange(
    String babyId,
    DateTime startDate,
    DateTime endDate,
  ) async {
    try {
      final response = await SupabaseService.from(tableName)
          .select()
          .eq('baby_id', babyId)
          .gte('start_time', startDate.toUtc().toIso8601String())
          .lte('start_time', endDate.toUtc().toIso8601String())
          .order('start_time', ascending: false);

      return (response as List).map((json) => Feeding.fromJson(json)).toList();
    } catch (e) {
      throw Exception(
        'Tarih aralığı için beslenme kayıtları yüklenirken hata oluştu: $e',
      );
    }
  }

  // Get today's feeding records
  static Future<List<Feeding>> getTodayFeedingRecords(String babyId) async {
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);
    final endOfDay = DateTime(now.year, now.month, now.day, 23, 59, 59);

    return getFeedingRecordsForDateRange(babyId, startOfDay, endOfDay);
  }

  // Get feeding count by type for today
  static Future<Map<FeedingType, int>> getTodayFeedingCountByType(
    String babyId,
  ) async {
    try {
      final feedings = await getTodayFeedingRecords(babyId);
      final counts = <FeedingType, int>{
        FeedingType.breastfeeding: 0,
        FeedingType.bottle: 0,
        FeedingType.solid: 0,
      };

      for (final feeding in feedings) {
        counts[feeding.type] = (counts[feeding.type] ?? 0) + 1;
      }

      return counts;
    } catch (e) {
      throw Exception('Günlük beslenme sayısı hesaplanırken hata oluştu: $e');
    }
  }

  // Get total milk amount for today (bottle feeding)
  static Future<int> getTotalMilkToday(String babyId) async {
    try {
      final feedings = await getTodayFeedingRecords(babyId);
      int totalAmount = 0;

      for (final feeding in feedings.where(
        (f) => f.type == FeedingType.bottle,
      )) {
        if (feeding.amount != null) {
          totalAmount += feeding.amount!;
        }
      }

      return totalAmount;
    } catch (e) {
      throw Exception(
        'Günlük toplam süt miktarı hesaplanırken hata oluştu: $e',
      );
    }
  }
}
