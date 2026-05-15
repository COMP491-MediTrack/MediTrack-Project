import 'package:injectable/injectable.dart';
import 'package:meditrack/features/lab_results/data/datasources/test_request_remote_datasource.dart';
import 'package:meditrack/features/lab_results/data/models/test_request_model.dart';
import 'package:meditrack/features/lab_results/domain/entities/test_request_entity.dart';
import 'package:meditrack/features/lab_results/domain/repositories/test_request_repository.dart';

@LazySingleton(as: TestRequestRepository)
class TestRequestRepositoryImpl implements TestRequestRepository {
  final TestRequestRemoteDatasource _remoteDatasource;

  TestRequestRepositoryImpl(this._remoteDatasource);

  @override
  Future<void> createTestRequest(TestRequestEntity testRequest) async {
    final model = TestRequestModel(
      id: testRequest.id,
      patientId: testRequest.patientId,
      patientName: testRequest.patientName, // YENİ EKLENDİ: İsim kaybolmasın
      doctorId: testRequest.doctorId,
      doctorName: testRequest.doctorName,
      requestedTests: testRequest.requestedTests,
      createdAt: testRequest.createdAt,
      status: testRequest.status,
    );
    await _remoteDatasource.createTestRequest(model);
  }

  @override
  Future<List<TestRequestEntity>> getPatientTestRequests(String patientId) async {
    return await _remoteDatasource.getPatientTestRequests(patientId);
  }

  // YENİ EKLENDİ: Doktorun kendi istediği tahlilleri getirmesi için
  @override
  Future<List<TestRequestEntity>> getDoctorTestRequests(String doctorId) async {
    return await _remoteDatasource.getDoctorTestRequests(doctorId);
  }

  @override
  Future<List<TestRequestEntity>> getAllTestRequests() async {
    return await _remoteDatasource.getAllTestRequests();
  }

  // YENİ EKLENDİ: Lab görevlisi PDF yükleyince statüyü güncellemek için
  @override
  Future<void> updateTestRequestStatus(String requestId, String status) async {
    await _remoteDatasource.updateTestRequestStatus(requestId, status);
  }
}