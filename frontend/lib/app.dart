import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:meditrack/core/router/app_router.dart';
import 'package:meditrack/core/theme/app_theme.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:meditrack/core/di/injection.dart';
import 'package:meditrack/features/auth/presentation/cubit/auth_cubit.dart';

class MediTrackApp extends StatelessWidget {
  const MediTrackApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ScreenUtilInit(
      designSize: const Size(390, 844),
      minTextAdapt: true,
      splitScreenMode: true,
      builder: (_, __) => BlocProvider(
        create: (_) => getIt<AuthCubit>()..checkAuthStatus(),
        child: MaterialApp.router(
          title: 'MediTrack',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.lightTheme,
          routerConfig: AppRouter.router,
        ),
      ),
    );
  }
}
