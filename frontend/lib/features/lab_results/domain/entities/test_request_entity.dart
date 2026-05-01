import 'package:equatable/equatable.dart';

class TestRequestEntity extends Equatable {
  final String id;
  final String patientId;
  final String doctorId;
  final String doctorName;
  final List<String> requestedTests;
  final DateTime createdAt;
  final String status;

  const TestRequestEntity({
    required this.id,
    required this.patientId,
    required this.doctorId,
    required this.doctorName,
    required this.requestedTests,
    required this.createdAt,
    this.status = 'Bekliyor', // pending
  });

  @override
  List<Object?> get props => [
        id,
        patientId,
        doctorId,
        doctorName,
        requestedTests,
        createdAt,
        status,
      ];
}
