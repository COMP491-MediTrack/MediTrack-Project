import 'package:equatable/equatable.dart';
import 'package:meditrack/features/prescription/domain/entities/drug_item_entity.dart';

class PrescriptionEntity extends Equatable {
  final String id;
  final String doctorId;
  final String doctorName;
  final String patientId;
  final String patientName;
  final List<DrugItemEntity> drugs;
  final String status;
  final DateTime createdAt;

  const PrescriptionEntity({
    required this.id,
    required this.doctorId,
    required this.doctorName,
    required this.patientId,
    required this.patientName,
    required this.drugs,
    required this.status,
    required this.createdAt,
  });

  bool get isActive => status == 'active';

  @override
  List<Object?> get props => [id, doctorId, patientId, drugs, status, createdAt];
}
