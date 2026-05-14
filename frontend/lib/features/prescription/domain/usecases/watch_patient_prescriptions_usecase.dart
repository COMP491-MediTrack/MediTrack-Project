import 'package:injectable/injectable.dart';
import 'package:meditrack/features/prescription/domain/entities/prescription_entity.dart';
import 'package:meditrack/features/prescription/domain/repositories/prescription_repository.dart';

@lazySingleton
class WatchPatientPrescriptionsUseCase {
  final PrescriptionRepository _repository;

  WatchPatientPrescriptionsUseCase(this._repository);

  Stream<List<PrescriptionEntity>> call(String patientId) {
    return _repository.watchPatientPrescriptions(patientId);
  }
}
