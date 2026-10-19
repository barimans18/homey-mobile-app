import 'dart:math';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/di/injection_container.dart';
import '../../../../core/services/session_storage_service.dart';
import '../models/family_model.dart';

abstract class FamilyRemoteDataSource {
  Future<UserProfileModel?> getMyProfile();
  Future<FamilyModel?> getFamilyById(String familyId);
  Future<FamilyModel?> findFamilyByInviteCode(String inviteCode);
  Future<UserProfileModel> joinFamily({
    required String familyId,
    required String role,
    String? fullName,
    String? userId,
  });
  Future<FamilyModel> createFamily({
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
  Future<List<UserProfileModel>> getFamilyMembers(String familyId);
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

class FamilyRemoteDataSourceImpl implements FamilyRemoteDataSource {
  final SupabaseClient _client;
  static const String fallbackUserId = '6471baf6-3b32-4a9b-9ee2-6ada214e4eb2';

  FamilyRemoteDataSourceImpl({SupabaseClient? client})
      : _client = client ?? Supabase.instance.client;

  @override
  Future<UserProfileModel?> getMyProfile() async {
    // 1. Prioritaskan userId yang tersimpan di sesi lokal perangkat
    final storedUserId = sl<SessionStorageService>().getUserId();
    if (storedUserId != null && storedUserId.isNotEmpty) {
      final res = await _client
          .from('profiles')
          .select()
          .eq('id', storedUserId)
          .maybeSingle();

      if (res != null) {
        return UserProfileModel.fromJson(res);
      }
    }

    // 2. Jika tidak ada di sesi, coba dari Supabase Auth
    final authUid = _client.auth.currentUser?.id;
    if (authUid != null) {
      final res = await _client
          .from('profiles')
          .select()
          .eq('id', authUid)
          .maybeSingle();
      if (res != null) {
        return UserProfileModel.fromJson(res);
      }
    }

    // 3. Coba dari kombinasi familyId dan role yang tersimpan di sesi
    final storedFamilyId = sl<SessionStorageService>().getFamilyId();
    final storedRole = sl<SessionStorageService>().getRole();
    if (storedFamilyId != null && storedRole != null) {
      final res = await _client
          .from('profiles')
          .select()
          .eq('family_id', storedFamilyId)
          .eq('role', storedRole)
          .maybeSingle();
      if (res != null) {
        final profile = UserProfileModel.fromJson(res);
        sl<SessionStorageService>().saveSession(
          userId: profile.id,
          role: profile.role,
          fullName: profile.fullName,
          familyId: profile.familyId,
        );
        return profile;
      }
    }

    // 4. Fallback ke profil pertama yang ada di database
    final res = await _client
        .from('profiles')
        .select()
        .eq('id', fallbackUserId)
        .maybeSingle();

    if (res != null) {
      return UserProfileModel.fromJson(res);
    }

    return null;
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
  Future<UserProfileModel> joinFamily({
    required String familyId,
    required String role,
    String? fullName,
    String? userId,
  }) async {
    final normalizedRole = role.toLowerCase().trim();

    // 1. Cek apakah di keluarga ini sudah ada profil untuk peran ini
    final existingRes = await _client
        .from('profiles')
        .select()
        .eq('family_id', familyId)
        .eq('role', normalizedRole)
        .maybeSingle();

    if (existingRes != null) {
      final existingProfile = UserProfileModel.fromJson(existingRes);
      if (fullName != null && fullName.trim().isNotEmpty) {
        await _client
            .from('profiles')
            .update({'full_name': fullName.trim()})
            .eq('id', existingProfile.id);
        return existingProfile.copyWith(fullName: fullName.trim());
      }
      return existingProfile;
    }

    // 2. Jika belum ada profil peran ini di keluarga tersebut, buat baru
    String targetId = userId ?? const Uuid().v4();
    final idTaken = await _client
        .from('profiles')
        .select('id')
        .eq('id', targetId)
        .maybeSingle();

    if (idTaken != null) {
      targetId = const Uuid().v4();
    }

    final newProfile = UserProfileModel(
      id: targetId,
      familyId: familyId,
      fullName: (fullName != null && fullName.trim().isNotEmpty)
          ? fullName.trim()
          : (normalizedRole == 'suami' ? 'Suami' : 'Istri'),
      role: normalizedRole,
    );

    await _client.from('profiles').insert(newProfile.toJson());
    return newProfile;
  }

  @override
  Future<FamilyModel> createFamily({
    required String familyName,
    required String pin,
    String? fullName,
    String? role,
    String? userId,
  }) async {
    final cleanPin = pin.trim().isNotEmpty ? pin.trim() : '123456';
    final randomCode = 'HOMEY-${1000 + Random().nextInt(9000)}';
    final insertRes = await _client
        .from('families')
        .insert({
          'name': familyName,
          'invite_code': randomCode,
          'pin': cleanPin,
        })
        .select()
        .single();

    final family = FamilyModel.fromJson(insertRes);
    final normalizedRole = (role ?? 'suami').toLowerCase().trim();

    String targetId = userId ?? const Uuid().v4();
    final idTaken = await _client
        .from('profiles')
        .select('id')
        .eq('id', targetId)
        .maybeSingle();

    if (idTaken != null) {
      targetId = const Uuid().v4();
    }

    final newProfile = UserProfileModel(
      id: targetId,
      familyId: family.id,
      fullName: (fullName != null && fullName.trim().isNotEmpty)
          ? fullName.trim()
          : (normalizedRole == 'suami' ? 'Suami' : 'Istri'),
      role: normalizedRole,
    );

    await _client.from('profiles').insert(newProfile.toJson());

    // Simpan ke sesi lokal
    sl<SessionStorageService>().saveSession(
      userId: newProfile.id,
      role: newProfile.role,
      fullName: newProfile.fullName,
      familyId: family.id,
      familyName: family.name,
      familyPin: family.pin,
    );

    return family;
  }

  @override
  Future<void> updateFamilyPin({
    required String familyId,
    required String newPin,
  }) async {
    final cleanPin = newPin.trim();
    if (cleanPin.length != 6 || int.tryParse(cleanPin) == null) {
      throw Exception('PIN keluarga harus berupa 6 digit angka');
    }
    await _client.from('families').update({'pin': cleanPin}).eq('id', familyId);
    final storage = sl<SessionStorageService>();
    if (storage.getFamilyId() == familyId) {
      storage.saveSession(
        userId: storage.getUserId() ?? '',
        role: storage.getRole() ?? '',
        fullName: storage.getFullName(),
        familyId: familyId,
        familyName: storage.getFamilyName(),
        familyPin: cleanPin,
        avatarUrl: storage.getAvatarUrl(),
      );
    }
  }

  @override
  Future<List<UserProfileModel>> getFamilyMembers(String familyId) async {
    final res = await _client
        .from('profiles')
        .select()
        .eq('family_id', familyId)
        .order('role', ascending: false);

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
    String? avatarUrl,
  }) async {
    final updateData = <String, dynamic>{};
    if (fullName != null && fullName.trim().isNotEmpty) {
      updateData['full_name'] = fullName.trim();
    }
    if (role != null) {
      updateData['role'] = role;
    }
    if (avatarUrl != null) {
      updateData['avatar_url'] = avatarUrl;
    }
    if (updateData.isNotEmpty) {
      await _client.from('profiles').update(updateData).eq('id', userId);
    }
  }

  @override
  Future<String> uploadAvatar({
    required String userId,
    required List<int> imageBytes,
    required String fileName,
  }) async {
    final cleanFileName = fileName.replaceAll(RegExp(r'[^a-zA-Z0-9._-]'), '_');
    final path = 'user_$userId/$cleanFileName';

    await _client.storage.from('avatars').uploadBinary(
      path,
      imageBytes as dynamic,
      fileOptions: const FileOptions(
        contentType: 'image/jpeg',
        upsert: true,
      ),
    );

    final publicUrl = _client.storage.from('avatars').getPublicUrl(path);
    final freshUrl = '$publicUrl?t=${DateTime.now().millisecondsSinceEpoch}';
    return freshUrl;
  }
}

