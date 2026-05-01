import 'package:equatable/equatable.dart';
import 'package:meditrack/features/lab_results/domain/entities/lab_result_entity.dart';

abstract class LabResultState extends Equatable {
  const LabResultState();

  @override
  List<Object?> get props => [];
}

class LabResultInitial extends LabResultState {
  const LabResultInitial();
}

class LabResultLoading extends LabResultState {
  const LabResultLoading();
}

class LabResultsLoaded extends LabResultState {
  final List<LabResultEntity> results;
  const LabResultsLoaded(this.results);

  @override
  List<Object?> get props => [results];
}

class LabResultUploading extends LabResultState {
  const LabResultUploading();
}

class LabResultUploaded extends LabResultState {
  final List<LabResultEntity> results;
  const LabResultUploaded(this.results);

  @override
  List<Object?> get props => [results];
}

class LabResultDeleted extends LabResultState {
  final List<LabResultEntity> results;
  const LabResultDeleted(this.results);

  @override
  List<Object?> get props => [results];
}

class LabResultError extends LabResultState {
  final String message;
  const LabResultError(this.message);

  @override
  List<Object?> get props => [message];
}
