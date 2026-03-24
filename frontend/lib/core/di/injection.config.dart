// GENERATED CODE - DO NOT MODIFY BY HAND

// **************************************************************************
// InjectableConfigGenerator
// **************************************************************************

// ignore_for_file: type=lint
// coverage:ignore-file

// ignore_for_file: no_leading_underscores_for_library_prefixes
import 'package:cloud_firestore/cloud_firestore.dart' as _i974;
import 'package:firebase_auth/firebase_auth.dart' as _i59;
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
    gh.lazySingleton<_i1020.AuthRemoteDataSource>(
        () => _i1020.AuthRemoteDataSourceImpl(
              gh<_i59.FirebaseAuth>(),
              gh<_i974.FirebaseFirestore>(),
            ));
    gh.lazySingleton<_i1038.AuthRepository>(
        () => _i549.AuthRepositoryImpl(gh<_i1020.AuthRemoteDataSource>()));
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
        ));
    return this;
  }
}

class _$FirebaseModule extends _i936.FirebaseModule {}
