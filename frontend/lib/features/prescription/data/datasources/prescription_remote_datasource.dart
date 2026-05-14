import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:injectable/injectable.dart';
import 'package:meditrack/core/constants/app_constants.dart';
import 'package:meditrack/features/prescription/data/models/prescription_model.dart';
import 'package:meditrack/features/prescription/domain/entities/ddi_result_entity.dart';
import 'package:meditrack/features/prescription/domain/entities/drug_item_entity.dart';

abstract class PrescriptionRemoteDataSource {
  Future<PrescriptionModel> createPrescription({
    required String patientId,
    required String patientName,
    required String doctorName,
    required List<DrugItemEntity> drugs,
    List<DdiInteractionEntity> interactions,
  });
  Future<List<PrescriptionModel>> getPatientPrescriptions(String patientId);
  Future<List<PrescriptionModel>> getDoctorPrescriptions(String doctorId);
  Stream<List<PrescriptionModel>> watchPatientPrescriptions(String patientId);
}

@LazySingleton(as: PrescriptionRemoteDataSource)
class PrescriptionRemoteDataSourceImpl implements PrescriptionRemoteDataSource {
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  PrescriptionRemoteDataSourceImpl(this._firestore, this._auth);

  @override
  Future<PrescriptionModel> createPrescription({
    required String patientId,
    required String patientName,
    required String doctorName,
    required List<DrugItemEntity> drugs,
    List<DdiInteractionEntity> interactions = const [],
  }) async {
    final doctorId = _auth.currentUser!.uid;
    final docRef = _firestore.collection(AppConstants.prescriptionsCollection).doc();
    final prescription = PrescriptionModel(
      id: docRef.id,
      doctorId: doctorId,
      doctorName: doctorName,
      patientId: patientId,
      patientName: patientName,
      drugs: drugs,
      status: 'active',
      createdAt: DateTime.now(),
      interactions: interactions,
    );
    await docRef.set(prescription.toFirestore());
    return prescription;
  }

  @override
  Future<List<PrescriptionModel>> getPatientPrescriptions(String patientId) async {
    final snapshot = await _firestore
        .collection(AppConstants.prescriptionsCollection)
        .where('patient_id', isEqualTo: patientId)
        .orderBy('created_at', descending: true)
        .get();
    return snapshot.docs
        .map((doc) => PrescriptionModel.fromFirestore(doc.data(), doc.id))
        .toList();
  }

  @override
  Future<List<PrescriptionModel>> getDoctorPrescriptions(String doctorId) async {
    final snapshot = await _firestore
        .collection(AppConstants.prescriptionsCollection)
        .where('doctor_id', isEqualTo: doctorId)
        .orderBy('created_at', descending: true)
        .get();
    return snapshot.docs
        .map((doc) => PrescriptionModel.fromFirestore(doc.data(), doc.id))
        .toList();
  }

  @override
  Stream<List<PrescriptionModel>> watchPatientPrescriptions(String patientId) {
    return _firestore
        .collection(AppConstants.prescriptionsCollection)
        .where('patient_id', isEqualTo: patientId)
        .orderBy('created_at', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => PrescriptionModel.fromFirestore(doc.data(), doc.id))
            .toList());
  }
}
