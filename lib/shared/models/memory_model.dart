import 'package:uuid/uuid.dart';

enum MemoryType { photo, note, milestone, development }

class Memory {
  final String id;
  final String babyId;
  final MemoryType type;
  final String title;
  final String? description;
  final String? mediaUrl;
  final DateTime memoryDate;
  final Map<String, dynamic>? metadata; // For storing additional data like tags
  final bool isFavorite; // Favori anı özelliği
  final DateTime createdAt;
  final DateTime updatedAt;

  Memory({
    String? id,
    required this.babyId,
    required this.type,
    required this.title,
    this.description,
    this.mediaUrl,
    required this.memoryDate,
    this.metadata,
    this.isFavorite = false, // Varsayılan olarak false
    DateTime? createdAt,
    DateTime? updatedAt,
  }) : id = id ?? const Uuid().v4(),
       createdAt = createdAt ?? DateTime.now(),
       updatedAt = updatedAt ?? DateTime.now();

  // Copy with method for immutable updates
  Memory copyWith({
    String? id,
    String? babyId,
    MemoryType? type,
    String? title,
    String? description,
    String? mediaUrl,
    DateTime? memoryDate,
    Map<String, dynamic>? metadata,
    bool? isFavorite,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Memory(
      id: id ?? this.id,
      babyId: babyId ?? this.babyId,
      type: type ?? this.type,
      title: title ?? this.title,
      description: description ?? this.description,
      mediaUrl: mediaUrl ?? this.mediaUrl,
      memoryDate: memoryDate ?? this.memoryDate,
      metadata: metadata ?? this.metadata,
      isFavorite: isFavorite ?? this.isFavorite,
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
      'title': title,
      'description': description,
      'media_url': mediaUrl,
      'memory_date': memoryDate.toIso8601String(),
      'metadata': metadata,
      'is_favorite': isFavorite,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  // JSON deserialization from Supabase
  factory Memory.fromJson(Map<String, dynamic> json) {
    return Memory(
      id: json['id'] as String,
      babyId: json['baby_id'] as String,
      type: MemoryType.values.firstWhere(
        (e) => e.toString().split('.').last == json['type'],
        orElse: () => MemoryType.note,
      ),
      title: json['title'] as String,
      description: json['description'] as String?,
      mediaUrl: json['media_url'] as String?,
      memoryDate: DateTime.parse(json['memory_date'] as String),
      metadata: json['metadata'] as Map<String, dynamic>?,
      isFavorite: json['is_favorite'] as bool? ?? false,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  // Helper getters
  String get typeText {
    switch (type) {
      case MemoryType.photo:
        return 'Fotoğraf';
      case MemoryType.note:
        return 'Not';
      case MemoryType.milestone:
        return 'Kilometre Taşı';
      case MemoryType.development:
        return 'Gelişim';
    }
  }

  String get typeEmoji {
    switch (type) {
      case MemoryType.photo:
        return '📸';
      case MemoryType.note:
        return '📝';
      case MemoryType.milestone:
        return '🏆';
      case MemoryType.development:
        return '📈';
    }
  }

  bool get hasMedia => mediaUrl != null && mediaUrl!.isNotEmpty;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Memory && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'Memory(id: $id, babyId: $babyId, type: $typeText, title: $title)';
  }
}
