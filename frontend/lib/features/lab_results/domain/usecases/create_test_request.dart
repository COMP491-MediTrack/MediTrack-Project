import 'package:injectable/injectable.dart';
import 'package:meditrack/features/lab_results/domain/entities/test_request_entity.dart';
import 'package:meditrack/features/lab_results/domain/repositories/test_request_repository.dart';

@lazySingleton
class CreateTestRequest {
  final TestRequestRepository _repository;

  CreateTestRequest(this._repository);

  Future<void> call(TestRequestEntity testRequest) async {
    return await _repository.createTestRequest(testRequest);
  }
}
