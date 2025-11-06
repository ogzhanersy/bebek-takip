import 'package:uuid/uuid.dart';

enum FeedingType { breastfeeding, bottle, solid }

class Feeding {
  final String id;
  final String babyId;
  final FeedingType type;
  final DateTime startTime;
  final DateTime? endTime;
  final int? amount; // ml for bottle feeding
  final String? side; // left/right for breastfeeding
  final String? notes;
  final DateTime createdAt;
  final DateTime updatedAt;

  Feeding({
    String? id,
    required this.babyId,
    required this.type,
    required this.startTime,
    this.endTime,
    this.amount,
    this.side,
    this.notes,
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : id = id ?? const Uuid().v4(),
        createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  // Copy with method for immutable updates
  Feeding copyWith({
    String? id,
    String? babyId,
    FeedingType? type,
    DateTime? startTime,
    DateTime? endTime,
    int? amount,
    String? side,
    String? notes,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Feeding(
      id: id ?? this.id,
      babyId: babyId ?? this.babyId,
      type: type ?? this.type,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      amount: amount ?? this.amount,
      side: side ?? this.side,
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
      'type': type.toString().split('.').last,
      'start_time': startTime.toIso8601String(),
      'end_time': endTime?.toIso8601String(),
      'amount': amount,
      'side': side,
      'notes': notes,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  // JSON deserialization from Supabase
  factory Feeding.fromJson(Map<String, dynamic> json) {
    return Feeding(
      id: json['id'] as String,
      babyId: json['baby_id'] as String,
      type: FeedingType.values.firstWhere(
        (e) => e.toString().split('.').last == json['type'],
        orElse: () => FeedingType.breastfeeding,
      ),
      startTime: DateTime.parse(json['start_time'] as String),
      endTime: json['end_time'] != null 
          ? DateTime.parse(json['end_time'] as String) 
          : null,
      amount: json['amount'] as int?,
      side: json['side'] as String?,
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
    
    final minutes = dur.inMinutes;
    return '${minutes}dk';
  }

  String get typeText {
    switch (type) {
      case FeedingType.breastfeeding:
        return 'Emzirme';
      case FeedingType.bottle:
        return 'Biberon';
      case FeedingType.solid:
        return 'Katı Gıda';
    }
  }

  String get typeEmoji {
    switch (type) {
      case FeedingType.breastfeeding:
        return '🤱';
      case FeedingType.bottle:
        return '🍼';
      case FeedingType.solid:
        return '🥄';
    }
  }

  bool get isActive => endTime == null;

  String get displayText {
    String text = typeText;
    if (type == FeedingType.bottle && amount != null) {
      text += ' (${amount}ml)';
    }
    if (type == FeedingType.breastfeeding && side != null) {
      text += ' (${side == 'left' ? 'Sol' : 'Sağ'})';
    }
    return text;
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Feeding && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'Feeding(id: $id, babyId: $babyId, type: $typeText, duration: $durationText)';
  }
}
