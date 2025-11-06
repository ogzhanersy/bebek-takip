import 'supabase_service.dart';

class GrowthTargets {
  final String babyId;
  final double? weightMinKg;
  final double? weightMaxKg;
  final double? heightMinCm;
  final double? heightMaxCm;

  GrowthTargets({
    required this.babyId,
    this.weightMinKg,
    this.weightMaxKg,
    this.heightMinCm,
    this.heightMaxCm,
  });

  Map<String, dynamic> toJson() => {
        'baby_id': babyId,
        'weight_min_kg': weightMinKg,
        'weight_max_kg': weightMaxKg,
        'height_min_cm': heightMinCm,
        'height_max_cm': heightMaxCm,
      };

  static GrowthTargets fromJson(Map<String, dynamic> json) => GrowthTargets(
        babyId: json['baby_id'] as String,
        weightMinKg: (json['weight_min_kg'] as num?)?.toDouble(),
        weightMaxKg: (json['weight_max_kg'] as num?)?.toDouble(),
        heightMinCm: (json['height_min_cm'] as num?)?.toDouble(),
        heightMaxCm: (json['height_max_cm'] as num?)?.toDouble(),
      );
}

class GrowthTargetService {
  static const table = 'growth_targets';

  static Future<GrowthTargets?> getTargets(String babyId) async {
    final res = await SupabaseService.from(table)
        .select()
        .eq('baby_id', babyId)
        .maybeSingle();
    if (res == null) return null;
    return GrowthTargets.fromJson(res);
  }

  static Future<void> upsertTargets(GrowthTargets t) async {
    await SupabaseService.from(table)
        .upsert(t.toJson(), onConflict: 'baby_id')
        .eq('baby_id', t.babyId);
  }
}


