import 'package:equatable/equatable.dart';

class FamilyEntity extends Equatable {
  final String id;
  final String name;
  final String inviteCode;
  final DateTime createdAt;

  const FamilyEntity({
    required this.id,
    required this.name,
    required this.inviteCode,
    required this.createdAt,
  });

  @override
  List<Object?> get props => [id, name, inviteCode, createdAt];
}

class UserProfileEntity extends Equatable {
  final String id;
  final String? familyId;
  final String? fullName;
  final String role; // 'suami' atau 'istri'
  final String? avatarUrl;

  const UserProfileEntity({
    required this.id,
    this.familyId,
    this.fullName,
    required this.role,
    this.avatarUrl,
  });

  bool get isHusband => role == 'suami';
  bool get isWife => role == 'istri';

  @override
  List<Object?> get props => [id, familyId, fullName, role, avatarUrl];
}
