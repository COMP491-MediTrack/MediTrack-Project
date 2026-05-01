import 'dart:developer' as developer;

import 'package:dio/dio.dart';
import 'package:injectable/injectable.dart';
import '../models/pharmacy_model.dart';
import '../../../../core/errors/exceptions.dart';

abstract class PharmacyRemoteDataSource {
  Future<List<PharmacyModel>> getOnDutyPharmacies(String city, {String? district});
}

@LazySingleton(as: PharmacyRemoteDataSource)
class PharmacyRemoteDataSourceImpl implements PharmacyRemoteDataSource {
  final Dio dio;

  PharmacyRemoteDataSourceImpl({required this.dio});

  @override
  Future<List<PharmacyModel>> getOnDutyPharmacies(String city, {String? district}) async {
    try {
      assert(() {
        developer.log('Fetching on-duty pharmacies for city: $city, district: $district');
        return true;
      }());

      final queryParams = <String, dynamic>{'city': city};
      if (district != null && district.isNotEmpty) queryParams['district'] = district;

      final response = await dio.get(
        '/pharmacies/on-duty',
        queryParameters: queryParams,
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = response.data;
        assert(() {
          developer.log('On-duty pharmacies response count: ${data.length}');
          return true;
        }());
        return data.map((json) => PharmacyModel.fromJson(json)).toList();
      } else {
        throw ServerException('Status code: ${response.statusCode}');
      }
    } catch (e) {
      throw ServerException(e.toString());
    }
  }
}
