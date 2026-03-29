import 'package:meditrack/features/prescription/domain/entities/drug_item_entity.dart';

class DrugItemModel extends DrugItemEntity {
  const DrugItemModel({
    required super.brandName,
    required super.genericName,
    required super.atcCode,
    required super.barcode,
    required super.dosage,
    required super.frequency,
    required super.durationDays,
  });

  factory DrugItemModel.fromFirestore(Map<String, dynamic> json) {
    return DrugItemModel(
      brandName: json['brand_name'] as String,
      genericName: json['generic_name'] as String,
      atcCode: json['atc_code'] as String,
      barcode: json['barcode'] as String,
      dosage: json['dosage'] as String,
      frequency: json['frequency'] as String,
      durationDays: json['duration_days'] as int,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'brand_name': brandName,
      'generic_name': genericName,
      'atc_code': atcCode,
      'barcode': barcode,
      'dosage': dosage,
      'frequency': frequency,
      'duration_days': durationDays,
    };
  }
}
