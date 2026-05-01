import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:injectable/injectable.dart';
import 'package:meditrack/features/lab_results/data/models/test_request_model.dart';


abstract class TestRequestRemoteDatasource {
  Future<void> createTestRequest(TestRequestModel testRequest);
  Future<List<TestRequestModel>> getPatientTestRequests(String patientId);
}

@LazySingleton(as: TestRequestRemoteDatasource)
class TestRequestRemoteDatasourceImpl implements TestRequestRemoteDatasource {
  final FirebaseFirestore _firestore;

  TestRequestRemoteDatasourceImpl(this._firestore);

  @override
  Future<void> createTestRequest(TestRequestModel testRequest) async {
    await _firestore
        .collection('test_requests')
        .doc(testRequest.id)
        .set(testRequest.toFirestore());
  }

  @override
  Future<List<TestRequestModel>> getPatientTestRequests(String patientId) async {
    final snapshot = await _firestore
        .collection('test_requests')
        .where('patient_id', isEqualTo: patientId)
        .orderBy('created_at', descending: true)
        .get();

    return snapshot.docs
        .map((doc) => TestRequestModel.fromFirestore(doc))
        .toList();
  }
}
