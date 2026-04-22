import 'dart:typed_data';

import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';
import 'package:meditrack/core/errors/failures.dart';
import 'package:meditrack/features/lab_results/domain/entities/lab_result_entity.dart';
import 'package:meditrack/features/lab_results/domain/repositories/lab_result_repository.dart';

@lazySingleton
class UploadLabResultUseCase {
  final LabResultRepository _repository;

  UploadLabResultUseCase(this._repository);

  Future<Either<Failure, LabResultEntity>> call({
    required String patientId,
    required Uint8List bytes,
    required String fileName,
    String? notes,
  }) {
    return _repository.uploadLabResult(
      patientId: patientId,
      bytes: bytes,
      fileName: fileName,
      notes: notes,
    );
  }
}
