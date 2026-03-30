import '../../domain/entities/pharmacy.dart';

class PharmacyModel extends Pharmacy {
  const PharmacyModel({
    required super.name,
    required super.address,
    required super.phone,
    required super.district,
    required super.latitude,
    required super.longitude,
  });

  factory PharmacyModel.fromJson(Map<String, dynamic> json) {
    return PharmacyModel(
      name: json['name'] ?? '',
      address: json['address'] ?? '',
      phone: json['phone'] ?? '',
      district: json['district'] ?? '',
      latitude: (json['lat'] as num?)?.toDouble() ?? 0.0,
      longitude: (json['lng'] as num?)?.toDouble() ?? 0.0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': this.name,
      'address': this.address,
      'phone': this.phone,
      'district': this.district,
      'lat': this.latitude,
      'lng': this.longitude,
    };
  }
}
