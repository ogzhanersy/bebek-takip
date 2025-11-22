import '../../shared/models/physical_measurement_model.dart';
import 'supabase_service.dart';

class PhysicalMeasurementService {
  static const String tableName = 'physical_measurements';

  // Get physical measurements for a baby
  static Future<List<PhysicalMeasurement>> getMeasurements(
    String babyId, {
    int? limit,
  }) async {
    try {
      var query = SupabaseService.from(
        tableName,
      ).select().eq('baby_id', babyId).order('measured_at', ascending: false);

      if (limit != null) {
        query = query.limit(limit);
      }

      final response = await query;

      return (response as List)
          .map((json) => PhysicalMeasurement.fromJson(json))
          .toList();
    } catch (e) {
      throw Exception('Fiziksel ölçümler yüklenirken hata oluştu: $e');
    }
  }

  // Create a new physical measurement
  static Future<PhysicalMeasurement> createMeasurement(
    PhysicalMeasurement measurement,
  ) async {
    try {
      final response = await SupabaseService.from(
        tableName,
      ).insert(measurement.toJson()).select().single();

      return PhysicalMeasurement.fromJson(response);
    } catch (e) {
      throw Exception('Fiziksel ölçüm kaydedilirken hata oluştu: $e');
    }
  }

  // Update a physical measurement
  static Future<PhysicalMeasurement> updateMeasurement(
    PhysicalMeasurement measurement,
  ) async {
    try {
      final response = await SupabaseService.from(
        tableName,
      ).update(measurement.toJson()).eq('id', measurement.id).select().single();

      return PhysicalMeasurement.fromJson(response);
    } catch (e) {
      throw Exception('Fiziksel ölçüm güncellenirken hata oluştu: $e');
    }
  }

  // Delete a physical measurement
  static Future<void> deleteMeasurement(String measurementId) async {
    try {
      await SupabaseService.from(tableName).delete().eq('id', measurementId);
    } catch (e) {
      throw Exception('Fiziksel ölçüm silinirken hata oluştu: $e');
    }
  }

  // Get measurements for date range
  static Future<List<PhysicalMeasurement>> getMeasurementsForDateRange(
    String babyId,
    DateTime startDate,
    DateTime endDate,
  ) async {
    try {
      final response = await SupabaseService.from(tableName)
          .select()
          .eq('baby_id', babyId)
          .gte('measured_at', startDate.toUtc().toIso8601String())
          .lte('measured_at', endDate.toUtc().toIso8601String())
          .order('measured_at', ascending: false);

      return (response as List)
          .map((json) => PhysicalMeasurement.fromJson(json))
          .toList();
    } catch (e) {
      throw Exception(
        'Tarih aralığındaki ölçümler yüklenirken hata oluştu: $e',
      );
    }
  }

  // Get latest measurement for a baby
  static Future<PhysicalMeasurement?> getLatestMeasurement(
    String babyId,
  ) async {
    try {
      final response = await SupabaseService.from(tableName)
          .select()
          .eq('baby_id', babyId)
          .order('measured_at', ascending: false)
          .limit(1)
          .maybeSingle();

      if (response == null) return null;
      return PhysicalMeasurement.fromJson(response);
    } catch (e) {
      throw Exception('Son ölçüm yüklenirken hata oluştu: $e');
    }
  }
}
