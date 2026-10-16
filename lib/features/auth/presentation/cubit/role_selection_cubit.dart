import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/user_role.dart';
import 'role_selection_state.dart';

/// Cubit untuk menangani pemilihan dan konfirmasi peran (Suami / Istri)
class RoleSelectionCubit extends Cubit<RoleSelectionState> {
  RoleSelectionCubit()
      : super(const RoleSelectionLoaded(selectedRole: UserRole.husband, isConfirmed: false));

  /// Memilih salah satu peran
  void selectRole(UserRole role) {
    emit(RoleSelectionLoaded(selectedRole: role, isConfirmed: false));
  }

  /// Reset pilihan peran
  void resetSelection() {
    emit(const RoleSelectionInitial());
  }

  /// Konfirmasi peran yang dipilih (misal: sebelum submit login/register)
  Future<void> confirmRole() async {
    final currentState = state;
    if (currentState is! RoleSelectionLoaded || currentState.selectedRole == null) {
      emit(const RoleSelectionError('Silakan pilih peran (Suami atau Istri) terlebih dahulu.'));
      return;
    }

    final chosenRole = currentState.selectedRole!;
    emit(const RoleSelectionLoading());

    try {
      // Simulasi delay proses persistensi role / inisialisasi sesi
      await Future<void>.delayed(const Duration(milliseconds: 600));

      emit(RoleSelectionLoaded(
        selectedRole: chosenRole,
        isConfirmed: true,
      ));
    } catch (e) {
      emit(RoleSelectionError('Gagal menetapkan peran: ${e.toString()}'));
    }
  }
}
