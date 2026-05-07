import 'package:meditrack/features/lab_results/domain/entities/test_request_entity.dart';

abstract class TestRequestRepository {
  Future<void> createTestRequest(TestRequestEntity testRequest);
  Future<List<TestRequestEntity>> getPatientTestRequests(String patientId);
  Future<List<TestRequestEntity>> getAllTestRequests();
}
