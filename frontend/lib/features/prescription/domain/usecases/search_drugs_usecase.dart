import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';
import 'package:meditrack/core/errors/failures.dart';
import 'package:meditrack/features/prescription/domain/entities/drug_search_result_entity.dart';
import 'package:meditrack/features/prescription/domain/repositories/prescription_repository.dart';

@lazySingleton
class SearchDrugsUseCase {
  final PrescriptionRepository _repository;

  SearchDrugsUseCase(this._repository);

  Future<Either<Failure, List<DrugSearchResultEntity>>> call(String name) {
    return _repository.searchDrugs(name);
  }
}
