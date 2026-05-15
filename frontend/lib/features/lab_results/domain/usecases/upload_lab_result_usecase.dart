import 'dart:typed_data';

import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';
import 'package:meditrack/core/errors/failures.dart';
import 'package:meditrack/features/lab_results/domain/entities/lab_result_entity.dart';
import 'package:meditrack/features/lab_results/domain/repositories/lab_result_repository.dart';
import 'package:meditrack/features/lab_results/domain/repositories/test_request_repository.dart';

@lazySingleton
class UploadLabResultUseCase {
  final LabResultRepository _labResultRepository;
  final TestRequestRepository _testRequestRepository; // YENİ EKLENDİ

  UploadLabResultUseCase(
    this._labResultRepository,
    this._testRequestRepository,
  );

  Future<Either<Failure, LabResultEntity>> call({
    required String testRequestId, // YENİ EKLENDİ
    required String patientId,
    required Uint8List bytes,
    required String fileName,
    String? notes,
  }) async {
    // 1. Önce PDF dosyasını yükle ve veritabanına LabResult olarak kaydet
    final result = await _labResultRepository.uploadLabResult(
      testRequestId: testRequestId,
      patientId: patientId,
      bytes: bytes,
      fileName: fileName,
      notes: notes,
    );

    // 2. Yükleme başarılı olduysa Test İsteğinin durumunu güncelle
    return result.fold(
      (failure) => Left(failure), // Eğer yüklemede hata çıkarsa direkt hatayı dön
      (labResult) async {
        try {
          // Başarılı! Statüyü 'Tamamlandı' olarak güncelle
          await _testRequestRepository.updateTestRequestStatus(
            testRequestId,
            'Tamamlandı',
          );
          return Right(labResult);
        } catch (e) {
          // Statü güncellenemezse hata dön (Opsiyonel ama güvenli)
          return Left(ServerFailure('Sonuç yüklendi ancak statü güncellenemedi: $e'));
        }
      },
    );
  }
}