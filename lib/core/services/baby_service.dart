import '../../shared/models/baby_model.dart';
import 'supabase_service.dart';

class BabyService {
  static const String tableName = 'babies';

  // Get all babies for current user
  static Future<List<Baby>> getBabies() async {
    try {
      // Get current user
      final currentUser = SupabaseService.currentUser;
      if (currentUser == null) {
        throw Exception('Kullanıcı oturumu açmamış');
      }

      final response = await SupabaseService.from(tableName)
          .select()
          .eq('user_id', currentUser.id)
          .order('created_at', ascending: false);

      return (response as List).map((json) => Baby.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Bebekler yüklenirken hata oluştu: $e');
    }
  }

  // Get primary baby
  static Future<Baby?> getPrimaryBaby() async {
    try {
      // Get current user
      final currentUser = SupabaseService.currentUser;
      if (currentUser == null) {
        throw Exception('Kullanıcı oturumu açmamış');
      }

      final response = await SupabaseService.from(tableName)
          .select()
          .eq('user_id', currentUser.id)
          .eq('is_primary', true)
          .maybeSingle();

      if (response == null) return null;
      return Baby.fromJson(response);
    } catch (e) {
      throw Exception('Ana bebek yüklenirken hata oluştu: $e');
    }
  }

  // Create new baby
  static Future<Baby> createBaby(Baby baby) async {
    try {
      // Get current user
      final currentUser = SupabaseService.currentUser;
      if (currentUser == null) {
        throw Exception('Kullanıcı oturumu açmamış');
      }

      // If this is the first baby, make it primary
      final existingBabies = await getBabies();
      final babyData = baby.copyWith(userId: currentUser.id).toJson();

      if (existingBabies.isEmpty) {
        babyData['is_primary'] = true;
      }

      final response = await SupabaseService.from(
        tableName,
      ).insert(babyData).select().single();

      return Baby.fromJson(response);
    } catch (e) {
      throw Exception('Bebek eklenirken hata oluştu: $e');
    }
  }

  // Update baby
  static Future<Baby> updateBaby(Baby baby) async {
    try {
      // Get current user
      final currentUser = SupabaseService.currentUser;
      if (currentUser == null) {
        throw Exception('Kullanıcı oturumu açmamış');
      }

      // Ensure user_id is set to current user
      final babyData = baby.copyWith(userId: currentUser.id).toJson();

      final response = await SupabaseService.from(
        tableName,
      ).update(babyData).eq('id', baby.id).select().single();

      return Baby.fromJson(response);
    } catch (e) {
      throw Exception('Bebek güncellenirken hata oluştu: $e');
    }
  }

  // Delete baby
  static Future<void> deleteBaby(String babyId) async {
    try {
      // Get current user
      final currentUser = SupabaseService.currentUser;
      if (currentUser == null) {
        throw Exception('Kullanıcı oturumu açmamış');
      }

      // First verify the baby belongs to current user
      final baby = await getBabyById(babyId);
      if (baby == null || baby.userId != currentUser.id) {
        throw Exception('Bu bebeği silme yetkiniz yok');
      }

      await SupabaseService.from(tableName).delete().eq('id', babyId);
    } catch (e) {
      throw Exception('Bebek silinirken hata oluştu: $e');
    }
  }

  // Set primary baby
  static Future<void> setPrimaryBaby(String babyId) async {
    try {
      // Get current user
      final currentUser = SupabaseService.currentUser;
      if (currentUser == null) {
        throw Exception('Kullanıcı oturumu açmamış');
      }

      // First verify the baby belongs to current user
      final baby = await getBabyById(babyId);
      if (baby == null || baby.userId != currentUser.id) {
        throw Exception('Bu bebeği ana bebek yapma yetkiniz yok');
      }

      // First, unset all primary babies for current user
      await SupabaseService.from(
        tableName,
      ).update({'is_primary': false}).eq('user_id', currentUser.id);

      // Then set the selected baby as primary
      await SupabaseService.from(tableName)
          .update({'is_primary': true})
          .eq('id', babyId)
          .eq('user_id', currentUser.id);
    } catch (e) {
      throw Exception('Ana bebek ayarlanırken hata oluştu: $e');
    }
  }

  // Get baby by id
  static Future<Baby?> getBabyById(String babyId) async {
    try {
      // Get current user
      final currentUser = SupabaseService.currentUser;
      if (currentUser == null) {
        throw Exception('Kullanıcı oturumu açmamış');
      }

      final response = await SupabaseService.from(
        tableName,
      ).select().eq('id', babyId).eq('user_id', currentUser.id).maybeSingle();

      if (response == null) return null;
      return Baby.fromJson(response);
    } catch (e) {
      throw Exception('Bebek yüklenirken hata oluştu: $e');
    }
  }
}
