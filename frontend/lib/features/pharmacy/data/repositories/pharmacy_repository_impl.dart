import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';
import '../../domain/entities/pharmacy.dart';
import '../../domain/repositories/pharmacy_repository.dart';
import '../datasources/pharmacy_remote_data_source.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/errors/exceptions.dart';

@LazySingleton(as: PharmacyRepository)
class PharmacyRepositoryImpl implements PharmacyRepository {
  final PharmacyRemoteDataSource remoteDataSource;

  PharmacyRepositoryImpl({required this.remoteDataSource});

  @override
  Future<Either<Failure, List<Pharmacy>>> getOnDutyPharmacies(String city) async {
    try {
      final remotePharmacies = await remoteDataSource.getOnDutyPharmacies(city);
      return Right(remotePharmacies);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message ?? 'Server error occurred'));
    } catch (e) {
      return Left(ServerFailure('Connection error: $e'));
    }
  }
}
