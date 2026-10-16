import 'package:equatable/equatable.dart';
import '../../domain/entities/family_entity.dart';

abstract class FamilyState extends Equatable {
  const FamilyState();

  @override
  List<Object?> get props => [];
}

class FamilyInitial extends FamilyState {
  const FamilyInitial();
}

class FamilyLoading extends FamilyState {
  const FamilyLoading();
}

class FamilyLoaded extends FamilyState {
  final UserProfileEntity profile;
  final FamilyEntity? family;
  final List<UserProfileEntity> members;
  final bool isPairingLoading;
  final String? notificationMessage;

  const FamilyLoaded({
    required this.profile,
    this.family,
    this.members = const [],
    this.isPairingLoading = false,
    this.notificationMessage,
  });

  bool get hasFamily => family != null;

  FamilyLoaded copyWith({
    UserProfileEntity? profile,
    FamilyEntity? family,
    List<UserProfileEntity>? members,
    bool? isPairingLoading,
    String? notificationMessage,
  }) {
    return FamilyLoaded(
      profile: profile ?? this.profile,
      family: family ?? this.family,
      members: members ?? this.members,
      isPairingLoading: isPairingLoading ?? this.isPairingLoading,
      notificationMessage: notificationMessage,
    );
  }

  @override
  List<Object?> get props => [
        profile,
        family,
        members,
        isPairingLoading,
        notificationMessage,
      ];
}

class FamilyError extends FamilyState {
  final String message;

  const FamilyError(this.message);

  @override
  List<Object?> get props => [message];
}
