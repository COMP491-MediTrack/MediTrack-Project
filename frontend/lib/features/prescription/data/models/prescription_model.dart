import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:meditrack/features/prescription/data/models/drug_item_model.dart';
import 'package:meditrack/features/prescription/domain/entities/prescription_entity.dart';

class PrescriptionModel extends PrescriptionEntity {
  const PrescriptionModel({
    required super.id,
    required super.doctorId,
    required super.doctorName,
    required super.patientId,
    required super.patientName,
    required super.drugs,
    required super.status,
    required super.createdAt,
  });

  factory PrescriptionModel.fromFirestore(Map<String, dynamic> json, String id) {
    return PrescriptionModel(
      id: id,
      doctorId: json['doctor_id'] as String,
      doctorName: json['doctor_name'] as String,
      patientId: json['patient_id'] as String,
      patientName: json['patient_name'] as String,
      drugs: (json['drugs'] as List)
          .map((d) => DrugItemModel.fromFirestore(d as Map<String, dynamic>))
          .toList(),
      status: json['status'] as String,
      createdAt: (json['created_at'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'doctor_id': doctorId,
      'doctor_name': doctorName,
      'patient_id': patientId,
      'patient_name': patientName,
      'drugs': drugs
          .map((d) => DrugItemModel(
                brandName: d.brandName,
                genericName: d.genericName,
                atcCode: d.atcCode,
                barcode: d.barcode,
                dosage: d.dosage,
                frequency: d.frequency,
                durationDays: d.durationDays,
              ).toFirestore())
          .toList(),
      'status': status,
      'created_at': Timestamp.fromDate(createdAt),
    };
  }
}
