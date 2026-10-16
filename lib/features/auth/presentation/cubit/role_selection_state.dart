import 'package:equatable/equatable.dart';
import '../../domain/entities/user_role.dart';

/// State untuk pemilihan peran (Suami / Istri)
/// Sesuai skills.md: dipisahkan menjadi Initial, Loading, Loaded, dan Error
sealed class RoleSelectionState extends Equatable {
  const RoleSelectionState();

  @override
  List<Object?> get props => [];
}

/// State awal sebelum ada role yang dipilih
class RoleSelectionInitial extends RoleSelectionState {
  const RoleSelectionInitial();
}

/// State saat memproses konfirmasi/simpan role
class RoleSelectionLoading extends RoleSelectionState {
  const RoleSelectionLoading();
}

/// State ketika peran telah dipilih atau berhasil dikonfirmasi
class RoleSelectionLoaded extends RoleSelectionState {
  final UserRole? selectedRole;
  final bool isConfirmed;

  const RoleSelectionLoaded({
    required this.selectedRole,
    this.isConfirmed = false,
  });

  RoleSelectionLoaded copyWith({
    UserRole? selectedRole,
    bool? isConfirmed,
  }) {
    return RoleSelectionLoaded(
      selectedRole: selectedRole ?? this.selectedRole,
      isConfirmed: isConfirmed ?? this.isConfirmed,
    );
  }

  @override
  List<Object?> get props => [selectedRole, isConfirmed];
}

/// State ketika terjadi error
class RoleSelectionError extends RoleSelectionState {
  final String message;

  const RoleSelectionError(this.message);

  @override
  List<Object?> get props => [message];
}
