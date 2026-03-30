import 'package:equatable/equatable.dart';

class Pharmacy extends Equatable {
  final String name;
  final String address;
  final String phone;
  final String district;
  final double latitude;
  final double longitude;
  final double? distance; // Distance in meters from user

  const Pharmacy({
    required this.name,
    required this.address,
    required this.phone,
    required this.district,
    required this.latitude,
    required this.longitude,
    this.distance,
  });

  Pharmacy copyWith({
    String? name,
    String? address,
    String? phone,
    String? district,
    double? latitude,
    double? longitude,
    double? distance,
  }) {
    return Pharmacy(
      name: name ?? this.name,
      address: address ?? this.address,
      phone: phone ?? this.phone,
      district: district ?? this.district,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      distance: distance ?? this.distance,
    );
  }

  @override
  List<Object?> get props => [name, address, phone, district, latitude, longitude, distance];
}
