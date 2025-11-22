import 'package:uuid/uuid.dart';

enum DiaperType { wet, dirty, mixed }

class Diaper {
  final String id;
  final String babyId;
  final DiaperType type;
  final DateTime time;
  final String? notes;

  Diaper({
    String? id,
    required this.babyId,
    required this.type,
    required this.time,
    this.notes,
  }) : id = id ?? const Uuid().v4();

  // Copy with method for immutable updates
  Diaper copyWith({
    String? id,
    String? babyId,
    DiaperType? type,
    DateTime? time,
    String? notes,
  }) {
    return Diaper(
      id: id ?? this.id,
      babyId: babyId ?? this.babyId,
      type: type ?? this.type,
      time: time ?? this.time,
      notes: notes ?? this.notes,
    );
  }

  // JSON serialization for Supabase
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'baby_id': babyId,
      'type': type.toString().split('.').last,
      'time': time.toUtc().toIso8601String(),
      'notes': notes,
      'created_at': DateTime.now().toUtc().toIso8601String(),
      'updated_at': DateTime.now().toUtc().toIso8601String(),
    };
  }

  factory Diaper.fromJson(Map<String, dynamic> json) {
    // Parse UTC string from Supabase and convert to local time
    // Supabase stores all times in UTC (ISO8601 with 'Z' suffix)
    DateTime parseDateTime(String dateTimeStr) {
      // DateTime.parse() automatically recognizes UTC strings (ending with 'Z')
      // and creates a UTC DateTime. We convert it to local time.
      final parsed = DateTime.parse(dateTimeStr);
      // Always convert to local time - Supabase always stores UTC
      return parsed.toLocal();
    }
    
    return Diaper(
      id: json['id'] as String,
      babyId: json['baby_id'] as String,
      type: DiaperType.values.firstWhere(
        (e) => e.toString().split('.').last == json['type'],
        orElse: () => DiaperType.wet,
      ),
      time: parseDateTime(json['time'] as String),
      notes: json['notes'] as String?,
    );
  }
}
