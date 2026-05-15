import 'package:injectable/injectable.dart';
import 'package:meditrack/features/lab_results/domain/entities/test_request_entity.dart';
import 'package:meditrack/features/lab_results/domain/repositories/test_request_repository.dart';

@lazySingleton
class GetAllTestRequestsUseCase {
  final TestRequestRepository _repository;

  GetAllTestRequestsUseCase(this._repository);

  Future<List<TestRequestEntity>> call() async {
    return await _repository.getAllTestRequests();
  }
}
