import '../../shared/models/vaccination_model.dart';
import 'supabase_service.dart';

class VaccinationService {
  static const String tableName = 'vaccinations';

  // Get vaccinations for a baby
  static Future<List<Vaccination>> getVaccinations(String babyId) async {
    try {
      final response = await SupabaseService.from(
        tableName,
      ).select().eq('baby_id', babyId).order('scheduled_date', ascending: true);

      return (response as List)
          .map((json) => Vaccination.fromJson(json))
          .toList();
    } catch (e) {
      throw Exception('Aşı kayıtları yüklenirken hata oluştu: $e');
    }
  }

  // Get upcoming vaccinations
  static Future<List<Vaccination>> getUpcomingVaccinations(
    String babyId,
  ) async {
    try {
      final response = await SupabaseService.from(tableName)
          .select()
          .eq('baby_id', babyId)
          .eq('is_completed', false)
          .gte('scheduled_date', DateTime.now().toIso8601String())
          .order('scheduled_date', ascending: true);

      return (response as List)
          .map((json) => Vaccination.fromJson(json))
          .toList();
    } catch (e) {
      throw Exception('Yaklaşan aşılar yüklenirken hata oluştu: $e');
    }
  }

  // Get overdue vaccinations
  static Future<List<Vaccination>> getOverdueVaccinations(String babyId) async {
    try {
      final response = await SupabaseService.from(tableName)
          .select()
          .eq('baby_id', babyId)
          .eq('is_completed', false)
          .lt('scheduled_date', DateTime.now().toIso8601String())
          .order('scheduled_date', ascending: true);

      return (response as List)
          .map((json) => Vaccination.fromJson(json))
          .toList();
    } catch (e) {
      throw Exception('Gecikmiş aşılar yüklenirken hata oluştu: $e');
    }
  }

  // Get completed vaccinations
  static Future<List<Vaccination>> getCompletedVaccinations(
    String babyId,
  ) async {
    try {
      final response = await SupabaseService.from(tableName)
          .select()
          .eq('baby_id', babyId)
          .eq('is_completed', true)
          .order('administered_date', ascending: false);

      return (response as List)
          .map((json) => Vaccination.fromJson(json))
          .toList();
    } catch (e) {
      throw Exception('Tamamlanan aşılar yüklenirken hata oluştu: $e');
    }
  }

  // Create vaccination
  static Future<Vaccination> createVaccination(Vaccination vaccination) async {
    try {
      final response = await SupabaseService.from(
        tableName,
      ).insert(vaccination.toJson()).select().single();

      return Vaccination.fromJson(response);
    } catch (e) {
      throw Exception('Aşı kaydı oluşturulurken hata oluştu: $e');
    }
  }

  // Update vaccination
  static Future<Vaccination> updateVaccination(Vaccination vaccination) async {
    try {
      final response = await SupabaseService.from(
        tableName,
      ).update(vaccination.toJson()).eq('id', vaccination.id).select().single();

      return Vaccination.fromJson(response);
    } catch (e) {
      throw Exception('Aşı kaydı güncellenirken hata oluştu: $e');
    }
  }

  // Mark vaccination as completed
  static Future<Vaccination> markAsCompleted(
    String vaccinationId, {
    DateTime? administeredDate,
    String? location,
    String? notes,
  }) async {
    try {
      final updateData = {
        'is_completed': true,
        'administered_date': (administeredDate ?? DateTime.now())
            .toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      };

      if (location != null) updateData['location'] = location;
      if (notes != null) updateData['notes'] = notes;

      final response = await SupabaseService.from(
        tableName,
      ).update(updateData).eq('id', vaccinationId).select().single();

      return Vaccination.fromJson(response);
    } catch (e) {
      throw Exception('Aşı tamamlandı olarak işaretlenirken hata oluştu: $e');
    }
  }

  // Delete vaccination
  static Future<void> deleteVaccination(String vaccinationId) async {
    try {
      await SupabaseService.from(tableName).delete().eq('id', vaccinationId);
    } catch (e) {
      throw Exception('Aşı kaydı silinirken hata oluştu: $e');
    }
  }

  // Get vaccination statistics
  static Future<Map<String, int>> getVaccinationStats(String babyId) async {
    try {
      final allVaccinations = await getVaccinations(babyId);

      int completed = 0;
      int overdue = 0;
      int upcoming = 0;

      final now = DateTime.now();

      for (final vaccination in allVaccinations) {
        if (vaccination.isCompleted) {
          completed++;
        } else if (vaccination.scheduledDate.isBefore(now)) {
          overdue++;
        } else {
          upcoming++;
        }
      }

      return {
        'total': allVaccinations.length,
        'completed': completed,
        'overdue': overdue,
        'upcoming': upcoming,
      };
    } catch (e) {
      throw Exception('Aşı istatistikleri hesaplanırken hata oluştu: $e');
    }
  }

  // Create default vaccination schedule for baby
  static Future<List<Vaccination>> createDefaultSchedule(
    String babyId,
    DateTime birthDate,
  ) async {
    try {
      final defaultVaccines = [
        {'name': 'Hepatit B (1. doz)', 'days': 0},
        {'name': 'BCG', 'days': 60},
        {'name': 'DaBT-İPA-Hib (1. doz)', 'days': 60},
        {'name': 'KPA (1. doz)', 'days': 60},
        {'name': 'RV (1. doz)', 'days': 60},
        {'name': 'DaBT-İPA-Hib (2. doz)', 'days': 120},
        {'name': 'KPA (2. doz)', 'days': 120},
        {'name': 'RV (2. doz)', 'days': 120},
        {'name': 'DaBT-İPA-Hib (3. doz)', 'days': 180},
        {'name': 'KPA (3. doz)', 'days': 180},
        {'name': 'RV (3. doz)', 'days': 180},
        {'name': 'Hepatit B (2. doz)', 'days': 180},
        {'name': 'KPA (4. doz)', 'days': 365},
        {'name': 'KKK (1. doz)', 'days': 365},
        {'name': 'DaBT-İPA (Rapel)', 'days': 540},
        {'name': 'KKK (2. doz)', 'days': 1825},
      ];

      final vaccinations = <Vaccination>[];

      for (final vaccine in defaultVaccines) {
        final scheduledDate = birthDate.add(
          Duration(days: vaccine['days'] as int),
        );

        final vaccination = Vaccination(
          babyId: babyId,
          vaccineName: vaccine['name'] as String,
          scheduledDate: scheduledDate,
        );

        vaccinations.add(vaccination);
      }

      // Insert all vaccinations
      final insertData = vaccinations.map((v) => v.toJson()).toList();
      final response = await SupabaseService.from(
        tableName,
      ).insert(insertData).select();

      return (response as List)
          .map((json) => Vaccination.fromJson(json))
          .toList();
    } catch (e) {
      throw Exception('Varsayılan aşı programı oluşturulurken hata oluştu: $e');
    }
  }
}
