import 'package:equatable/equatable.dart';
import 'package:meditrack/core/constants/app_constants.dart';

class UserEntity extends Equatable {
  final String uid;
  final String email;
  final String name;
  final String role;
  final String? doctorId;

  const UserEntity({
    required this.uid,
    required this.email,
    required this.name,
    required this.role,
    this.doctorId,
  });

  bool get isDoctor => role == AppConstants.roleDoctor;
  bool get isPatient => role == AppConstants.rolePatient;
  bool get isLab => role == AppConstants.roleLab;

  @override
  List<Object?> get props => [uid, email, name, role, doctorId];

  UserEntity copyWith({
    String? uid,
    String? email,
    String? name,
    String? role,
    String? doctorId,
  }) {
    return UserEntity(
      uid: uid ?? this.uid,
      email: email ?? this.email,
      name: name ?? this.name,
      role: role ?? this.role,
      doctorId: doctorId ?? this.doctorId,
    );
  }
}
