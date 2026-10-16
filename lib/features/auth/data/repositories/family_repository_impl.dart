import '../../domain/entities/family_entity.dart';
import '../../domain/repositories/family_repository.dart';
import '../datasources/family_remote_data_source.dart';

class FamilyRepositoryImpl implements FamilyRepository {
  final FamilyRemoteDataSource _remoteDataSource;

  FamilyRepositoryImpl({required FamilyRemoteDataSource remoteDataSource})
      : _remoteDataSource = remoteDataSource;

  @override
  Future<UserProfileEntity?> getMyProfile() {
    return _remoteDataSource.getMyProfile();
  }

  @override
  Future<FamilyEntity?> getFamilyById(String familyId) {
    return _remoteDataSource.getFamilyById(familyId);
  }

  @override
  Future<FamilyEntity?> findFamilyByInviteCode(String inviteCode) {
    return _remoteDataSource.findFamilyByInviteCode(inviteCode);
  }

  @override
  Future<UserProfileEntity> joinFamily({
    required String familyId,
    required String role,
    String? fullName,
    String? userId,
  }) {
    return _remoteDataSource.joinFamily(
      familyId: familyId,
      role: role,
      fullName: fullName,
      userId: userId,
    );
  }

  @override
  Future<FamilyEntity> createFamily({
    required String familyName,
    String? fullName,
    String? role,
    String? userId,
  }) {
    return _remoteDataSource.createFamily(
      familyName: familyName,
      fullName: fullName,
      role: role,
      userId: userId,
    );
  }

  @override
  Future<List<UserProfileEntity>> getFamilyMembers(String familyId) {
    return _remoteDataSource.getFamilyMembers(familyId);
  }

  @override
  Future<void> updateRole({required String userId, required String role}) {
    return _remoteDataSource.updateRole(userId: userId, role: role);
  }

  @override
  Future<void> updateProfile({
    required String userId,
    String? fullName,
    String? role,
  }) {
    return _remoteDataSource.updateProfile(
      userId: userId,
      fullName: fullName,
      role: role,
    );
  }
}
