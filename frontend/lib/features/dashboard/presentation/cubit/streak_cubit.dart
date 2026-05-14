import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';
import 'package:meditrack/core/constants/app_constants.dart';
import 'package:meditrack/features/auth/domain/entities/user_entity.dart';
import 'package:meditrack/features/auth/domain/repositories/auth_repository.dart';
import 'package:meditrack/features/dashboard/presentation/cubit/streak_state.dart';
import 'package:meditrack/features/prescription/domain/entities/prescription_entity.dart';

@LazySingleton()
class StreakCubit extends Cubit<StreakState> {
  final AuthRepository _authRepository;
  final FirebaseFirestore _firestore;

  StreakCubit(this._authRepository, this._firestore) : super(StreakInitial());

  Future<void> checkAndUpdateStreak(
    UserEntity user,
    List<PrescriptionEntity> prescriptions,
  ) async {
    emit(StreakLoading());
    try {
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);

      // 1. Get today's adherence logs
      final snapshot = await _firestore
          .collection(AppConstants.adherenceCollection)
          .where('patient_id', isEqualTo: user.uid)
          .get();

      final todayTakenCounts = <String, int>{};
      for (final doc in snapshot.docs) {
        final data = doc.data();
        final takenAt = data['taken_at'];
        DateTime? takenAtDate;
        if (takenAt is Timestamp) {
          takenAtDate = takenAt.toDate();
        }

        if (takenAtDate != null &&
            takenAtDate.year == today.year &&
            takenAtDate.month == today.month &&
            takenAtDate.day == today.day) {
          final drugKey = data['drug_key'] as String;
          final doseCount = (data['dose_count'] as num?)?.toInt() ?? 1;
          todayTakenCounts[drugKey] =
              (todayTakenCounts[drugKey] ?? 0) + doseCount;
        }
      }

      // 2. Determine if all meds for today are taken
      bool isPerfectToday = true;
      bool hasMedsToday = false;

      for (final prescription in prescriptions) {
        if (!prescription.isActive) continue;
        for (final drug in prescription.drugs) {
          final startDate = DateTime(
            prescription.createdAt.year,
            prescription.createdAt.month,
            prescription.createdAt.day,
          );
          final endDate = startDate.add(Duration(days: drug.durationDays - 1));

          if (!today.isBefore(startDate) && !today.isAfter(endDate)) {
            hasMedsToday = true;
            final requiredPerDay = _calculateDosesPerDay(drug.frequency);
            final drugKey = _drugKey(drug);
            final taken = todayTakenCounts[drugKey] ?? 0;

            if (taken < requiredPerDay) {
              isPerfectToday = false;
              break;
            }
          }
        }
        if (!isPerfectToday) break;
      }

      // If no meds are planned for today, it's not a "perfect day" in terms of adherence streak
      if (!hasMedsToday) isPerfectToday = false;

      // 3. Update streak logic
      int currentStreak = user.currentStreak;
      int longestStreak = user.longestStreak;
      DateTime? lastStreakDate = user.lastStreakDate;

      final lastStreakDay = lastStreakDate != null
          ? DateTime(
              lastStreakDate.year,
              lastStreakDate.month,
              lastStreakDate.day,
            )
          : null;

      // Check for streak reset (if they missed yesterday)
      if (lastStreakDay != null) {
        final daysSinceLastStreak = today.difference(lastStreakDay).inDays;
        if (daysSinceLastStreak > 1) {
          currentStreak = 0;
          // Sync reset to Firestore
          await _authRepository.updateStreak(
            user.uid,
            currentStreak: currentStreak,
            longestStreak: longestStreak,
            lastStreakDate: lastStreakDate,
          );
        }
      }

      // Update streak if today is perfect
      if (isPerfectToday) {
        if (lastStreakDay == null || today.isAfter(lastStreakDay)) {
          if (lastStreakDay != null && today.difference(lastStreakDay).inDays == 1) {
            currentStreak += 1;
          } else {
            currentStreak = 1;
          }

          if (currentStreak > longestStreak) longestStreak = currentStreak;
          lastStreakDate = now;

          await _authRepository.updateStreak(
            user.uid,
            currentStreak: currentStreak,
            longestStreak: longestStreak,
            lastStreakDate: lastStreakDate,
          );
        }
      }

      emit(StreakLoaded(
        currentStreak: currentStreak,
        longestStreak: longestStreak,
        isPerfectToday: isPerfectToday,
      ));
    } catch (e) {
      emit(StreakError(e.toString()));
    }
  }

  int _calculateDosesPerDay(String frequency) {
    final normalized = frequency.toLowerCase();
    final turkishDailyMatch = RegExp(r'günde\s*(\d+)').firstMatch(normalized);
    if (turkishDailyMatch != null) {
      return int.tryParse(turkishDailyMatch.group(1) ?? '') ?? 1;
    }
    if (normalized.contains('x')) {
      final parts = normalized.split('x');
      if (parts.length == 2) {
        return (int.tryParse(parts[0].trim()) ?? 1) *
            (int.tryParse(parts[1].trim()) ?? 1);
      }
    }
    return 1;
  }

  String _drugKey(dynamic drug) {
    if (drug.barcode.isNotEmpty) return drug.barcode;
    return '${drug.brandName}_${drug.frequency}_${drug.durationDays}'
        .toLowerCase();
  }
}
