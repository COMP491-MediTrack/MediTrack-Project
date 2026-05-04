import 'package:dio/dio.dart';
import 'package:injectable/injectable.dart';
import 'package:meditrack/core/constants/app_constants.dart';
import 'package:meditrack/features/dashboard/data/models/weather_model.dart';

abstract class WeatherRemoteDataSource {
  Future<WeatherModel> getWeather(double lat, double lon);
}

@LazySingleton(as: WeatherRemoteDataSource)
class WeatherRemoteDataSourceImpl implements WeatherRemoteDataSource {
  final Dio _dio;

  WeatherRemoteDataSourceImpl(this._dio);

  @override
  Future<WeatherModel> getWeather(double lat, double lon) async {
    try {
      final response = await _dio.get(
        '${AppConstants.apiBaseUrl}/weather/',
        queryParameters: {
          'lat': lat,
          'lon': lon,
        },
      );
      return WeatherModel.fromJson(response.data);
    } catch (e) {
      rethrow;
    }
  }
}
