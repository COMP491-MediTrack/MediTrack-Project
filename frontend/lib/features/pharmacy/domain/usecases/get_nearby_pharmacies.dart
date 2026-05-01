import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';
import '../entities/pharmacy.dart';
import '../repositories/pharmacy_repository.dart';
import '../../../../core/errors/failures.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:latlong2/latlong.dart';

@lazySingleton
class GetNearbyPharmacies {
  final PharmacyRepository repository;

  GetNearbyPharmacies(this.repository);

  Future<Either<Failure, List<Pharmacy>>> call() async {
    try {
      // 1. Get Location Permission
      bool serviceEnabled;
      LocationPermission permission;

      serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        return const Left(ServerFailure('Location services are disabled.'));
      }

      permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          return const Left(ServerFailure('Location permissions are denied.'));
        }
      }

      if (permission == LocationPermission.deniedForever) {
        return const Left(ServerFailure('Location permissions are permanently denied.'));
      }

      // 2. Get Current Location
      final position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.medium);

      // 3. Get City from Placemarks
      final placemarks = await placemarkFromCoordinates(position.latitude, position.longitude);
      if (placemarks.isEmpty) {
        return const Left(ServerFailure('Could not determine city from location.'));
      }
      
      String city = placemarks.first.administrativeArea ?? 'Istanbul';
      // Clean " İli", " Province" etc. in Flutter before sending to backend for safety
      city = city.replaceAll(RegExp(r' (İli|Province|Belediyesi|Valiliği)', caseSensitive: false), '').trim();
      
      // In Turkey, administrativeArea is usually the province name e.g. "İstanbul"

      // 4. Fetch Pharmacies for City
      final fallbackCity = 'istanbul'; // just in case
      final result = await repository.getOnDutyPharmacies(city.isNotEmpty ? city : fallbackCity);

      // 5. Filter, Geocode and Calculate distances
      return await result.fold(
        (failure) async => Left(failure),
        (pharmacies) async {
          // A. Clean up empty or bad names
          var validPharmacies = pharmacies.where((p) {
            final n = p.name.toLowerCase().trim();
            return n != 'eczane' && n != 'eczaneleri' && n.length > 3;
          }).toList();

          // B. Filter by user's district to reduce geocoding calls
          // On some iOS simulators, subAdministrativeArea might be empty, or locality might be the Ilce.
          // Let's check both!
          String rawDistrict = placemarks.first.subAdministrativeArea ?? '';
          if (rawDistrict.isEmpty || rawDistrict.toLowerCase() == city.toLowerCase()) {
             rawDistrict = placemarks.first.locality ?? '';
          }
          if (rawDistrict.toLowerCase() == city.toLowerCase()) {
             rawDistrict = placemarks.first.subLocality ?? '';
          }
          
          String normalize(String s) {
            return s.toLowerCase().replaceAll('ç', 'c').replaceAll('ğ', 'g').replaceAll('ı', 'i')
                    .replaceAll('ö', 'o').replaceAll('ş', 's').replaceAll('ü', 'u');
          }

          if (rawDistrict.isNotEmpty && validPharmacies.length > 10) {
            final testDistrict = normalize(rawDistrict);
            final inDistrict = validPharmacies.where((p) => 
                normalize(p.address).contains(testDistrict) || 
                normalize(p.district).contains(testDistrict)
            ).toList();
            
            // Eğer ilçe filtrelemesi sonucu hiç eczane kalmıyorsa, 
            // filtrelemeyi iptal et ve tüm şehri göster (önemli fallback)
            if (inDistrict.isNotEmpty) {
               validPharmacies = inDistrict;
            }
          }

          // C. Geocode missing coordinates
          final distanceHelper = const Distance();
          final List<Pharmacy> processedPharmacies = [];
          
          for (int i = 0; i < validPharmacies.length; i++) {
            Pharmacy p = validPharmacies[i];
            double lat = p.latitude;
            double lng = p.longitude;
            
            if (lat == 0.0 || lng == 0.0) {
              try {
                // Suffix with city to help geocoder. Address often has '»' used for descriptions, keep only the left part.
                final cleanAddress = p.address.split('»').first.trim();
                final query1 = '$cleanAddress, $city, Turkey';
                
                List<Location> locations = [];
                try {
                   locations = await locationFromAddress(query1).timeout(const Duration(seconds: 5));
                } catch (_) {}

                // Fallback 1: Try Pharmacy Name + District
                if (locations.isEmpty) {
                   final query2 = '${p.name}, $rawDistrict, $city, Turkey';
                   try {
                     locations = await locationFromAddress(query2).timeout(const Duration(seconds: 4));
                   } catch (_) {}
                }

                if (locations.isNotEmpty) {
                  lat = locations.first.latitude;
                  lng = locations.first.longitude;
                }
              } catch (_) {
                // Ignore geocode completely failed
              }
            }
            
            processedPharmacies.add(p.copyWith(
              latitude: lat,
              longitude: lng,
              distance: (lat != 0.0 && lng != 0.0) 
                 ? distanceHelper.as(LengthUnit.Meter, LatLng(position.latitude, position.longitude), LatLng(lat, lng)).toDouble() 
                 : null,
            ));
          }

          // D. Sort by distance, nearest first
          processedPharmacies.sort((a, b) {
            if (a.distance == null && b.distance == null) return 0;
            if (a.distance == null) return 1;
            if (b.distance == null) return -1;
            return a.distance!.compareTo(b.distance!);
          });

          return Right(processedPharmacies);
        }
      );
    } catch (e) {
      return Left(ServerFailure('An error occurred while finding nearby pharmacies: $e'));
    }
  }
}
