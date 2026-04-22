import 'package:injectable/injectable.dart';
import 'package:meditrack/features/lab_results/domain/entities/test_request_entity.dart';
import 'package:meditrack/features/lab_results/domain/repositories/test_request_repository.dart';

@lazySingleton
class GetPatientTestRequests {
  final TestRequestRepository _repository;

  GetPatientTestRequests(this._repository);

  Future<List<TestRequestEntity>> call(String patientId) async {
    return await _repository.getPatientTestRequests(patientId);
  }
}
