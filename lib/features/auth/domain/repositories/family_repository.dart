import '../entities/family_entity.dart';

abstract class FamilyRepository {
  Future<UserProfileEntity?> getMyProfile();
  Future<FamilyEntity?> getFamilyById(String familyId);
  Future<FamilyEntity?> findFamilyByInviteCode(String inviteCode);
  Future<void> joinFamily({
    required String userId,
    required String familyId,
    String? fullName,
    String? role,
  });
  Future<FamilyEntity> createFamily({
    required String userId,
    required String familyName,
    String? fullName,
    String? role,
  });
  Future<List<UserProfileEntity>> getFamilyMembers(String familyId);
  Future<void> updateRole({required String userId, required String role});
  Future<void> updateProfile({
    required String userId,
    String? fullName,
    String? role,
  });
}
