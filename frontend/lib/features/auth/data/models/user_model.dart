import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:meditrack/features/auth/domain/entities/user_entity.dart';

class UserModel extends UserEntity {
  const UserModel({
    required super.uid,
    required super.email,
    required super.name,
    required super.role,
    super.doctorId,
    super.currentStreak,
    super.longestStreak,
    super.lastStreakDate,
  });

  factory UserModel.fromFirestore(Map<String, dynamic> map, String uid) {
    return UserModel(
      uid: uid,
      email: map['email'] as String,
      name: map['name'] as String,
      role: map['role'] as String,
      doctorId: map['doctorId'] as String?,
      currentStreak: (map['currentStreak'] as num?)?.toInt() ?? 0,
      longestStreak: (map['longestStreak'] as num?)?.toInt() ?? 0,
      lastStreakDate: map['lastStreakDate'] != null
          ? (map['lastStreakDate'] as Timestamp).toDate()
          : null,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'email': email,
      'name': name,
      'role': role,
      if (doctorId != null) 'doctorId': doctorId,
      'currentStreak': currentStreak,
      'longestStreak': longestStreak,
      'lastStreakDate':
          lastStreakDate != null ? Timestamp.fromDate(lastStreakDate!) : null,
    };
  }
}
