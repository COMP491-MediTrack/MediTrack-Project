import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';
import 'package:meditrack/core/errors/failures.dart';
import 'package:meditrack/features/lab_results/domain/repositories/lab_result_repository.dart';

@lazySingleton
class DeleteLabResultUseCase {
  final LabResultRepository _repository;

  DeleteLabResultUseCase(this._repository);

  Future<Either<Failure, void>> call({
    required String labResultId,
    required String patientId,
    required String fileName,
  }) {
    return _repository.deleteLabResult(
      labResultId: labResultId,
      patientId: patientId,
      fileName: fileName,
    );
  }
}
