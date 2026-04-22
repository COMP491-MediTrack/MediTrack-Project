import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';
import 'package:meditrack/features/lab_results/domain/entities/test_request_entity.dart';
import 'package:meditrack/features/lab_results/domain/usecases/create_test_request.dart';
import 'package:meditrack/features/lab_results/domain/usecases/get_patient_test_requests.dart';
import 'package:meditrack/features/lab_results/presentation/cubit/test_request_state.dart';

@injectable
class TestRequestCubit extends Cubit<TestRequestState> {
  final CreateTestRequest _createTestRequest;
  final GetPatientTestRequests _getPatientTestRequests;

  TestRequestCubit(this._createTestRequest, this._getPatientTestRequests)
      : super(TestRequestInitial());

  Future<void> loadTestRequests(String patientId) async {
    try {
      emit(TestRequestLoading());
      final requests = await _getPatientTestRequests(patientId);
      emit(TestRequestsLoaded(requests));
    } catch (e) {
      emit(TestRequestError('İstek formları yüklenirken hata oluştu: $e'));
    }
  }

  Future<void> createTestRequest({
    required String testRequestId,
    required String patientId,
    required String doctorId,
    required String doctorName,
    required List<String> requestedTests,
  }) async {
    try {
      emit(TestRequestLoading());
      final request = TestRequestEntity(
        id: testRequestId,
        patientId: patientId,
        doctorId: doctorId,
        doctorName: doctorName,
        requestedTests: requestedTests,
        createdAt: DateTime.now(),
      );
      await _createTestRequest(request);
      emit(TestRequestCreated());
    } catch (e) {
      emit(TestRequestError('İstek formu oluşturulurken hata: $e'));
    }
  }
}
