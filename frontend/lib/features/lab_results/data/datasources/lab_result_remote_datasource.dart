import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:injectable/injectable.dart';
import 'package:meditrack/core/constants/app_constants.dart';
import 'package:meditrack/core/errors/exceptions.dart';
import 'package:meditrack/features/lab_results/data/models/lab_result_model.dart';

abstract class LabResultRemoteDataSource {
  Future<List<LabResultModel>> getLabResults(String patientId);
  Future<LabResultModel?> getLabResultByTestRequest(String testRequestId); // YENİ
  Future<LabResultModel> uploadLabResult({
    required String testRequestId, // YENİ
    required String patientId,
    required Uint8List bytes,
    required String fileName,
    String? notes,
  });
  Future<void> deleteLabResult({
    required String labResultId,
    required String patientId,
    required String fileName,
  });
}

@LazySingleton(as: LabResultRemoteDataSource)
class LabResultRemoteDataSourceImpl implements LabResultRemoteDataSource {
  final FirebaseFirestore _firestore;
  final FirebaseStorage _storage;

  LabResultRemoteDataSourceImpl(this._firestore, this._storage);

  @override
  Future<List<LabResultModel>> getLabResults(String patientId) async {
    try {
      final snapshot = await _firestore
          .collection(AppConstants.labResultsCollection)
          .where('patient_id', isEqualTo: patientId)
          .get();
      return snapshot.docs.map((doc) => LabResultModel.fromFirestore(doc)).toList();
    } catch (e) {
      throw ServerException(e.toString());
    }
  }

  // YENİ: "Tamamlandı" statüsündeki bir isteğin sonucunu çekmek için
  @override
  Future<LabResultModel?> getLabResultByTestRequest(String testRequestId) async {
    try {
      final snapshot = await _firestore
          .collection(AppConstants.labResultsCollection)
          .where('test_request_id', isEqualTo: testRequestId)
          .limit(1)
          .get();
      
      if (snapshot.docs.isEmpty) return null;
      return LabResultModel.fromFirestore(snapshot.docs.first);
    } catch (e) {
      throw ServerException(e.toString());
    }
  }

  @override
  Future<LabResultModel> uploadLabResult({
    required String testRequestId, // YENİ
    required String patientId,
    required Uint8List bytes,
    required String fileName,
    String? notes,
  }) async {
    try {
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final storagePath = 'lab_results/$patientId/${timestamp}_$fileName';
      final ref = _storage.ref(storagePath);

      await ref.putData(bytes, SettableMetadata(contentType: 'application/pdf'));
      final fileUrl = await ref.getDownloadURL();

      final now = DateTime.now();
      final model = LabResultModel(
        id: '',
        testRequestId: testRequestId, // YENİ
        patientId: patientId,
        fileName: fileName,
        fileUrl: fileUrl,
        notes: notes,
        uploadedAt: now,
      );

      final docRef = await _firestore
          .collection(AppConstants.labResultsCollection)
          .add(model.toFirestore());

      return LabResultModel(
        id: docRef.id,
        testRequestId: testRequestId,
        patientId: patientId,
        fileName: fileName,
        fileUrl: fileUrl,
        notes: notes,
        uploadedAt: now,
      );
    } catch (e) {
      throw ServerException(e.toString());
    }
  }

  @override
  Future<void> deleteLabResult({
    required String labResultId,
    required String patientId,
    required String fileName,
  }) async {
    try {
      await _firestore
          .collection(AppConstants.labResultsCollection)
          .doc(labResultId)
          .delete();

      final listResult = await _storage.ref('lab_results/$patientId').listAll();
      for (final item in listResult.items) {
        if (item.name.endsWith('_$fileName')) {
          await item.delete();
          break;
        }
      }
    } catch (e) {
      throw ServerException(e.toString());
    }
  }
}