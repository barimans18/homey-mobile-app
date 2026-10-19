import 'package:equatable/equatable.dart';

class FamilyEntity extends Equatable {
  final String id;
  final String name;
  final String inviteCode;
  final String pin;
  final DateTime createdAt;
  final DateTime? weddingDate;
  final DateTime? husbandBirthday;
  final DateTime? wifeBirthday;

  const FamilyEntity({
    required this.id,
    required this.name,
    required this.inviteCode,
    this.pin = '123456',
    required this.createdAt,
    this.weddingDate,
    this.husbandBirthday,
    this.wifeBirthday,
  });

  @override
  List<Object?> get props => [
        id,
        name,
        inviteCode,
        pin,
        createdAt,
        weddingDate,
        husbandBirthday,
        wifeBirthday,
      ];
}

class UserProfileEntity extends Equatable {
  final String id;
  final String? familyId;
  final String? fullName;
  final String role; // 'suami' atau 'istri'
  final String? avatarUrl;
  final DateTime? birthDate;

  const UserProfileEntity({
    required this.id,
    this.familyId,
    this.fullName,
    required this.role,
    this.avatarUrl,
    this.birthDate,
  });

  bool get isHusband => role == 'suami';
  bool get isWife => role == 'istri';

  @override
  List<Object?> get props => [id, familyId, fullName, role, avatarUrl, birthDate];
}
