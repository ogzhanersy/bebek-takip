import 'package:uuid/uuid.dart';

class Sleep {
  final String id;
  final String babyId;
  final DateTime startTime;
  final DateTime? endTime;
  final String? notes;
  final DateTime createdAt;
  final DateTime updatedAt;

  Sleep({
    String? id,
    required this.babyId,
    required this.startTime,
    this.endTime,
    this.notes,
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : id = id ?? const Uuid().v4(),
        createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  // Copy with method for immutable updates
  Sleep copyWith({
    String? id,
    String? babyId,
    DateTime? startTime,
    DateTime? endTime,
    String? notes,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Sleep(
      id: id ?? this.id,
      babyId: babyId ?? this.babyId,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
    );
  }

  // JSON serialization for Supabase
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'baby_id': babyId,
      'start_time': startTime.toIso8601String(),
      'end_time': endTime?.toIso8601String(),
      'notes': notes,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  // JSON deserialization from Supabase
  factory Sleep.fromJson(Map<String, dynamic> json) {
    return Sleep(
      id: json['id'] as String,
      babyId: json['baby_id'] as String,
      startTime: DateTime.parse(json['start_time'] as String),
      endTime: json['end_time'] != null 
          ? DateTime.parse(json['end_time'] as String) 
          : null,
      notes: json['notes'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  // Helper getters
  Duration? get duration {
    if (endTime == null) return null;
    return endTime!.difference(startTime);
  }

  String get durationText {
    final dur = duration;
    if (dur == null) return 'Devam ediyor...';
    
    final hours = dur.inHours;
    final minutes = dur.inMinutes.remainder(60);
    
    if (hours > 0) {
      return '${hours}s ${minutes}dk';
    } else {
      return '${minutes}dk';
    }
  }

  bool get isActive => endTime == null;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Sleep && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'Sleep(id: $id, babyId: $babyId, startTime: $startTime, duration: $durationText)';
  }
}
