import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';
import 'package:meditrack/core/errors/failures.dart';
import 'package:meditrack/features/auth/domain/entities/user_entity.dart';
import 'package:meditrack/features/auth/domain/repositories/auth_repository.dart';

@lazySingleton
class LoginUseCase {
  final AuthRepository _repository;

  LoginUseCase(this._repository);

  Future<Either<Failure, UserEntity>> call({
    required String email,
    required String password,
  }) {
    return _repository.login(email: email, password: password);
  }
}
