import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import 'package:injectable/injectable.dart';
import 'package:meditrack/core/errors/failures.dart';
import 'package:meditrack/features/prescription/data/datasources/drug_remote_datasource.dart';
import 'package:meditrack/features/prescription/data/datasources/prescription_remote_datasource.dart';
import 'package:meditrack/features/prescription/domain/entities/ddi_result_entity.dart';
import 'package:meditrack/features/prescription/domain/entities/drug_item_entity.dart';
import 'package:meditrack/features/prescription/domain/entities/drug_search_result_entity.dart';
import 'package:meditrack/features/prescription/domain/entities/prescription_entity.dart';
import 'package:meditrack/features/prescription/domain/repositories/prescription_repository.dart';

@LazySingleton(as: PrescriptionRepository)
class PrescriptionRepositoryImpl implements PrescriptionRepository {
  final DrugRemoteDataSource _drugDataSource;
  final PrescriptionRemoteDataSource _prescriptionDataSource;

  PrescriptionRepositoryImpl(this._drugDataSource, this._prescriptionDataSource);

  @override
  Future<Either<Failure, List<DrugSearchResultEntity>>> searchDrugs(String name) async {
    try {
      final results = await _drugDataSource.searchDrugs(name);
      return Right(results);
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) return const Right([]);
      return Left(ServerFailure(e.message ?? 'İlaç arama başarısız.'));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, DdiResultEntity>> checkDdi(List<String> genericNames) async {
    try {
      final result = await _drugDataSource.checkDdi(genericNames);
      return Right(result);
    } on DioException catch (e) {
      return Left(ServerFailure(e.message ?? 'DDI kontrolü başarısız.'));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, String>> explainDdi(String drug1, String drug2, String description) async {
    try {
      final explanation = await _drugDataSource.explainDdi(drug1, drug2, description);
      return Right(explanation);
    } on DioException catch (e) {
      return Left(ServerFailure(e.message ?? 'AI açıklaması alınamadı.'));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, PrescriptionEntity>> createPrescription({
    required String patientId,
    required String patientName,
    required String doctorName,
    required List<DrugItemEntity> drugs,
  }) async {
    try {
      final prescription = await _prescriptionDataSource.createPrescription(
        patientId: patientId,
        patientName: patientName,
        doctorName: doctorName,
        drugs: drugs,
      );
      return Right(prescription);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<PrescriptionEntity>>> getPatientPrescriptions(String patientId) async {
    try {
      final prescriptions = await _prescriptionDataSource.getPatientPrescriptions(patientId);
      return Right(prescriptions);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<PrescriptionEntity>>> getDoctorPrescriptions(String doctorId) async {
    try {
      final prescriptions = await _prescriptionDataSource.getDoctorPrescriptions(doctorId);
      return Right(prescriptions);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }
}
