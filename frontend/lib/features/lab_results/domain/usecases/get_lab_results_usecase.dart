import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';
import 'package:meditrack/core/errors/failures.dart';
import 'package:meditrack/features/lab_results/domain/entities/lab_result_entity.dart';
import 'package:meditrack/features/lab_results/domain/repositories/lab_result_repository.dart';

@lazySingleton
class GetLabResultsUseCase {
  final LabResultRepository _repository;

  GetLabResultsUseCase(this._repository);

  Future<Either<Failure, List<LabResultEntity>>> call(String patientId) {
    return _repository.getLabResults(patientId);
  }
}
