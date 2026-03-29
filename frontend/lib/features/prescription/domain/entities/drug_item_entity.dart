import 'package:equatable/equatable.dart';

class DrugItemEntity extends Equatable {
  final String brandName;
  final String genericName;
  final String atcCode;
  final String barcode;
  final String dosage;
  final String frequency;
  final int durationDays;

  const DrugItemEntity({
    required this.brandName,
    required this.genericName,
    required this.atcCode,
    required this.barcode,
    required this.dosage,
    required this.frequency,
    required this.durationDays,
  });

  @override
  List<Object?> get props => [brandName, genericName, atcCode, barcode, dosage, frequency, durationDays];
}
