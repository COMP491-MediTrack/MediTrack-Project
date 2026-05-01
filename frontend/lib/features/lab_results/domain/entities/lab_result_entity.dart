import 'package:equatable/equatable.dart';

class LabResultEntity extends Equatable {
  final String id;
  final String patientId;
  final String fileName;
  final String fileUrl;
  final String? notes;
  final DateTime uploadedAt;

  const LabResultEntity({
    required this.id,
    required this.patientId,
    required this.fileName,
    required this.fileUrl,
    this.notes,
    required this.uploadedAt,
  });

  @override
  List<Object?> get props => [id, patientId, fileName, fileUrl, notes, uploadedAt];
}
