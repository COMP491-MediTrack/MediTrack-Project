import 'package:equatable/equatable.dart';

class DrugSearchResultEntity extends Equatable {
  final String brandName;
  final String genericName;
  final String atcCode;
  final String barcode;
  final String manufacturer;

  const DrugSearchResultEntity({
    required this.brandName,
    required this.genericName,
    required this.atcCode,
    required this.barcode,
    required this.manufacturer,
  });

  @override
  List<Object?> get props => [brandName, genericName, atcCode, barcode, manufacturer];
}
