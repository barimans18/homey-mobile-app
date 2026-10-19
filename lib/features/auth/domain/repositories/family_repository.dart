import '../entities/family_entity.dart';

abstract class FamilyRepository {
  Future<UserProfileEntity?> getMyProfile();
  Future<FamilyEntity?> getFamilyById(String familyId);
  Future<FamilyEntity?> findFamilyByInviteCode(String inviteCode);
  Future<UserProfileEntity> joinFamily({
    required String familyId,
    required String role,
    String? fullName,
    String? userId,
  });
  Future<FamilyEntity> createFamily({
    required String familyName,
    required String pin,
    String? fullName,
    String? role,
    String? userId,
  });
  Future<void> updateFamilyPin({
    required String familyId,
    required String newPin,
  });
  Future<List<UserProfileEntity>> getFamilyMembers(String familyId);
  Future<void> updateRole({required String userId, required String role});
  Future<void> updateProfile({
    required String userId,
    String? fullName,
    String? role,
    String? avatarUrl,
  });
  Future<String> uploadAvatar({
    required String userId,
    required List<int> imageBytes,
    required String fileName,
  });
}

