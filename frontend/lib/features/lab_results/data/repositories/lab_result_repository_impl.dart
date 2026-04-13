import 'dart:typed_data';

import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';
import 'package:meditrack/core/errors/exceptions.dart';
import 'package:meditrack/core/errors/failures.dart';
import 'package:meditrack/features/lab_results/data/datasources/lab_result_remote_datasource.dart';
import 'package:meditrack/features/lab_results/domain/entities/lab_result_entity.dart';
import 'package:meditrack/features/lab_results/domain/repositories/lab_result_repository.dart';

@LazySingleton(as: LabResultRepository)
class LabResultRepositoryImpl implements LabResultRepository {
  final LabResultRemoteDataSource _dataSource;

  LabResultRepositoryImpl(this._dataSource);

  @override
  Future<Either<Failure, List<LabResultEntity>>> getLabResults(String patientId) async {
    try {
      final results = await _dataSource.getLabResults(patientId);
      return Right(results);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message ?? 'Lab sonuçları yüklenemedi'));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, LabResultEntity>> uploadLabResult({
    required String patientId,
    required Uint8List bytes,
    required String fileName,
    String? notes,
  }) async {
    try {
      final result = await _dataSource.uploadLabResult(
        patientId: patientId,
        bytes: bytes,
        fileName: fileName,
        notes: notes,
      );
      return Right(result);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message ?? 'Yükleme başarısız'));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> deleteLabResult({
    required String labResultId,
    required String patientId,
    required String fileName,
  }) async {
    try {
      await _dataSource.deleteLabResult(
        labResultId: labResultId,
        patientId: patientId,
        fileName: fileName,
      );
      return const Right(null);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message ?? 'Silme başarısız'));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }
}
