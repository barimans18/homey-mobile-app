import 'dart:math';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/family_model.dart';

abstract class FamilyRemoteDataSource {
  Future<UserProfileModel?> getMyProfile();
  Future<FamilyModel?> getFamilyById(String familyId);
  Future<FamilyModel?> findFamilyByInviteCode(String inviteCode);
  Future<void> joinFamily({
    required String userId,
    required String familyId,
    String? fullName,
    String? role,
  });
  Future<FamilyModel> createFamily({
    required String userId,
    required String familyName,
    String? fullName,
    String? role,
  });
  Future<List<UserProfileModel>> getFamilyMembers(String familyId);
  Future<void> updateRole({required String userId, required String role});
  Future<void> updateProfile({
    required String userId,
    String? fullName,
    String? role,
  });
}

class FamilyRemoteDataSourceImpl implements FamilyRemoteDataSource {
  final SupabaseClient _client;
  static const String fallbackUserId = '6471baf6-3b32-4a9b-9ee2-6ada214e4eb2';

  FamilyRemoteDataSourceImpl({SupabaseClient? client})
      : _client = client ?? Supabase.instance.client;

  String get _currentUserId => _client.auth.currentUser?.id ?? fallbackUserId;

  @override
  Future<UserProfileModel?> getMyProfile() async {
    final uid = _currentUserId;
    final res = await _client
        .from('profiles')
        .select()
        .eq('id', uid)
        .maybeSingle();

    if (res == null) {
      // Buat profile default jika belum ada
      final newProfile = UserProfileModel(
        id: uid,
        familyId: '00000000-0000-0000-0000-000000000001',
        fullName: 'Pasutri Homey',
        role: 'suami',
      );
      await _client.from('profiles').upsert(newProfile.toJson());
      return newProfile;
    }
    return UserProfileModel.fromJson(res);
  }

  @override
  Future<FamilyModel?> getFamilyById(String familyId) async {
    final res = await _client
        .from('families')
        .select()
        .eq('id', familyId)
        .maybeSingle();

    if (res == null) return null;
    return FamilyModel.fromJson(res);
  }

  @override
  Future<FamilyModel?> findFamilyByInviteCode(String inviteCode) async {
    final cleanCode = inviteCode.trim().toUpperCase();
    final res = await _client
        .from('families')
        .select()
        .eq('invite_code', cleanCode)
        .maybeSingle();

    if (res == null) return null;
    return FamilyModel.fromJson(res);
  }

  @override
  Future<void> joinFamily({
    required String userId,
    required String familyId,
    String? fullName,
    String? role,
  }) async {
    final updateData = <String, dynamic>{'family_id': familyId};
    if (fullName != null && fullName.trim().isNotEmpty) {
      updateData['full_name'] = fullName.trim();
    }
    if (role != null) {
      updateData['role'] = role;
    }
    await _client.from('profiles').update(updateData).eq('id', userId);
  }

  @override
  Future<FamilyModel> createFamily({
    required String userId,
    required String familyName,
    String? fullName,
    String? role,
  }) async {
    final randomCode = 'HOMEY-${1000 + Random().nextInt(9000)}';
    final insertRes = await _client
        .from('families')
        .insert({
          'name': familyName,
          'invite_code': randomCode,
        })
        .select()
        .single();

    final family = FamilyModel.fromJson(insertRes);

    final updateData = <String, dynamic>{'family_id': family.id};
    if (fullName != null && fullName.trim().isNotEmpty) {
      updateData['full_name'] = fullName.trim();
    }
    if (role != null) {
      updateData['role'] = role;
    }
    await _client.from('profiles').update(updateData).eq('id', userId);

    return family;
  }

  @override
  Future<List<UserProfileModel>> getFamilyMembers(String familyId) async {
    final res = await _client
        .from('profiles')
        .select()
        .eq('family_id', familyId);

    return (res as List)
        .map((json) => UserProfileModel.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<void> updateRole({required String userId, required String role}) async {
    await _client.from('profiles').update({
      'role': role,
    }).eq('id', userId);
  }

  @override
  Future<void> updateProfile({
    required String userId,
    String? fullName,
    String? role,
  }) async {
    final updateData = <String, dynamic>{};
    if (fullName != null && fullName.trim().isNotEmpty) {
      updateData['full_name'] = fullName.trim();
    }
    if (role != null) {
      updateData['role'] = role;
    }
    if (updateData.isNotEmpty) {
      await _client.from('profiles').update(updateData).eq('id', userId);
    }
  }
}
