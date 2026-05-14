import 'package:equatable/equatable.dart';

abstract class StreakState extends Equatable {
  const StreakState();

  @override
  List<Object?> get props => [];
}

class StreakInitial extends StreakState {}

class StreakLoading extends StreakState {}

class StreakLoaded extends StreakState {
  final int currentStreak;
  final int longestStreak;
  final bool isPerfectToday;

  const StreakLoaded({
    required this.currentStreak,
    required this.longestStreak,
    required this.isPerfectToday,
  });

  @override
  List<Object?> get props => [currentStreak, longestStreak, isPerfectToday];
}

class StreakError extends StreakState {
  final String message;

  const StreakError(this.message);

  @override
  List<Object?> get props => [message];
}
