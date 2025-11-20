import 'package:equatable/equatable.dart';

class Child extends Equatable {
  final String id;
  final String parentId;
  final String name;
  final int age;
  final String gender;
  // final String? bloodType;
  final String? medicalConditions;
  final String description;
  final String? imageUrl;
  final List<String> identifyingFeatures;
  final DateTime birthDate;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final Map<String, dynamic>? additionalInfo;

  const Child({
    required this.id,
    required this.parentId,
    required this.name,
    required this.age,
    required this.gender,
    // this.bloodType,
    this.medicalConditions,
    required this.description,
    this.imageUrl,
    this.identifyingFeatures = const [],
    required this.birthDate,
    required this.createdAt,
    this.updatedAt,
    this.additionalInfo,
  });

  factory Child.fromJson(Map<String, dynamic> json) {
    return Child(
      id: json['id'] as String,
      parentId: json['parent_id'] as String,
      name: json['name'] as String,
      age: json['age'] as int,
      gender: json['gender'] as String,
      // bloodType: json['blood_type'] as String?,
      medicalConditions: json['medical_conditions'] as String?,
      description: json['description'] as String,
      imageUrl: json['image_url'] as String?,
      identifyingFeatures: json['identifying_features'] != null
          ? List<String>.from(json['identifying_features'] as List)
          : [],
      birthDate: DateTime.parse(json['birth_date'] as String),
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : null,
      additionalInfo: json['additional_info'] as Map<String, dynamic>?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'parent_id': parentId,
      'name': name,
      'age': age,
      'gender': gender,
      // 'blood_type': bloodType,
      'medical_conditions': medicalConditions,
      'description': description,
      'image_url': imageUrl,
      'identifying_features': identifyingFeatures,
      'birth_date': birthDate.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
      'additional_info': additionalInfo,
    };
  }

  Child copyWith({
    String? id,
    String? parentId,
    String? name,
    int? age,
    String? gender,
    // String? bloodType,
    String? medicalConditions,
    String? description,
    String? imageUrl,
    List<String>? identifyingFeatures,
    DateTime? birthDate,
    DateTime? createdAt,
    DateTime? updatedAt,
    Map<String, dynamic>? additionalInfo,
  }) {
    return Child(
      id: id ?? this.id,
      parentId: parentId ?? this.parentId,
      name: name ?? this.name,
      age: age ?? this.age,
      gender: gender ?? this.gender,
      // bloodType: bloodType ?? this.bloodType,
      medicalConditions: medicalConditions ?? this.medicalConditions,
      description: description ?? this.description,
      imageUrl: imageUrl ?? this.imageUrl,
      identifyingFeatures: identifyingFeatures ?? this.identifyingFeatures,
      birthDate: birthDate ?? this.birthDate,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      additionalInfo: additionalInfo ?? this.additionalInfo,
    );
  }

  @override
  List<Object?> get props => [
    id,
    parentId,
    name,
    age,
    gender,
    // bloodType,
    medicalConditions,
    description,
    imageUrl,
    identifyingFeatures,
    birthDate,
    createdAt,
    updatedAt,
    additionalInfo,
  ];
}