import 'package:dartz/dartz.dart';
import '../entities/pharmacy.dart';
import '../../../../core/errors/failures.dart';

abstract class PharmacyRepository {
  Future<Either<Failure, List<Pharmacy>>> getOnDutyPharmacies(String city);
}
