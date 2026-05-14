import 'package:equatable/equatable.dart';
import 'package:meditrack/features/prescription/domain/entities/ddi_result_entity.dart';
import 'package:meditrack/features/prescription/domain/entities/drug_search_result_entity.dart';
import 'package:meditrack/features/prescription/domain/entities/prescription_entity.dart';

abstract class PrescriptionState extends Equatable {
  const PrescriptionState();

  @override
  List<Object?> get props => [];
}

class PrescriptionInitial extends PrescriptionState {}

class PrescriptionLoading extends PrescriptionState {}

// İlaç arama
class DrugSearchLoading extends PrescriptionState {}

class DrugSearchLoaded extends PrescriptionState {
  final List<DrugSearchResultEntity> results;
  const DrugSearchLoaded(this.results);

  @override
  List<Object?> get props => [results];
}

// DDI kontrolü
class DdiChecking extends PrescriptionState {}

class DdiLoaded extends PrescriptionState {
  final DdiResultEntity result;
  const DdiLoaded(this.result);

  @override
  List<Object?> get props => [result];
}

// DDI Açıklama
class DdiExplaining extends PrescriptionState {
  final int interactionIndex;
  const DdiExplaining(this.interactionIndex);

  @override
  List<Object?> get props => [interactionIndex];
}

class DdiExplanationLoaded extends PrescriptionState {
  final int interactionIndex;
  final String explanation;
  const DdiExplanationLoaded(this.interactionIndex, this.explanation);

  @override
  List<Object?> get props => [interactionIndex, explanation];
}

// Reçete listesi
class PrescriptionListLoaded extends PrescriptionState {
  final List<PrescriptionEntity> prescriptions;
  const PrescriptionListLoaded(this.prescriptions);

  @override
  List<Object?> get props => [prescriptions];
}

// Reçete oluşturuldu
class PrescriptionCreated extends PrescriptionState {
  final PrescriptionEntity prescription;
  const PrescriptionCreated(this.prescription);

  @override
  List<Object?> get props => [prescription];
}

class PrescriptionError extends PrescriptionState {
  final String message;
  const PrescriptionError(this.message);

  @override
  List<Object?> get props => [message];
}
