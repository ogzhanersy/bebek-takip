import 'dart:io';
import '../../shared/models/memory_model.dart';
import 'supabase_service.dart';

class MemoryService {
  static const String tableName = 'memories';

  // Get memories for a baby
  static Future<List<Memory>> getMemories(String babyId, {int? limit}) async {
    try {
      var query = SupabaseService.from(
        tableName,
      ).select().eq('baby_id', babyId).order('memory_date', ascending: false);

      if (limit != null) {
        query = query.limit(limit);
      }

      final response = await query;

      return (response as List).map((json) => Memory.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Anılar yüklenirken hata oluştu: $e');
    }
  }

  // Get memory by ID
  static Future<Memory?> getMemoryById(String memoryId) async {
    try {
      final response = await SupabaseService.from(
        tableName,
      ).select().eq('id', memoryId).maybeSingle();

      if (response == null) return null;
      return Memory.fromJson(response);
    } catch (e) {
      throw Exception('Anı yüklenirken hata oluştu: $e');
    }
  }

  // Get memories by type
  static Future<List<Memory>> getMemoriesByType(
    String babyId,
    MemoryType type,
  ) async {
    try {
      final response = await SupabaseService.from(tableName)
          .select()
          .eq('baby_id', babyId)
          .eq('type', type.toString().split('.').last)
          .order('memory_date', ascending: false);

      return (response as List).map((json) => Memory.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Anılar (türe göre) yüklenirken hata oluştu: $e');
    }
  }

  // Get memories for date range
  static Future<List<Memory>> getMemoriesForDateRange(
    String babyId,
    DateTime startDate,
    DateTime endDate,
  ) async {
    try {
      final response = await SupabaseService.from(tableName)
          .select()
          .eq('baby_id', babyId)
          .gte('memory_date', startDate.toIso8601String())
          .lte('memory_date', endDate.toIso8601String())
          .order('memory_date', ascending: false);

      return (response as List).map((json) => Memory.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Tarih aralığı için anılar yüklenirken hata oluştu: $e');
    }
  }

  // Create memory
  static Future<Memory> createMemory(Memory memory) async {
    try {
      final response = await SupabaseService.from(
        tableName,
      ).insert(memory.toJson()).select().single();

      return Memory.fromJson(response);
    } catch (e) {
      throw Exception('Anı oluşturulurken hata oluştu: $e');
    }
  }

  // Update memory
  static Future<Memory> updateMemory(Memory memory) async {
    try {
      final response = await SupabaseService.from(
        tableName,
      ).update(memory.toJson()).eq('id', memory.id).select().single();

      return Memory.fromJson(response);
    } catch (e) {
      throw Exception('Anı güncellenirken hata oluştu: $e');
    }
  }

  // Delete memory
  static Future<void> deleteMemory(String memoryId) async {
    try {
      await SupabaseService.from(tableName).delete().eq('id', memoryId);
    } catch (e) {
      throw Exception('Anı silinirken hata oluştu: $e');
    }
  }

  // Upload memory media
  static Future<String> uploadMemoryMedia(
    String memoryId,
    String filePath,
  ) async {
    try {
      final file = File(filePath);
      final fileName =
          'memory_${memoryId}_${DateTime.now().millisecondsSinceEpoch}${file.path.split('.').last}';

      // Create user-specific folder structure: memories/user_id/memory_id/filename
      final currentUser = SupabaseService.currentUser;
      if (currentUser == null) {
        throw Exception('Kullanıcı oturumu bulunamadı');
      }

      final folderPath = '${currentUser.id}/$fileName';

      await SupabaseService.storage.from('memories').upload(folderPath, file);

      final publicUrl = SupabaseService.storage
          .from('memories')
          .getPublicUrl(folderPath);

      return publicUrl;
    } catch (e) {
      throw Exception('Medya yüklenirken hata oluştu: $e');
    }
  }

  // Delete memory media
  static Future<void> deleteMemoryMedia(String mediaUrl) async {
    try {
      // Extract the file path from URL
      final urlParts = mediaUrl.split('/');
      final fileName = urlParts.last;
      final userId = urlParts[urlParts.length - 2]; // user_id is second to last

      final filePath = '$userId/$fileName';

      await SupabaseService.storage.from('memories').remove([filePath]);
    } catch (e) {
      throw Exception('Medya silinirken hata oluştu: $e');
    }
  }

  // Get recent milestones
  static Future<List<Memory>> getRecentMilestones(
    String babyId, {
    int limit = 5,
  }) async {
    try {
      final response = await SupabaseService.from(tableName)
          .select()
          .eq('baby_id', babyId)
          .eq('type', MemoryType.milestone.toString().split('.').last)
          .order('memory_date', ascending: false)
          .limit(limit);

      return (response as List).map((json) => Memory.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Son kilometre taşları yüklenirken hata oluştu: $e');
    }
  }

  // Get memory count by type
  static Future<Map<MemoryType, int>> getMemoryCountByType(
    String babyId,
  ) async {
    try {
      final memories = await getMemories(babyId);
      final counts = <MemoryType, int>{
        MemoryType.photo: 0,
        MemoryType.note: 0,
        MemoryType.milestone: 0,
        MemoryType.development: 0,
      };

      for (final memory in memories) {
        counts[memory.type] = (counts[memory.type] ?? 0) + 1;
      }

      return counts;
    } catch (e) {
      throw Exception('Anı sayıları hesaplanırken hata oluştu: $e');
    }
  }

  // Search memories
  static Future<List<Memory>> searchMemories(
    String babyId,
    String searchTerm,
  ) async {
    try {
      final response = await SupabaseService.from(tableName)
          .select()
          .eq('baby_id', babyId)
          .or('title.ilike.%$searchTerm%,description.ilike.%$searchTerm%')
          .order('memory_date', ascending: false);

      return (response as List).map((json) => Memory.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Anı arama sırasında hata oluştu: $e');
    }
  }

  // Create memory with media upload
  static Future<Memory> createMemoryWithMedia(
    Memory memory,
    File? mediaFile,
  ) async {
    try {
      String? mediaUrl;

      // Upload media if provided
      if (mediaFile != null) {
        mediaUrl = await uploadMemoryMedia(memory.id, mediaFile.path);
      }

      // Create memory with media URL
      final memoryWithMedia = memory.copyWith(mediaUrl: mediaUrl);
      return await createMemory(memoryWithMedia);
    } catch (e) {
      throw Exception('Anı ve medya oluşturulurken hata oluştu: $e');
    }
  }

  // Update memory with media upload
  static Future<Memory> updateMemoryWithMedia(
    Memory memory,
    File? mediaFile,
  ) async {
    try {
      String? mediaUrl = memory.mediaUrl;

      // Upload new media if provided
      if (mediaFile != null) {
        // Delete old media if exists
        if (mediaUrl != null) {
          await deleteMemoryMedia(mediaUrl);
        }

        // Upload new media
        mediaUrl = await uploadMemoryMedia(memory.id, mediaFile.path);
      }

      // Update memory with new media URL
      final updatedMemory = memory.copyWith(
        mediaUrl: mediaUrl,
        updatedAt: DateTime.now(),
      );

      return await updateMemory(updatedMemory);
    } catch (e) {
      throw Exception('Anı ve medya güncellenirken hata oluştu: $e');
    }
  }

  // Get favorite memories
  static Future<List<Memory>> getFavoriteMemories(String babyId) async {
    try {
      final response = await SupabaseService.from(tableName)
          .select()
          .eq('baby_id', babyId)
          .eq('is_favorite', true)
          .order('memory_date', ascending: false);

      return (response as List).map((json) => Memory.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Favori anılar yüklenirken hata oluştu: $e');
    }
  }

  // Toggle favorite status
  static Future<Memory> toggleFavorite(String memoryId) async {
    try {
      // Get current memory
      final currentMemory = await SupabaseService.from(
        tableName,
      ).select().eq('id', memoryId).single();

      final memory = Memory.fromJson(currentMemory);

      // Toggle favorite status
      final updatedMemory = memory.copyWith(
        isFavorite: !memory.isFavorite,
        updatedAt: DateTime.now(),
      );

      return await updateMemory(updatedMemory);
    } catch (e) {
      throw Exception('Favori durumu değiştirilirken hata oluştu: $e');
    }
  }

  // Get memories by date range with filters
  static Future<List<Memory>> getMemoriesWithFilters(
    String babyId, {
    MemoryType? type,
    DateTime? startDate,
    DateTime? endDate,
    bool? isFavorite,
    String? searchTerm,
    String sortBy = 'memory_date',
    bool ascending = false,
    int? limit,
  }) async {
    try {
      // Build base query
      var query = SupabaseService.from(
        tableName,
      ).select().eq('baby_id', babyId);

      // Apply filters
      if (type != null) {
        query = query.eq('type', type.toString().split('.').last);
      }

      if (startDate != null) {
        query = query.gte('memory_date', startDate.toIso8601String());
      }

      if (endDate != null) {
        query = query.lte('memory_date', endDate.toIso8601String());
      }

      if (isFavorite != null) {
        query = query.eq('is_favorite', isFavorite);
      }

      // Handle search term - apply it last to avoid type issues
      if (searchTerm != null && searchTerm.isNotEmpty) {
        query = query.or(
          'title.ilike.%$searchTerm%,description.ilike.%$searchTerm%',
        );
        // After or(), we need to rebuild the query for sorting and limiting
        final searchResponse = await query;
        var memories = (searchResponse as List)
            .map((json) => Memory.fromJson(json))
            .toList();

        // Apply sorting manually
        memories.sort((a, b) {
          switch (sortBy) {
            case 'memory_date':
              return ascending
                  ? a.memoryDate.compareTo(b.memoryDate)
                  : b.memoryDate.compareTo(a.memoryDate);
            case 'title':
              return ascending
                  ? a.title.compareTo(b.title)
                  : b.title.compareTo(a.title);
            case 'created_at':
              return ascending
                  ? a.createdAt.compareTo(b.createdAt)
                  : b.createdAt.compareTo(a.createdAt);
            default:
              return ascending
                  ? a.memoryDate.compareTo(b.memoryDate)
                  : b.memoryDate.compareTo(a.memoryDate);
          }
        });

        // Apply limit manually
        if (limit != null && limit < memories.length) {
          memories = memories.take(limit).toList();
        }

        return memories;
      }

      // Apply sorting and limit for non-search queries
      var finalQuery = query.order(sortBy, ascending: ascending);

      if (limit != null) {
        finalQuery = finalQuery.limit(limit);
      }

      final response = await finalQuery;
      return (response as List).map((json) => Memory.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Filtrelenmiş anılar yüklenirken hata oluştu: $e');
    }
  }
}
