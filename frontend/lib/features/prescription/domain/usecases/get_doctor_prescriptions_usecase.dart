import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';
import 'package:meditrack/core/errors/failures.dart';
import 'package:meditrack/features/prescription/domain/entities/prescription_entity.dart';
import 'package:meditrack/features/prescription/domain/repositories/prescription_repository.dart';

@lazySingleton
class GetDoctorPrescriptionsUseCase {
  final PrescriptionRepository _repository;

  GetDoctorPrescriptionsUseCase(this._repository);

  Future<Either<Failure, List<PrescriptionEntity>>> call(String doctorId) {
    return _repository.getDoctorPrescriptions(doctorId);
  }
}
