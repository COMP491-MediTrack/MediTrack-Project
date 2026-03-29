import 'package:dio/dio.dart';
import 'package:injectable/injectable.dart';
import 'package:meditrack/core/constants/app_constants.dart';
import 'package:meditrack/features/prescription/data/models/ddi_result_model.dart';
import 'package:meditrack/features/prescription/data/models/drug_search_result_model.dart';

abstract class DrugRemoteDataSource {
  Future<List<DrugSearchResultModel>> searchDrugs(String name);
  Future<DdiResultModel> checkDdi(List<String> genericNames);
}

@LazySingleton(as: DrugRemoteDataSource)
class DrugRemoteDataSourceImpl implements DrugRemoteDataSource {
  final Dio _dio;

  DrugRemoteDataSourceImpl(this._dio);

  @override
  Future<List<DrugSearchResultModel>> searchDrugs(String name) async {
    final response = await _dio.get(
      '${AppConstants.apiBaseUrl}/drugs/search',
      queryParameters: {'name': name},
    );
    final results = response.data['results'] as List;
    return results
        .map((r) => DrugSearchResultModel.fromJson(r as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<DdiResultModel> checkDdi(List<String> genericNames) async {
    final response = await _dio.post(
      '${AppConstants.apiBaseUrl}/ddi/check',
      data: {'drugs': genericNames},
    );
    return DdiResultModel.fromJson(response.data as Map<String, dynamic>);
  }
}
