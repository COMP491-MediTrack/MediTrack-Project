import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';
import 'package:meditrack/features/prescription/domain/entities/ddi_result_entity.dart';
import 'package:meditrack/features/prescription/domain/entities/drug_item_entity.dart';
import 'package:meditrack/features/prescription/domain/usecases/check_ddi_usecase.dart';
import 'package:meditrack/features/prescription/domain/usecases/create_prescription_usecase.dart';
import 'package:meditrack/features/prescription/domain/usecases/get_doctor_prescriptions_usecase.dart';
import 'package:meditrack/features/prescription/domain/usecases/get_patient_prescriptions_usecase.dart';
import 'package:meditrack/features/prescription/domain/usecases/search_drugs_usecase.dart';
import 'package:meditrack/features/prescription/domain/usecases/explain_ddi_usecase.dart';
import 'package:meditrack/features/prescription/domain/usecases/watch_patient_prescriptions_usecase.dart';
import 'package:meditrack/features/prescription/presentation/cubit/prescription_state.dart';

@injectable
class PrescriptionCubit extends Cubit<PrescriptionState> {
  final SearchDrugsUseCase _searchDrugs;
  final CheckDdiUseCase _checkDdi;
  final ExplainDdiUseCase _explainDdi;
  final CreatePrescriptionUseCase _createPrescription;
  final GetPatientPrescriptionsUseCase _getPatientPrescriptions;
  final GetDoctorPrescriptionsUseCase _getDoctorPrescriptions;
  final WatchPatientPrescriptionsUseCase _watchPatientPrescriptions;

  StreamSubscription? _prescriptionSub;

  PrescriptionCubit(
    this._searchDrugs,
    this._checkDdi,
    this._explainDdi,
    this._createPrescription,
    this._getPatientPrescriptions,
    this._getDoctorPrescriptions,
    this._watchPatientPrescriptions,
  ) : super(PrescriptionInitial());

  Future<void> searchDrugs(String name) async {
    emit(DrugSearchLoading());
    final result = await _searchDrugs(name);
    result.fold(
      (failure) => emit(PrescriptionError(failure.message)),
      (drugs) => emit(DrugSearchLoaded(drugs)),
    );
  }

  Future<void> checkDdi(List<String> genericNames) async {
    emit(DdiChecking());
    final result = await _checkDdi(genericNames);
    result.fold(
      (failure) => emit(PrescriptionError(failure.message)),
      (ddiResult) => emit(DdiLoaded(ddiResult)),
    );
  }

  Future<void> explainDdi(int index, String drug1, String drug2, String description) async {
    emit(DdiExplaining(index));
    final result = await _explainDdi(
      drug1: drug1,
      drug2: drug2,
      description: description,
    );
    result.fold(
      (failure) => emit(PrescriptionError(failure.message)),
      (explanation) => emit(DdiExplanationLoaded(index, explanation)),
    );
  }

  Future<void> createPrescription({
    required String patientId,
    required String patientName,
    required String doctorName,
    required List<DrugItemEntity> drugs,
    List<DdiInteractionEntity> interactions = const [],
  }) async {
    emit(PrescriptionLoading());
    final result = await _createPrescription(
      patientId: patientId,
      patientName: patientName,
      doctorName: doctorName,
      drugs: drugs,
      interactions: interactions,
    );
    result.fold(
      (failure) => emit(PrescriptionError(failure.message)),
      (prescription) => emit(PrescriptionCreated(prescription)),
    );
  }

  Future<void> loadPatientPrescriptions(String patientId) async {
    emit(PrescriptionLoading());
    final result = await _getPatientPrescriptions(patientId);
    result.fold(
      (failure) => emit(PrescriptionError(failure.message)),
      (prescriptions) => emit(PrescriptionListLoaded(prescriptions)),
    );
  }

  void watchPatientPrescriptions(String patientId) {
    _prescriptionSub?.cancel();
    emit(PrescriptionLoading());
    _prescriptionSub = _watchPatientPrescriptions(patientId).listen(
      (prescriptions) => emit(PrescriptionListLoaded(prescriptions)),
      onError: (_) => emit(PrescriptionError('Reçeteler yüklenemedi.')),
    );
  }

  @override
  Future<void> close() {
    _prescriptionSub?.cancel();
    return super.close();
  }

  Future<void> loadDoctorPrescriptions(String doctorId) async {
    emit(PrescriptionLoading());
    final result = await _getDoctorPrescriptions(doctorId);
    result.fold(
      (failure) => emit(PrescriptionError(failure.message)),
      (prescriptions) => emit(PrescriptionListLoaded(prescriptions)),
    );
  }
}
