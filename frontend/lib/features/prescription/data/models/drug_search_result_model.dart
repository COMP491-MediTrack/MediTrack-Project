import 'package:meditrack/features/prescription/domain/entities/drug_search_result_entity.dart';

class DrugSearchResultModel extends DrugSearchResultEntity {
  const DrugSearchResultModel({
    required super.brandName,
    required super.genericName,
    required super.atcCode,
    required super.barcode,
    required super.manufacturer,
  });

  factory DrugSearchResultModel.fromJson(Map<String, dynamic> json) {
    return DrugSearchResultModel(
      brandName: json['brand_name'] as String,
      genericName: json['generic_name'] as String,
      atcCode: json['atc_code'] as String,
      barcode: json['barcode'] as String,
      manufacturer: json['manufacturer'] as String,
    );
  }
}
