import 'package:uuid/uuid.dart';

class Vaccination {
  final String id;
  final String babyId;
  final String vaccineName;
  final DateTime scheduledDate;
  final DateTime? administeredDate;
  final String? location;
  final String? notes;
  final bool isCompleted;
  final DateTime createdAt;
  final DateTime updatedAt;

  Vaccination({
    String? id,
    required this.babyId,
    required this.vaccineName,
    required this.scheduledDate,
    this.administeredDate,
    this.location,
    this.notes,
    this.isCompleted = false,
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : id = id ?? const Uuid().v4(),
        createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  // Copy with method for immutable updates
  Vaccination copyWith({
    String? id,
    String? babyId,
    String? vaccineName,
    DateTime? scheduledDate,
    DateTime? administeredDate,
    String? location,
    String? notes,
    bool? isCompleted,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Vaccination(
      id: id ?? this.id,
      babyId: babyId ?? this.babyId,
      vaccineName: vaccineName ?? this.vaccineName,
      scheduledDate: scheduledDate ?? this.scheduledDate,
      administeredDate: administeredDate ?? this.administeredDate,
      location: location ?? this.location,
      notes: notes ?? this.notes,
      isCompleted: isCompleted ?? this.isCompleted,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
    );
  }

  // JSON serialization for Supabase
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'baby_id': babyId,
      'vaccine_name': vaccineName,
      'scheduled_date': scheduledDate.toUtc().toIso8601String(),
      'administered_date': administeredDate?.toUtc().toIso8601String(),
      'location': location,
      'notes': notes,
      'is_completed': isCompleted,
      'created_at': createdAt.toUtc().toIso8601String(),
      'updated_at': updatedAt.toUtc().toIso8601String(),
    };
  }

  // JSON deserialization from Supabase
  factory Vaccination.fromJson(Map<String, dynamic> json) {
    return Vaccination(
      id: json['id'] as String,
      babyId: json['baby_id'] as String,
      vaccineName: json['vaccine_name'] as String,
      scheduledDate: DateTime.parse(json['scheduled_date'] as String),
      administeredDate: json['administered_date'] != null 
          ? DateTime.parse(json['administered_date'] as String) 
          : null,
      location: json['location'] as String?,
      notes: json['notes'] as String?,
      isCompleted: json['is_completed'] as bool? ?? false,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  // Helper getters
  bool get isOverdue {
    if (isCompleted) return false;
    return DateTime.now().isAfter(scheduledDate);
  }

  bool get isDueSoon {
    if (isCompleted) return false;
    final daysUntilDue = scheduledDate.difference(DateTime.now()).inDays;
    return daysUntilDue <= 7 && daysUntilDue >= 0;
  }

  String get statusText {
    if (isCompleted) return 'Tamamlandı';
    if (isOverdue) return 'Gecikmiş';
    if (isDueSoon) return 'Yaklaşıyor';
    return 'Zamanlanmış';
  }

  String get statusEmoji {
    if (isCompleted) return '✅';
    if (isOverdue) return '🚨';
    if (isDueSoon) return '⚠️';
    return '📅';
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Vaccination && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'Vaccination(id: $id, babyId: $babyId, vaccine: $vaccineName, status: $statusText)';
  }
}
