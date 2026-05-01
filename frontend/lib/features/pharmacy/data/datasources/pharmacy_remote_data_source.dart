import 'package:dio/dio.dart';
import 'package:injectable/injectable.dart';
import '../models/pharmacy_model.dart';
import '../../../../core/errors/exceptions.dart';

abstract class PharmacyRemoteDataSource {
  Future<List<PharmacyModel>> getOnDutyPharmacies(String city);
}

@LazySingleton(as: PharmacyRemoteDataSource)
class PharmacyRemoteDataSourceImpl implements PharmacyRemoteDataSource {
  final Dio dio;

  PharmacyRemoteDataSourceImpl({required this.dio});

  @override
  Future<List<PharmacyModel>> getOnDutyPharmacies(String city) async {
    try {
      final response = await dio.get(
        '/pharmacies/on-duty',
        queryParameters: {'city': city},
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = response.data;
        return data.map((json) => PharmacyModel.fromJson(json)).toList();
      } else {
        throw ServerException('Status code: ${response.statusCode}');
      }
    } catch (e) {
      throw ServerException(e.toString());
    }
  }
}
