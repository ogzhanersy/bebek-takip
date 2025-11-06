import 'package:uuid/uuid.dart';

enum Gender { male, female }

class Baby {
  final String id;
  final String? userId;
  final String name;
  final DateTime birthDate;
  final Gender gender;
  final String weight; // Current weight in kg
  final String height; // Current height in cm
  final bool isPrimary;
  final String? avatar;
  final DateTime createdAt;

  Baby({
    String? id,
    this.userId,
    required this.name,
    required this.birthDate,
    required this.gender,
    required this.weight,
    required this.height,
    this.isPrimary = false,
    this.avatar,
    DateTime? createdAt,
  }) : id = id ?? const Uuid().v4(),
       createdAt = createdAt ?? DateTime.now();

  // Copy with method for immutable updates
  Baby copyWith({
    String? id,
    String? userId,
    String? name,
    DateTime? birthDate,
    Gender? gender,
    String? weight,
    String? height,
    bool? isPrimary,
    String? avatar,
    DateTime? createdAt,
  }) {
    return Baby(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      birthDate: birthDate ?? this.birthDate,
      gender: gender ?? this.gender,
      weight: weight ?? this.weight,
      height: height ?? this.height,
      isPrimary: isPrimary ?? this.isPrimary,
      avatar: avatar ?? this.avatar,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  // JSON serialization for Supabase
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'name': name,
      'birth_date': birthDate.toIso8601String(),
      'gender': gender.toString().split('.').last,
      'weight': weight,
      'height': height,
      'is_primary': isPrimary,
      'avatar': avatar,
      'created_at': createdAt.toIso8601String(),
      'updated_at': DateTime.now().toIso8601String(),
    };
  }

  // JSON deserialization from Supabase
  factory Baby.fromJson(Map<String, dynamic> json) {
    return Baby(
      id: json['id'] as String,
      userId: json['user_id'] as String?,
      name: json['name'] as String,
      birthDate: DateTime.parse(json['birth_date'] as String),
      gender: Gender.values.firstWhere(
        (e) => e.toString().split('.').last == json['gender'],
        orElse: () => Gender.female,
      ),
      weight: json['weight'] as String,
      height: json['height'] as String,
      isPrimary: json['is_primary'] as bool? ?? false,
      avatar: json['avatar'] as String?,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
    );
  }

  // Helper getters
  String get genderText => gender == Gender.female ? 'Kız' : 'Erkek';
  String get genderEmoji => gender == Gender.female ? '👧' : '👦';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Baby && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'Baby(id: $id, name: $name, gender: $gender, isPrimary: $isPrimary)';
  }
}
