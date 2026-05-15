import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:meditrack/features/lab_results/domain/entities/lab_result_entity.dart';

class LabResultModel extends LabResultEntity {
  const LabResultModel({
    required super.id,
    required super.testRequestId, // YENİ
    required super.patientId,
    required super.fileName,
    required super.fileUrl,
    super.notes,
    required super.uploadedAt,
  });

  factory LabResultModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return LabResultModel(
      id: doc.id,
      testRequestId: data['test_request_id'] as String, // YENİ
      patientId: data['patient_id'] as String,
      fileName: data['file_name'] as String,
      fileUrl: data['file_url'] as String,
      notes: data['notes'] as String?,
      uploadedAt: (data['uploaded_at'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'test_request_id': testRequestId, // YENİ
      'patient_id': patientId,
      'file_name': fileName,
      'file_url': fileUrl,
      'notes': notes,
      'uploaded_at': Timestamp.fromDate(uploadedAt),
    };
  }
}