import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:meditrack/features/lab_results/domain/entities/test_request_entity.dart';

class TestRequestModel extends TestRequestEntity {
  const TestRequestModel({
    required super.id,
    required super.patientId,
    super.patientName,
    required super.doctorId,
    required super.doctorName,
    required super.requestedTests,
    required super.createdAt,
    super.status,
  });

  factory TestRequestModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return TestRequestModel(
      id: doc.id,
      patientId: data['patient_id'] as String,
      patientName: data['patient_name'] as String?,
      doctorId: data['doctor_id'] as String,
      doctorName: data['doctor_name'] as String,
      requestedTests: List<String>.from(data['requested_tests'] ?? []),
      createdAt: (data['created_at'] as Timestamp).toDate(),
      status: data['status'] as String? ?? 'Bekliyor',
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'patient_id': patientId,
      if (patientName != null) 'patient_name': patientName,
      'doctor_id': doctorId,
      'doctor_name': doctorName,
      'requested_tests': requestedTests,
      'created_at': Timestamp.fromDate(createdAt),
      'status': status,
    };
  }
}
