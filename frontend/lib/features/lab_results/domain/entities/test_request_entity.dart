import 'package:equatable/equatable.dart';

class TestRequestEntity extends Equatable {
  final String id;
  final String patientId;
  final String? patientName;
  final String doctorId;
  final String doctorName;
  final List<String> requestedTests;
  final DateTime createdAt;
  final String status;

  const TestRequestEntity({
    required this.id,
    required this.patientId,
    this.patientName,
    required this.doctorId,
    required this.doctorName,
    required this.requestedTests,
    required this.createdAt,
    this.status = 'Bekliyor',
  });

  @override
  List<Object?> get props => [
        id,
        patientId,
        patientName,
        doctorId,
        doctorName,
        requestedTests,
        createdAt,
        status,
      ];
}
