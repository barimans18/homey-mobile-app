import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/services/session_storage_service.dart';
import '../../domain/entities/family_entity.dart';
import '../../domain/repositories/family_repository.dart';
import 'family_state.dart';

class FamilyCubit extends Cubit<FamilyState> {
  final FamilyRepository _familyRepository;

  FamilyCubit({required FamilyRepository familyRepository})
      : _familyRepository = familyRepository,
        super(const FamilyInitial());

  Future<void> loadFamilyData() async {
    emit(const FamilyLoading());
    try {
      final profile = await _familyRepository.getMyProfile();
      if (profile == null) {
        emit(const FamilyError('Profil pengguna tidak ditemukan'));
        return;
      }

      if (profile.familyId != null && profile.familyId!.isNotEmpty) {
        final family = await _familyRepository.getFamilyById(profile.familyId!);
        final members = await _familyRepository.getFamilyMembers(profile.familyId!);

        // Simpan sesi ke Local Storage
        if (family != null) {
          sl<SessionStorageService>().saveSession(
            userId: profile.id,
            role: profile.role,
            fullName: profile.fullName,
            familyId: family.id,
            familyName: family.name,
            familyPin: family.pin,
          );
        }

        emit(FamilyLoaded(
          profile: profile,
          family: family,
          members: members,
        ));
      } else {
        emit(FamilyLoaded(
          profile: profile,
          family: null,
          members: const [],
        ));
      }
    } catch (e) {
      emit(FamilyError('Gagal memuat data keluarga: $e'));
    }
  }

  Future<void> joinFamilyByCode(
    String inviteCode, {
    required String pin,
    String? fullName,
    String? role,
  }) async {
    final currentState = state;
    emit(const FamilyLoading());

    try {
      final cleanCode = inviteCode.trim().toUpperCase();
      final cleanPin = pin.trim();

      if (cleanPin.length != 6 || int.tryParse(cleanPin) == null) {
        final profile = await _familyRepository.getMyProfile();
        emit(FamilyLoaded(
          profile: profile ??
              UserProfileEntity(
                id: 'anon',
                role: role ?? 'istri',
                fullName: fullName,
              ),
          family: null,
          members: const [],
          isPairingLoading: false,
          notificationMessage: 'PIN keluarga harus berupa 6 digit angka.',
        ));
        return;
      }

      final family = await _familyRepository.findFamilyByInviteCode(cleanCode);

      if (family == null) {
        final profile = await _familyRepository.getMyProfile();
        emit(FamilyLoaded(
          profile: profile ??
              UserProfileEntity(
                id: 'anon',
                role: role ?? 'istri',
                fullName: fullName,
              ),
          family: null,
          members: const [],
          isPairingLoading: false,
          notificationMessage: 'Kode keluarga "$cleanCode" tidak ditemukan. Periksa kembali kodenya ya.',
        ));
        return;
      }

      // Validasi PIN keluarga
      if (family.pin.isNotEmpty && family.pin != cleanPin) {
        final profile = await _familyRepository.getMyProfile();
        emit(FamilyLoaded(
          profile: profile ??
              UserProfileEntity(
                id: 'anon',
                role: role ?? 'istri',
                fullName: fullName,
              ),
          family: null,
          members: const [],
          isPairingLoading: false,
          notificationMessage: 'PIN keluarga tidak sesuai. Silakan minta 6 digit PIN ke pasangan Anda.',
        ));
        return;
      }

      final joinedProfile = await _familyRepository.joinFamily(
        familyId: family.id,
        role: role ?? 'istri',
        fullName: fullName,
      );

      final members = await _familyRepository.getFamilyMembers(family.id);

      // Simpan ke local storage
      sl<SessionStorageService>().saveSession(
        userId: joinedProfile.id,
        role: joinedProfile.role,
        fullName: joinedProfile.fullName,
        familyId: family.id,
        familyName: family.name,
        familyPin: family.pin,
      );

      emit(FamilyLoaded(
        profile: joinedProfile,
        family: family,
        members: members,
        isPairingLoading: false,
        notificationMessage: 'Yeay! Berhasil terhubung dengan ${family.name}! 🎉',
      ));
    } catch (e) {
      if (currentState is FamilyLoaded) {
        emit(currentState.copyWith(
          isPairingLoading: false,
          notificationMessage: 'Terjadi kesalahan saat menghubungkan: $e',
        ));
      } else {
        emit(FamilyError('Gagal menghubungkan keluarga: $e'));
      }
    }
  }

  Future<void> createFamily(
    String familyName, {
    required String pin,
    String? fullName,
    String? role,
  }) async {
    final currentState = state;
    emit(const FamilyLoading());

    try {
      final cleanPin = pin.trim();
      if (cleanPin.length != 6 || int.tryParse(cleanPin) == null) {
        final profile = await _familyRepository.getMyProfile();
        emit(FamilyLoaded(
          profile: profile ??
              UserProfileEntity(
                id: 'anon',
                role: role ?? 'suami',
                fullName: fullName,
              ),
          family: null,
          members: const [],
          isPairingLoading: false,
          notificationMessage: 'PIN keluarga harus berupa 6 digit angka.',
        ));
        return;
      }

      final newFamily = await _familyRepository.createFamily(
        familyName: familyName.trim().isEmpty ? 'Keluarga Kita' : familyName.trim(),
        pin: cleanPin,
        fullName: fullName,
        role: role,
      );

      final profile = await _familyRepository.getMyProfile();
      final members = await _familyRepository.getFamilyMembers(newFamily.id);

      emit(FamilyLoaded(
        profile: profile ??
            UserProfileEntity(
              id: 'anon',
              role: role ?? 'suami',
              fullName: fullName,
            ),
        family: newFamily,
        members: members,
        isPairingLoading: false,
        notificationMessage: 'Keluarga baru berhasil dibuat! Bagikan kode "${newFamily.inviteCode}" dan PIN 6 digit ke pasangan ya.',
      ));
    } catch (e) {
      if (currentState is FamilyLoaded) {
        emit(currentState.copyWith(
          isPairingLoading: false,
          notificationMessage: 'Terjadi kesalahan saat membuat keluarga: $e',
        ));
      } else {
        emit(FamilyError('Gagal membuat keluarga: $e'));
      }
    }
  }

  Future<void> updateFamilyPin(String newPin) async {
    final currentState = state;
    if (currentState is! FamilyLoaded || currentState.family == null) return;

    final cleanPin = newPin.trim();
    if (cleanPin.length != 6 || int.tryParse(cleanPin) == null) {
      emit(currentState.copyWith(
        notificationMessage: 'PIN baru harus terdiri dari 6 digit angka.',
      ));
      return;
    }

    try {
      await _familyRepository.updateFamilyPin(
        familyId: currentState.family!.id,
        newPin: cleanPin,
      );
      await loadFamilyData();
      final updatedState = state;
      if (updatedState is FamilyLoaded) {
        emit(updatedState.copyWith(
          notificationMessage: 'PIN keluarga berhasil diperbarui! 🎉',
        ));
      }
    } catch (e) {
      emit(currentState.copyWith(
        notificationMessage: 'Gagal memperbarui PIN keluarga: $e',
      ));
    }
  }

  Future<void> updateProfile({
    String? fullName,
    String? role,
    String? avatarUrl,
  }) async {
    try {
      final profile = await _familyRepository.getMyProfile();
      if (profile == null) return;
      await _familyRepository.updateProfile(
        userId: profile.id,
        fullName: fullName,
        role: role,
        avatarUrl: avatarUrl,
      );
      // Update sesi lokal
      sl<SessionStorageService>().saveSession(
        userId: profile.id,
        role: role ?? profile.role,
        fullName: fullName ?? profile.fullName,
        familyId: profile.familyId,
        avatarUrl: avatarUrl ?? profile.avatarUrl,
      );
      await loadFamilyData();
    } catch (e) {
      final currentState = state;
      if (currentState is FamilyLoaded) {
        emit(currentState.copyWith(notificationMessage: 'Gagal update profil: $e'));
      }
    }
  }

  Future<String?> uploadAvatar({
    required List<int> imageBytes,
    required String fileName,
  }) async {
    try {
      final profile = await _familyRepository.getMyProfile();
      if (profile == null) return null;
      final url = await _familyRepository.uploadAvatar(
        userId: profile.id,
        imageBytes: imageBytes,
        fileName: fileName,
      );
      await updateProfile(avatarUrl: url);
      return url;
    } catch (e) {
      final currentState = state;
      if (currentState is FamilyLoaded) {
        emit(currentState.copyWith(notificationMessage: 'Gagal mengupload foto: $e'));
      }
      return null;
    }
  }

  Future<void> updateRole(String newRole) async {
    final currentState = state;
    if (currentState is! FamilyLoaded) return;

    try {
      await _familyRepository.updateRole(
        userId: currentState.profile.id,
        role: newRole,
      );
      await loadFamilyData();
    } catch (e) {
      emit(currentState.copyWith(
        notificationMessage: 'Gagal memperbarui peran: $e',
      ));
    }
  }
}
