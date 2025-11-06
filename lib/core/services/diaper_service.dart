import '../../shared/models/diaper_model.dart';
import 'supabase_service.dart';

class DiaperService {
  static const String tableName = 'diaper_records';

  // Get all diapers for a baby
  static Future<List<Diaper>> getDiapers(String babyId) async {
    try {
      final response = await SupabaseService.from(
        tableName,
      ).select().eq('baby_id', babyId).order('time', ascending: false);

      return (response as List)
          .map((json) => Diaper.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      rethrow;
    }
  }

  // Create a new diaper record
  static Future<Diaper> createDiaper(Diaper diaper) async {
    try {
      final response = await SupabaseService.from(
        tableName,
      ).insert(diaper.toJson()).select().single();

      return Diaper.fromJson(response);
    } catch (e) {
      rethrow;
    }
  }

  // Update a diaper record
  static Future<Diaper> updateDiaper(Diaper diaper) async {
    try {
      final response = await SupabaseService.from(
        tableName,
      ).update(diaper.toJson()).eq('id', diaper.id).select().single();

      return Diaper.fromJson(response);
    } catch (e) {
      rethrow;
    }
  }

  // Delete a diaper record
  static Future<void> deleteDiaper(String diaperId) async {
    try {
      await SupabaseService.from(tableName).delete().eq('id', diaperId);
    } catch (e) {
      rethrow;
    }
  }
}
