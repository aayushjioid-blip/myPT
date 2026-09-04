enum UserRole { client, trainer, headTrainer, gymManager, superAdmin }

class UserEntity {
  final String id;
  final String name;
  final String email;
  final UserRole role;
  final String avatar;
  final String status;
  final bool sharePersonalInfoWithTrainer;
  final String? gymId;
  final int? age;
  final double? heightCm;
  final double? weightKg;
  final String? fitnessGoal;
  final String? fitnessLevel;
  final String? injuries;
  final String? medicalInfo;
  final String? emergencyContact;

  const UserEntity({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    this.avatar = '👤',
    this.status = 'ACTIVE',
    this.sharePersonalInfoWithTrainer = false,
    this.gymId,
    this.age,
    this.heightCm,
    this.weightKg,
    this.fitnessGoal,
    this.fitnessLevel,
    this.injuries,
    this.medicalInfo,
    this.emergencyContact,
  });

  UserEntity copyWith({
    String? name,
    String? email,
    UserRole? role,
    String? avatar,
    String? status,
    bool? sharePersonalInfoWithTrainer,
    String? gymId,
    int? age,
    double? heightCm,
    double? weightKg,
    String? fitnessGoal,
    String? fitnessLevel,
    String? injuries,
    String? medicalInfo,
    String? emergencyContact,
  }) {
    return UserEntity(
      id: id,
      name: name ?? this.name,
      email: email ?? this.email,
      role: role ?? this.role,
      avatar: avatar ?? this.avatar,
      status: status ?? this.status,
      sharePersonalInfoWithTrainer: sharePersonalInfoWithTrainer ?? this.sharePersonalInfoWithTrainer,
      gymId: gymId ?? this.gymId,
      age: age ?? this.age,
      heightCm: heightCm ?? this.heightCm,
      weightKg: weightKg ?? this.weightKg,
      fitnessGoal: fitnessGoal ?? this.fitnessGoal,
      fitnessLevel: fitnessLevel ?? this.fitnessLevel,
      injuries: injuries ?? this.injuries,
      medicalInfo: medicalInfo ?? this.medicalInfo,
      emergencyContact: emergencyContact ?? this.emergencyContact,
    );
  }
}
