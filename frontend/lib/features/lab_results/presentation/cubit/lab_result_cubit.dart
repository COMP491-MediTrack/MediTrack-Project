import 'dart:typed_data';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';
import 'package:meditrack/features/lab_results/domain/entities/lab_result_entity.dart';
import 'package:meditrack/features/lab_results/domain/usecases/delete_lab_result_usecase.dart';
import 'package:meditrack/features/lab_results/domain/usecases/get_lab_results_usecase.dart';
import 'package:meditrack/features/lab_results/domain/usecases/upload_lab_result_usecase.dart';
import 'package:meditrack/features/lab_results/presentation/cubit/lab_result_state.dart';

@injectable
class LabResultCubit extends Cubit<LabResultState> {
  final GetLabResultsUseCase _getLabResults;
  final UploadLabResultUseCase _uploadLabResult;
  final DeleteLabResultUseCase _deleteLabResult;

  List<LabResultEntity> _currentResults = [];

  LabResultCubit(
    this._getLabResults,
    this._uploadLabResult,
    this._deleteLabResult,
  ) : super(const LabResultInitial());

  Future<void> loadLabResults(String patientId) async {
    emit(const LabResultLoading());
    final result = await _getLabResults(patientId);
    result.fold(
      (failure) => emit(LabResultError(failure.message)),
      (results) {
        _currentResults = results;
        emit(LabResultsLoaded(results));
      },
    );
  }

  Future<void> uploadLabResult({
    required String patientId,
    required Uint8List bytes,
    required String fileName,
    String? notes,
  }) async {
    emit(const LabResultUploading());
    final result = await _uploadLabResult(
      patientId: patientId,
      bytes: bytes,
      fileName: fileName,
      notes: notes,
    );
    result.fold(
      (failure) => emit(LabResultError(failure.message)),
      (uploaded) {
        _currentResults = [uploaded, ..._currentResults];
        emit(LabResultUploaded(_currentResults));
      },
    );
  }

  Future<void> deleteLabResult({
    required String labResultId,
    required String patientId,
    required String fileName,
  }) async {
    emit(const LabResultLoading());
    final result = await _deleteLabResult(
      labResultId: labResultId,
      patientId: patientId,
      fileName: fileName,
    );
    result.fold(
      (failure) => emit(LabResultError(failure.message)),
      (_) {
        _currentResults = _currentResults.where((r) => r.id != labResultId).toList();
        emit(LabResultDeleted(_currentResults));
      },
    );
  }
}
