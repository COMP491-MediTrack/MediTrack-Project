import 'package:equatable/equatable.dart';

class LabResultEntity extends Equatable {
  final String id;
  final String testRequestId; // YENİ EKLENDİ: Hangi tahlil isteğinin sonucu?
  final String patientId;
  final String fileName;
  final String fileUrl;
  final String? notes;
  final DateTime uploadedAt;

  const LabResultEntity({
    required this.id,
    required this.testRequestId,
    required this.patientId,
    required this.fileName,
    required this.fileUrl,
    this.notes,
    required this.uploadedAt,
  });

  @override
  List<Object?> get props => [
        id,
        testRequestId,
        patientId,
        fileName,
        fileUrl,
        notes,
        uploadedAt,
      ];
}