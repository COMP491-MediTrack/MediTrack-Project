import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';
import 'package:meditrack/features/dashboard/data/datasources/weather_remote_datasource.dart';
import 'package:meditrack/features/dashboard/presentation/cubit/weather_state.dart';

@injectable
class WeatherCubit extends Cubit<WeatherState> {
  final WeatherRemoteDataSource _remoteDataSource;

  WeatherCubit(this._remoteDataSource) : super(WeatherInitial());

  Future<void> fetchWeather({double lat = 41.0082, double lon = 28.9784}) async {
    emit(WeatherLoading());
    try {
      final weather = await _remoteDataSource.getWeather(lat, lon);
      emit(WeatherLoaded(weather));
    } catch (e) {
      emit(WeatherError(e.toString()));
    }
  }
}
