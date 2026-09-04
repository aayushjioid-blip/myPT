import '../../domain/entities/user_entity.dart';

class UserModel {
  final String id;
  final String? authId;
  final String email;
  final String? phone;
  final String name;
  final String? avatarUrl;
  final UserRole role;
  final bool isActive;
  final bool sharePersonalInfoWithTrainer;
  final int? age;
  final double? heightCm;
  final double? weightKg;
  final String? fitnessGoal;
  final String? injuries;
  final String? medicalInfo;
  final String? emergencyContact;
  final DateTime createdAt;
  final DateTime updatedAt;

  UserModel({
    required this.id,
    this.authId,
    required this.email,
    this.phone,
    required this.name,
    this.avatarUrl,
    required this.role,
    this.isActive = true,
    this.sharePersonalInfoWithTrainer = false,
    this.age,
    this.heightCm,
    this.weightKg,
    this.fitnessGoal,
    this.injuries,
    this.medicalInfo,
    this.emergencyContact,
    required this.createdAt,
    required this.updatedAt,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    UserRole parsedRole;
    switch (json['role']?.toString().toUpperCase()) {
      case 'SUPER_ADMIN':
        parsedRole = UserRole.superAdmin;
        break;
      case 'GYM_MANAGER':
        parsedRole = UserRole.gymManager;
        break;
      case 'HEAD_TRAINER':
        parsedRole = UserRole.headTrainer;
        break;
      case 'TRAINER':
        parsedRole = UserRole.trainer;
        break;
      case 'CLIENT':
      default:
        parsedRole = UserRole.client;
    }

    final health = json['client_health_profiles'] is List && (json['client_health_profiles'] as List).isNotEmpty
        ? (json['client_health_profiles'] as List).first as Map<String, dynamic>
        : (json['client_health_profiles'] is Map<String, dynamic>
            ? json['client_health_profiles'] as Map<String, dynamic>
            : <String, dynamic>{});

    return UserModel(
      id: json['id']?.toString() ?? '',
      authId: json['auth_id']?.toString(),
      email: json['email']?.toString() ?? '',
      phone: json['phone']?.toString(),
      name: json['name']?.toString() ?? '',
      avatarUrl: json['avatar_url']?.toString(),
      role: parsedRole,
      isActive: json['is_active'] ?? true,
      sharePersonalInfoWithTrainer: health['share_personal_info_with_trainer'] ?? json['share_personal_info_with_trainer'] ?? false,
      age: health['age'] as int?,
      heightCm: health['height_cm'] != null ? double.tryParse(health['height_cm'].toString()) : null,
      weightKg: health['weight_kg'] != null ? double.tryParse(health['weight_kg'].toString()) : null,
      fitnessGoal: health['fitness_goal']?.toString(),
      injuries: health['injuries']?.toString(),
      medicalInfo: health['medical_info']?.toString(),
      emergencyContact: health['emergency_contact_phone']?.toString(),
      createdAt: json['created_at'] != null ? DateTime.parse(json['created_at'].toString()).toLocal() : DateTime.now(),
      updatedAt: json['updated_at'] != null ? DateTime.parse(json['updated_at'].toString()).toLocal() : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      if (authId != null) 'auth_id': authId,
      'email': email,
      if (phone != null) 'phone': phone,
      'name': name,
      if (avatarUrl != null) 'avatar_url': avatarUrl,
      'role': role.name.toUpperCase(),
      'is_active': isActive,
      'created_at': createdAt.toUtc().toIso8601String(),
      'updated_at': updatedAt.toUtc().toIso8601String(),
    };
  }

  UserEntity toEntity() {
    return UserEntity(
      id: id,
      name: name,
      email: email,
      role: role,
      avatar: avatarUrl ?? (role == UserRole.client ? '👩' : (role == UserRole.trainer ? '🏋️' : '👤')),
      sharePersonalInfoWithTrainer: sharePersonalInfoWithTrainer,
      age: age,
      heightCm: heightCm,
      weightKg: weightKg,
      fitnessGoal: fitnessGoal,
      injuries: injuries,
      medicalInfo: medicalInfo,
      emergencyContact: emergencyContact,
    );
  }
}
