import 'package:equatable/equatable.dart';
import 'package:meditrack/core/constants/app_constants.dart';

class UserEntity extends Equatable {
  final String uid;
  final String email;
  final String name;
  final String role;

  const UserEntity({
    required this.uid,
    required this.email,
    required this.name,
    required this.role,
  });

  bool get isDoctor => role == AppConstants.roleDoctor;
  bool get isPatient => role == AppConstants.rolePatient;

  @override
  List<Object?> get props => [uid, email, name, role];
}
