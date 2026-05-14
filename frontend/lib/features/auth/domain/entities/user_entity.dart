import 'package:equatable/equatable.dart';
import 'package:meditrack/core/constants/app_constants.dart';

class UserEntity extends Equatable {
  final String uid;
  final String email;
  final String name;
  final String role;
  final String? doctorId;
  final int currentStreak;
  final int longestStreak;
  final DateTime? lastStreakDate;

  const UserEntity({
    required this.uid,
    required this.email,
    required this.name,
    required this.role,
    this.doctorId,
    this.currentStreak = 0,
    this.longestStreak = 0,
    this.lastStreakDate,
  });

  bool get isDoctor => role == AppConstants.roleDoctor;
  bool get isPatient => role == AppConstants.rolePatient;

  @override
  List<Object?> get props => [
        uid,
        email,
        name,
        role,
        doctorId,
        currentStreak,
        longestStreak,
        lastStreakDate,
      ];

  UserEntity copyWith({
    String? uid,
    String? email,
    String? name,
    String? role,
    String? doctorId,
    int? currentStreak,
    int? longestStreak,
    DateTime? lastStreakDate,
  }) {
    return UserEntity(
      uid: uid ?? this.uid,
      email: email ?? this.email,
      name: name ?? this.name,
      role: role ?? this.role,
      doctorId: doctorId ?? this.doctorId,
      currentStreak: currentStreak ?? this.currentStreak,
      longestStreak: longestStreak ?? this.longestStreak,
      lastStreakDate: lastStreakDate ?? this.lastStreakDate,
    );
  }
}
