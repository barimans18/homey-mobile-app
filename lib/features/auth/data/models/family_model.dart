import '../../domain/entities/family_entity.dart';

class FamilyModel extends FamilyEntity {
  const FamilyModel({
    required super.id,
    required super.name,
    required super.inviteCode,
    super.pin,
    required super.createdAt,
    super.weddingDate,
    super.husbandBirthday,
    super.wifeBirthday,
  });

  factory FamilyModel.fromJson(Map<String, dynamic> json) {
    return FamilyModel(
      id: json['id'] as String,
      name: json['name'] as String,
      inviteCode: json['invite_code'] as String,
      pin: (json['pin'] as String?) ?? '123456',
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'] as String) ?? DateTime.now()
          : DateTime.now(),
      weddingDate: json['wedding_date'] != null
          ? DateTime.tryParse(json['wedding_date'] as String)
          : null,
      husbandBirthday: json['husband_birthday'] != null
          ? DateTime.tryParse(json['husband_birthday'] as String)
          : null,
      wifeBirthday: json['wife_birthday'] != null
          ? DateTime.tryParse(json['wife_birthday'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'invite_code': inviteCode,
      'pin': pin,
      if (weddingDate != null)
        'wedding_date': weddingDate!.toIso8601String().substring(0, 10),
      if (husbandBirthday != null)
        'husband_birthday': husbandBirthday!.toIso8601String().substring(0, 10),
      if (wifeBirthday != null)
        'wife_birthday': wifeBirthday!.toIso8601String().substring(0, 10),
    };
  }
}

class UserProfileModel extends UserProfileEntity {
  const UserProfileModel({
    required super.id,
    super.familyId,
    super.fullName,
    required super.role,
    super.avatarUrl,
    super.birthDate,
  });

  factory UserProfileModel.fromJson(Map<String, dynamic> json) {
    return UserProfileModel(
      id: json['id'] as String,
      familyId: json['family_id'] as String?,
      fullName: json['full_name'] as String?,
      role: json['role'] as String? ?? 'suami',
      avatarUrl: json['avatar_url'] as String?,
      birthDate: json['birth_date'] != null
          ? DateTime.tryParse(json['birth_date'] as String)
          : null,
    );
  }

  UserProfileModel copyWith({
    String? id,
    String? familyId,
    String? fullName,
    String? role,
    String? avatarUrl,
    DateTime? birthDate,
  }) {
    return UserProfileModel(
      id: id ?? this.id,
      familyId: familyId ?? this.familyId,
      fullName: fullName ?? this.fullName,
      role: role ?? this.role,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      birthDate: birthDate ?? this.birthDate,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      if (familyId != null) 'family_id': familyId,
      if (fullName != null) 'full_name': fullName,
      'role': role,
      if (avatarUrl != null) 'avatar_url': avatarUrl,
      if (birthDate != null)
        'birth_date': birthDate!.toIso8601String().substring(0, 10),
    };
  }
}
