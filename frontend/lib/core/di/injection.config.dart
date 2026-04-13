// GENERATED CODE - DO NOT MODIFY BY HAND

// **************************************************************************
// InjectableConfigGenerator
// **************************************************************************

// ignore_for_file: type=lint
// coverage:ignore-file

// ignore_for_file: no_leading_underscores_for_library_prefixes
import 'package:cloud_firestore/cloud_firestore.dart' as _i974;
import 'package:dio/dio.dart' as _i361;
import 'package:firebase_auth/firebase_auth.dart' as _i59;
import 'package:firebase_storage/firebase_storage.dart' as _i457;
import 'package:get_it/get_it.dart' as _i174;
import 'package:injectable/injectable.dart' as _i526;
import 'package:meditrack/core/di/firebase_module.dart' as _i936;
import 'package:meditrack/features/auth/data/datasources/auth_remote_datasource.dart'
    as _i1020;
import 'package:meditrack/features/auth/data/repositories/auth_repository_impl.dart'
    as _i549;
import 'package:meditrack/features/auth/domain/repositories/auth_repository.dart'
    as _i1038;
import 'package:meditrack/features/auth/domain/usecases/get_current_user_usecase.dart'
    as _i8;
import 'package:meditrack/features/auth/domain/usecases/login_usecase.dart'
    as _i852;
import 'package:meditrack/features/auth/domain/usecases/logout_usecase.dart'
    as _i468;
import 'package:meditrack/features/auth/domain/usecases/register_usecase.dart'
    as _i1050;
import 'package:meditrack/features/auth/presentation/cubit/auth_cubit.dart'
    as _i596;
import 'package:meditrack/features/dashboard/presentation/cubit/dashboard_cubit.dart'
    as _i172;
import 'package:meditrack/features/lab_results/data/datasources/lab_result_remote_datasource.dart'
    as _i301;
import 'package:meditrack/features/lab_results/data/repositories/lab_result_repository_impl.dart'
    as _i302;
import 'package:meditrack/features/lab_results/domain/repositories/lab_result_repository.dart'
    as _i303;
import 'package:meditrack/features/lab_results/domain/usecases/delete_lab_result_usecase.dart'
    as _i304;
import 'package:meditrack/features/lab_results/domain/usecases/get_lab_results_usecase.dart'
    as _i305;
import 'package:meditrack/features/lab_results/domain/usecases/upload_lab_result_usecase.dart'
    as _i306;
import 'package:meditrack/features/lab_results/presentation/cubit/lab_result_cubit.dart'
    as _i307;
import 'package:meditrack/features/pharmacy/data/datasources/pharmacy_remote_data_source.dart'
    as _i104;
import 'package:meditrack/features/pharmacy/data/repositories/pharmacy_repository_impl.dart'
    as _i83;
import 'package:meditrack/features/pharmacy/domain/repositories/pharmacy_repository.dart'
    as _i1061;
import 'package:meditrack/features/pharmacy/domain/usecases/get_nearby_pharmacies.dart'
    as _i556;
import 'package:meditrack/features/pharmacy/presentation/cubit/pharmacy_cubit.dart'
    as _i297;
import 'package:meditrack/features/prescription/data/datasources/drug_remote_datasource.dart'
    as _i60;
import 'package:meditrack/features/prescription/data/datasources/prescription_remote_datasource.dart'
    as _i607;
import 'package:meditrack/features/prescription/data/repositories/prescription_repository_impl.dart'
    as _i482;
import 'package:meditrack/features/prescription/domain/repositories/prescription_repository.dart'
    as _i202;
import 'package:meditrack/features/prescription/domain/usecases/check_ddi_usecase.dart'
    as _i23;
import 'package:meditrack/features/prescription/domain/usecases/create_prescription_usecase.dart'
    as _i118;
import 'package:meditrack/features/prescription/domain/usecases/get_doctor_prescriptions_usecase.dart'
    as _i920;
import 'package:meditrack/features/prescription/domain/usecases/get_patient_prescriptions_usecase.dart'
    as _i872;
import 'package:meditrack/features/prescription/domain/usecases/search_drugs_usecase.dart'
    as _i92;
import 'package:meditrack/features/prescription/presentation/cubit/prescription_cubit.dart'
    as _i840;

extension GetItInjectableX on _i174.GetIt {
// initializes the registration of main-scope dependencies inside of GetIt
  _i174.GetIt init({
    String? environment,
    _i526.EnvironmentFilter? environmentFilter,
  }) {
    final gh = _i526.GetItHelper(
      this,
      environment,
      environmentFilter,
    );
    final firebaseModule = _$FirebaseModule();
    gh.lazySingleton<_i59.FirebaseAuth>(() => firebaseModule.firebaseAuth);
    gh.lazySingleton<_i974.FirebaseFirestore>(() => firebaseModule.firestore);
    gh.lazySingleton<_i457.FirebaseStorage>(() => firebaseModule.storage);
    gh.lazySingleton<_i361.Dio>(() => firebaseModule.dio);
    gh.lazySingleton<_i60.DrugRemoteDataSource>(
        () => _i60.DrugRemoteDataSourceImpl(gh<_i361.Dio>()));
    gh.lazySingleton<_i1020.AuthRemoteDataSource>(
        () => _i1020.AuthRemoteDataSourceImpl(
              gh<_i59.FirebaseAuth>(),
              gh<_i974.FirebaseFirestore>(),
            ));
    gh.factory<_i172.DashboardCubit>(
        () => _i172.DashboardCubit(gh<_i974.FirebaseFirestore>()));
    gh.lazySingleton<_i607.PrescriptionRemoteDataSource>(
        () => _i607.PrescriptionRemoteDataSourceImpl(
              gh<_i974.FirebaseFirestore>(),
              gh<_i59.FirebaseAuth>(),
            ));
    gh.lazySingleton<_i104.PharmacyRemoteDataSource>(
        () => _i104.PharmacyRemoteDataSourceImpl(dio: gh<_i361.Dio>()));
    gh.lazySingleton<_i301.LabResultRemoteDataSource>(
        () => _i301.LabResultRemoteDataSourceImpl(
              gh<_i974.FirebaseFirestore>(),
              gh<_i457.FirebaseStorage>(),
            ));
    gh.lazySingleton<_i1061.PharmacyRepository>(() =>
        _i83.PharmacyRepositoryImpl(
            remoteDataSource: gh<_i104.PharmacyRemoteDataSource>()));
    gh.lazySingleton<_i1038.AuthRepository>(
        () => _i549.AuthRepositoryImpl(gh<_i1020.AuthRemoteDataSource>()));
    gh.lazySingleton<_i303.LabResultRepository>(
        () => _i302.LabResultRepositoryImpl(
              gh<_i301.LabResultRemoteDataSource>(),
            ));
    gh.lazySingleton<_i556.GetNearbyPharmacies>(
        () => _i556.GetNearbyPharmacies(gh<_i1061.PharmacyRepository>()));
    gh.factory<_i297.PharmacyCubit>(() => _i297.PharmacyCubit(
        getNearbyPharmacies: gh<_i556.GetNearbyPharmacies>()));
    gh.lazySingleton<_i202.PrescriptionRepository>(
        () => _i482.PrescriptionRepositoryImpl(
              gh<_i60.DrugRemoteDataSource>(),
              gh<_i607.PrescriptionRemoteDataSource>(),
            ));
    gh.lazySingleton<_i305.GetLabResultsUseCase>(
        () => _i305.GetLabResultsUseCase(gh<_i303.LabResultRepository>()));
    gh.lazySingleton<_i306.UploadLabResultUseCase>(
        () => _i306.UploadLabResultUseCase(gh<_i303.LabResultRepository>()));
    gh.lazySingleton<_i304.DeleteLabResultUseCase>(
        () => _i304.DeleteLabResultUseCase(gh<_i303.LabResultRepository>()));
    gh.lazySingleton<_i92.SearchDrugsUseCase>(
        () => _i92.SearchDrugsUseCase(gh<_i202.PrescriptionRepository>()));
    gh.lazySingleton<_i23.CheckDdiUseCase>(
        () => _i23.CheckDdiUseCase(gh<_i202.PrescriptionRepository>()));
    gh.lazySingleton<_i118.CreatePrescriptionUseCase>(() =>
        _i118.CreatePrescriptionUseCase(gh<_i202.PrescriptionRepository>()));
    gh.lazySingleton<_i920.GetDoctorPrescriptionsUseCase>(() =>
        _i920.GetDoctorPrescriptionsUseCase(
            gh<_i202.PrescriptionRepository>()));
    gh.lazySingleton<_i872.GetPatientPrescriptionsUseCase>(() =>
        _i872.GetPatientPrescriptionsUseCase(
            gh<_i202.PrescriptionRepository>()));
    gh.lazySingleton<_i1050.RegisterUseCase>(
        () => _i1050.RegisterUseCase(gh<_i1038.AuthRepository>()));
    gh.lazySingleton<_i852.LoginUseCase>(
        () => _i852.LoginUseCase(gh<_i1038.AuthRepository>()));
    gh.lazySingleton<_i468.LogoutUseCase>(
        () => _i468.LogoutUseCase(gh<_i1038.AuthRepository>()));
    gh.lazySingleton<_i8.GetCurrentUserUseCase>(
        () => _i8.GetCurrentUserUseCase(gh<_i1038.AuthRepository>()));
    gh.factory<_i596.AuthCubit>(() => _i596.AuthCubit(
          gh<_i852.LoginUseCase>(),
          gh<_i1050.RegisterUseCase>(),
          gh<_i8.GetCurrentUserUseCase>(),
          gh<_i468.LogoutUseCase>(),
          gh<_i1038.AuthRepository>(),
        ));
    gh.factory<_i307.LabResultCubit>(() => _i307.LabResultCubit(
          gh<_i305.GetLabResultsUseCase>(),
          gh<_i306.UploadLabResultUseCase>(),
          gh<_i304.DeleteLabResultUseCase>(),
        ));
    gh.factory<_i840.PrescriptionCubit>(() => _i840.PrescriptionCubit(
          gh<_i92.SearchDrugsUseCase>(),
          gh<_i23.CheckDdiUseCase>(),
          gh<_i118.CreatePrescriptionUseCase>(),
          gh<_i872.GetPatientPrescriptionsUseCase>(),
          gh<_i920.GetDoctorPrescriptionsUseCase>(),
        ));
    return this;
  }
}

class _$FirebaseModule extends _i936.FirebaseModule {}
