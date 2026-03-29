import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';
import 'package:meditrack/core/errors/failures.dart';
import 'package:meditrack/features/prescription/domain/entities/drug_item_entity.dart';
import 'package:meditrack/features/prescription/domain/entities/prescription_entity.dart';
import 'package:meditrack/features/prescription/domain/repositories/prescription_repository.dart';

@lazySingleton
class CreatePrescriptionUseCase {
  final PrescriptionRepository _repository;

  CreatePrescriptionUseCase(this._repository);

  Future<Either<Failure, PrescriptionEntity>> call({
    required String patientId,
    required String patientName,
    required String doctorName,
    required List<DrugItemEntity> drugs,
  }) {
    return _repository.createPrescription(
      patientId: patientId,
      patientName: patientName,
      doctorName: doctorName,
      drugs: drugs,
    );
  }
}
