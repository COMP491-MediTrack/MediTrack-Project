import 'package:dartz/dartz.dart';
import 'package:meditrack/core/errors/failures.dart';
import 'package:meditrack/features/auth/domain/entities/user_entity.dart';

abstract class AuthRepository {
  Future<Either<Failure, UserEntity>> login({
    required String email,
    required String password,
  });

  Future<Either<Failure, UserEntity>> register({
    required String email,
    required String password,
    required String name,
    required String role,
    String? doctorId,
  });

  Future<Either<Failure, List<UserEntity>>> getDoctors();

  Future<Either<Failure, UserEntity?>> getCurrentUser();

  Future<Either<Failure, void>> logout();
}
