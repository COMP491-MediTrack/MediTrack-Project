import 'package:equatable/equatable.dart';
import 'package:meditrack/features/auth/domain/entities/user_entity.dart';

abstract class DashboardState extends Equatable {
  const DashboardState();

  @override
  List<Object?> get props => [];
}

class DashboardInitial extends DashboardState {}

class DashboardLoading extends DashboardState {}

class DashboardPatientsLoaded extends DashboardState {
  final List<UserEntity> patients;

  const DashboardPatientsLoaded(this.patients);

  @override
  List<Object?> get props => [patients];
}

class DashboardDoctorLoaded extends DashboardState {
  final UserEntity doctor;

  const DashboardDoctorLoaded(this.doctor);

  @override
  List<Object?> get props => [doctor];
}

class DashboardError extends DashboardState {
  final String message;

  const DashboardError(this.message);

  @override
  List<Object?> get props => [message];
}
