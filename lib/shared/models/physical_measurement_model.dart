import 'package:uuid/uuid.dart';

class PhysicalMeasurement {
  final String id;
  final String babyId;
  final double? weight; // kg
  final double? height; // cm
  final double? headCircumference; // cm
  final String? notes;
  final DateTime measuredAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  PhysicalMeasurement({
    String? id,
    required this.babyId,
    this.weight,
    this.height,
    this.headCircumference,
    this.notes,
    required this.measuredAt,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) : id = id ?? const Uuid().v4(),
       createdAt = createdAt ?? DateTime.now(),
       updatedAt = updatedAt ?? DateTime.now();

  PhysicalMeasurement copyWith({
    String? id,
    String? babyId,
    double? weight,
    double? height,
    double? headCircumference,
    String? notes,
    DateTime? measuredAt,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return PhysicalMeasurement(
      id: id ?? this.id,
      babyId: babyId ?? this.babyId,
      weight: weight ?? this.weight,
      height: height ?? this.height,
      headCircumference: headCircumference ?? this.headCircumference,
      notes: notes ?? this.notes,
      measuredAt: measuredAt ?? this.measuredAt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'baby_id': babyId,
      'weight': weight,
      'height': height,
      'head_circumference': headCircumference,
      'notes': notes,
      'measured_at': measuredAt.toUtc().toIso8601String(),
      'created_at': createdAt.toUtc().toIso8601String(),
      'updated_at': updatedAt.toUtc().toIso8601String(),
    };
  }

  factory PhysicalMeasurement.fromJson(Map<String, dynamic> json) {
    return PhysicalMeasurement(
      id: json['id'] as String,
      babyId: json['baby_id'] as String,
      weight: json['weight'] != null
          ? (json['weight'] as num).toDouble()
          : null,
      height: json['height'] != null
          ? (json['height'] as num).toDouble()
          : null,
      headCircumference: json['head_circumference'] != null
          ? (json['head_circumference'] as num).toDouble()
          : null,
      notes: json['notes'] as String?,
      measuredAt: DateTime.parse(json['measured_at'] as String),
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  @override
  String toString() {
    return 'PhysicalMeasurement(id: $id, babyId: $babyId, weight: $weight, height: $height, headCircumference: $headCircumference, measuredAt: $measuredAt)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is PhysicalMeasurement && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
