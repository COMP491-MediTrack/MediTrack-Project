import 'dart:typed_data';

import 'package:dartz/dartz.dart';
import 'package:meditrack/core/errors/failures.dart';
import 'package:meditrack/features/lab_results/domain/entities/lab_result_entity.dart';

abstract class LabResultRepository {
  Future<Either<Failure, List<LabResultEntity>>> getLabResults(String patientId);
  Future<Either<Failure, LabResultEntity>> uploadLabResult({
    required String patientId,
    required Uint8List bytes,
    required String fileName,
    String? notes,
  });
  Future<Either<Failure, void>> deleteLabResult({
    required String labResultId,
    required String patientId,
    required String fileName,
  });
}
