import 'package:meditrack/features/lab_results/domain/entities/test_request_entity.dart';

abstract class TestRequestRepository {
  Future<void> createTestRequest(TestRequestEntity testRequest);
  Future<List<TestRequestEntity>> getPatientTestRequests(String patientId);
  
  // YENİ EKLENDİ: Doktorun kendi istediği tahlilleri getirmesi için
  Future<List<TestRequestEntity>> getDoctorTestRequests(String doctorId);
  
  Future<List<TestRequestEntity>> getAllTestRequests();
  
  // YENİ EKLENDİ: Lab görevlisi PDF yükleyince statüyü güncellemek için
  Future<void> updateTestRequestStatus(String requestId, String status);
}