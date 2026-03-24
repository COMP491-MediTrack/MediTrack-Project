import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';
import 'package:meditrack/core/errors/failures.dart';
import 'package:meditrack/features/auth/domain/repositories/auth_repository.dart';

@lazySingleton
class LogoutUseCase {
  final AuthRepository _repository;

  LogoutUseCase(this._repository);

  Future<Either<Failure, void>> call() {
    return _repository.logout();
  }
}
