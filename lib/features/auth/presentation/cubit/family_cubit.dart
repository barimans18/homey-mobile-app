import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/services/session_storage_service.dart';
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
    String? fullName,
    String? role,
  }) async {
    final currentState = state;
    emit(FamilyLoading());

    try {
      final profile = await _familyRepository.getMyProfile();
      if (profile == null) {
        emit(const FamilyError('Profil pengguna tidak ditemukan'));
        return;
      }

      final cleanCode = inviteCode.trim().toUpperCase();
      final family = await _familyRepository.findFamilyByInviteCode(cleanCode);

      if (family == null) {
        emit(FamilyLoaded(
          profile: profile,
          family: null,
          members: const [],
          isPairingLoading: false,
          notificationMessage: 'Kode keluarga "$cleanCode" tidak ditemukan. Periksa kembali kodenya ya.',
        ));
        return;
      }

      await _familyRepository.joinFamily(
        userId: profile.id,
        familyId: family.id,
        fullName: fullName,
        role: role,
      );

      final updatedProfile = await _familyRepository.getMyProfile();
      final members = await _familyRepository.getFamilyMembers(family.id);

      // Simpan ke local storage
      sl<SessionStorageService>().saveSession(
        userId: (updatedProfile ?? profile).id,
        role: (updatedProfile ?? profile).role,
        fullName: (updatedProfile ?? profile).fullName,
        familyId: family.id,
        familyName: family.name,
      );

      emit(FamilyLoaded(
        profile: updatedProfile ?? profile,
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
    String? fullName,
    String? role,
  }) async {
    final currentState = state;
    emit(FamilyLoading());

    try {
      final profile = await _familyRepository.getMyProfile();
      if (profile == null) {
        emit(const FamilyError('Profil pengguna tidak ditemukan'));
        return;
      }

      final newFamily = await _familyRepository.createFamily(
        userId: profile.id,
        familyName: familyName.trim().isEmpty ? 'Keluarga Kita' : familyName.trim(),
        fullName: fullName,
        role: role,
      );

      final updatedProfile = await _familyRepository.getMyProfile();
      final members = await _familyRepository.getFamilyMembers(newFamily.id);

      // Simpan ke local storage
      sl<SessionStorageService>().saveSession(
        userId: (updatedProfile ?? profile).id,
        role: (updatedProfile ?? profile).role,
        fullName: (updatedProfile ?? profile).fullName,
        familyId: newFamily.id,
        familyName: newFamily.name,
      );

      emit(FamilyLoaded(
        profile: updatedProfile ?? profile,
        family: newFamily,
        members: members,
        isPairingLoading: false,
        notificationMessage: 'Keluarga baru berhasil dibuat! Bagikan kode "${newFamily.inviteCode}" ke pasangan ya.',
      ));
    } catch (e) {
      if (currentState is FamilyLoaded) {
        emit(currentState.copyWith(
          isPairingLoading: false,
          notificationMessage: 'Gagal membuat keluarga: $e',
        ));
      } else {
        emit(FamilyError('Gagal membuat keluarga: $e'));
      }
    }
  }

  Future<void> updateProfile({String? fullName, String? role}) async {
    try {
      final profile = await _familyRepository.getMyProfile();
      if (profile == null) return;
      await _familyRepository.updateProfile(
        userId: profile.id,
        fullName: fullName,
        role: role,
      );
      await loadFamilyData();
    } catch (e) {
      final currentState = state;
      if (currentState is FamilyLoaded) {
        emit(currentState.copyWith(notificationMessage: 'Gagal update profil: $e'));
      }
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
