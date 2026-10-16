import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:homey/features/auth/domain/entities/user_role.dart';
import 'package:homey/features/auth/presentation/cubit/role_selection_cubit.dart';
import 'package:homey/features/auth/presentation/cubit/role_selection_state.dart';

void main() {
  group('RoleSelectionCubit Test', () {
    late RoleSelectionCubit cubit;

    setUp(() {
      cubit = RoleSelectionCubit();
    });

    tearDown(() {
      cubit.close();
    });

    test('Initial state harus RoleSelectionInitial', () {
      expect(cubit.state, equals(const RoleSelectionInitial()));
    });

    blocTest<RoleSelectionCubit, RoleSelectionState>(
      'Emits [RoleSelectionLoaded] saat memilih peran Suami',
      build: () => cubit,
      act: (c) => c.selectRole(UserRole.husband),
      expect: () => [
        const RoleSelectionLoaded(
          selectedRole: UserRole.husband,
          isConfirmed: false,
        ),
      ],
    );

    blocTest<RoleSelectionCubit, RoleSelectionState>(
      'Emits [RoleSelectionLoaded] saat memilih peran Istri',
      build: () => cubit,
      act: (c) => c.selectRole(UserRole.wife),
      expect: () => [
        const RoleSelectionLoaded(
          selectedRole: UserRole.wife,
          isConfirmed: false,
        ),
      ],
    );

    blocTest<RoleSelectionCubit, RoleSelectionState>(
      'Emits [RoleSelectionError] saat konfirmasi dilakukan tanpa memilih peran terlebih dahulu',
      build: () => cubit,
      act: (c) => c.confirmRole(),
      expect: () => [
        const RoleSelectionError('Silakan pilih peran (Suami atau Istri) terlebih dahulu.'),
      ],
    );

    blocTest<RoleSelectionCubit, RoleSelectionState>(
      'Emits [RoleSelectionLoading, RoleSelectionLoaded(isConfirmed: true)] saat konfirmasi berhasil',
      build: () => cubit,
      seed: () => const RoleSelectionLoaded(
        selectedRole: UserRole.husband,
        isConfirmed: false,
      ),
      act: (c) => c.confirmRole(),
      expect: () => [
        const RoleSelectionLoading(),
        const RoleSelectionLoaded(
          selectedRole: UserRole.husband,
          isConfirmed: true,
        ),
      ],
    );
  });
}
