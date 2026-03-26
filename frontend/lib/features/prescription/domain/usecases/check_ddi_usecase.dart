import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';
import 'package:meditrack/core/errors/failures.dart';
import 'package:meditrack/features/prescription/domain/entities/ddi_result_entity.dart';
import 'package:meditrack/features/prescription/domain/repositories/prescription_repository.dart';

@lazySingleton
class CheckDdiUseCase {
  final PrescriptionRepository _repository;

  CheckDdiUseCase(this._repository);

  Future<Either<Failure, DdiResultEntity>> call(List<String> genericNames) {
    return _repository.checkDdi(genericNames);
  }
}
