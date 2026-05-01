import 'package:equatable/equatable.dart';
import 'package:meditrack/features/lab_results/domain/entities/test_request_entity.dart';

abstract class TestRequestState extends Equatable {
  const TestRequestState();

  @override
  List<Object?> get props => [];
}

class TestRequestInitial extends TestRequestState {}

class TestRequestLoading extends TestRequestState {}

class TestRequestsLoaded extends TestRequestState {
  final List<TestRequestEntity> testRequests;

  const TestRequestsLoaded(this.testRequests);

  @override
  List<Object?> get props => [testRequests];
}

class TestRequestCreated extends TestRequestState {}

class TestRequestError extends TestRequestState {
  final String message;

  const TestRequestError(this.message);

  @override
  List<Object?> get props => [message];
}
