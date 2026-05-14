import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';
import 'package:meditrack/core/errors/failures.dart';
import 'package:meditrack/features/prescription/domain/repositories/prescription_repository.dart';

@lazySingleton
class ExplainDdiUseCase {
  final PrescriptionRepository _repository;

  ExplainDdiUseCase(this._repository);

  Future<Either<Failure, String>> call({
    required String drug1,
    required String drug2,
    required String description,
  }) {
    return _repository.explainDdi(drug1, drug2, description);
  }
}
