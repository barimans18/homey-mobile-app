import '../../domain/entities/family_entity.dart';

class FamilyModel extends FamilyEntity {
  const FamilyModel({
    required super.id,
    required super.name,
    required super.inviteCode,
    super.pin,
    required super.createdAt,
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
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'invite_code': inviteCode,
      'pin': pin,
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
  });

  factory UserProfileModel.fromJson(Map<String, dynamic> json) {
    return UserProfileModel(
      id: json['id'] as String,
      familyId: json['family_id'] as String?,
      fullName: json['full_name'] as String?,
      role: json['role'] as String? ?? 'suami',
      avatarUrl: json['avatar_url'] as String?,
    );
  }

  UserProfileModel copyWith({
    String? id,
    String? familyId,
    String? fullName,
    String? role,
    String? avatarUrl,
  }) {
    return UserProfileModel(
      id: id ?? this.id,
      familyId: familyId ?? this.familyId,
      fullName: fullName ?? this.fullName,
      role: role ?? this.role,
      avatarUrl: avatarUrl ?? this.avatarUrl,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      if (familyId != null) 'family_id': familyId,
      if (fullName != null) 'full_name': fullName,
      'role': role,
      if (avatarUrl != null) 'avatar_url': avatarUrl,
    };
  }
}
