import 'package:dartz/dartz.dart';
import 'package:meditrack/core/errors/failures.dart';
import 'package:meditrack/features/prescription/domain/entities/ddi_result_entity.dart';
import 'package:meditrack/features/prescription/domain/entities/drug_item_entity.dart';
import 'package:meditrack/features/prescription/domain/entities/drug_search_result_entity.dart';
import 'package:meditrack/features/prescription/domain/entities/prescription_entity.dart';

abstract class PrescriptionRepository {
  Future<Either<Failure, List<DrugSearchResultEntity>>> searchDrugs(String name);

  Future<Either<Failure, DdiResultEntity>> checkDdi(List<String> genericNames);
  Future<Either<Failure, String>> explainDdi(String drug1, String drug2, String description);

  Future<Either<Failure, PrescriptionEntity>> createPrescription({
    required String patientId,
    required String patientName,
    required String doctorName,
    required List<DrugItemEntity> drugs,
    List<DdiInteractionEntity> interactions,
  });

  Future<Either<Failure, List<PrescriptionEntity>>> getPatientPrescriptions(String patientId);

  Future<Either<Failure, List<PrescriptionEntity>>> getDoctorPrescriptions(String doctorId);

  Stream<List<PrescriptionEntity>> watchPatientPrescriptions(String patientId);
}
