import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:meditrack/core/di/injection.dart';
import 'package:meditrack/core/router/route_names.dart';
import 'package:meditrack/core/theme/app_colors.dart';
import 'package:meditrack/features/auth/domain/entities/user_entity.dart';
import 'package:meditrack/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:meditrack/features/auth/presentation/cubit/auth_state.dart';
import 'package:meditrack/features/dashboard/presentation/cubit/dashboard_cubit.dart';
import 'package:meditrack/features/dashboard/presentation/cubit/dashboard_state.dart';
import 'package:meditrack/features/dashboard/presentation/cubit/weather_cubit.dart';
import 'package:meditrack/features/dashboard/presentation/cubit/weather_state.dart';
import 'package:meditrack/features/dashboard/data/datasources/weather_remote_datasource.dart';
import 'package:dio/dio.dart';

class DoctorDashboardPage extends StatelessWidget {
  const DoctorDashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (context) {
          final cubit = getIt<DashboardCubit>();
          final authState = context.read<AuthCubit>().state;
          if (authState is AuthAuthenticated) {
            cubit.loadPatients(authState.user.uid);
          }
          return cubit;
        }),
        BlocProvider(
            create: (_) =>
                WeatherCubit(WeatherRemoteDataSourceImpl(getIt<Dio>()))
                  ..fetchWeather()),
      ],
      child: BlocListener<AuthCubit, AuthState>(
        listener: (context, state) {
          if (state is AuthUnauthenticated) {
            context.go(RouteNames.login);
          } else if (state is AuthAuthenticated) {
            context.read<DashboardCubit>().loadPatients(state.user.uid);
          }
        },
        child: BlocBuilder<AuthCubit, AuthState>(
          builder: (context, authState) {
            final user = authState is AuthAuthenticated ? authState.user : null;
            return Scaffold(
              backgroundColor: AppColors.background,
              appBar: _buildAppBar(context, user),
              body: SafeArea(
                child: SingleChildScrollView(
                  padding: EdgeInsets.all(20.w),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildWelcomeCard(context, user),
                      SizedBox(height: 24.h),
                      _buildPatientListSection(context),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  AppBar _buildAppBar(BuildContext context, UserEntity? user) {
    return AppBar(
      title: const Text('MediTrack'),
      centerTitle: false,
      actions: [
        PopupMenuButton<String>(
          onSelected: (value) {
            if (value == 'profile') {
              context.push(RouteNames.profile);
            } else if (value == 'logout') {
              context.read<AuthCubit>().logout();
            }
          },
          icon: CircleAvatar(
            radius: 16.r,
            backgroundColor: AppColors.primaryContainer,
            child: Icon(Icons.person, size: 20.r, color: AppColors.primary),
          ),
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'profile',
              child: Row(
                children: [
                  Icon(Icons.person_outline, color: AppColors.textPrimary),
                  SizedBox(width: 8),
                  Text('Profilim'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'logout',
              child: Row(
                children: [
                  Icon(Icons.logout, color: AppColors.error),
                  SizedBox(width: 8),
                  Text('Çıkış Yap'),
                ],
              ),
            ),
          ],
        ),
        SizedBox(width: 8.w),
      ],
    );
  }

  ({IconData icon, Color color}) _getWeatherInfo(String? description) {
    final desc = description?.toLowerCase() ?? '';
    if (desc.contains('açık') || desc.contains('güneş')) {
      return (icon: Icons.wb_sunny_rounded, color: AppColors.warning);
    } else if (desc.contains('bulut') || desc.contains('kapalı')) {
      return (icon: Icons.cloud_rounded, color: Colors.blueGrey[300]!);
    } else if (desc.contains('yağmur') || desc.contains('çisenti')) {
      return (icon: Icons.umbrella_rounded, color: Colors.indigo[300]!);
    } else if (desc.contains('kar')) {
      return (icon: Icons.ac_unit_rounded, color: Colors.lightBlue[100]!);
    }
    return (icon: Icons.wb_cloudy_rounded, color: AppColors.primaryDark);
  }

  Widget _buildWelcomeCard(BuildContext context, UserEntity? user) {
    return BlocBuilder<WeatherCubit, WeatherState>(
      builder: (context, weatherState) {
        final weather =
            weatherState is WeatherLoaded ? weatherState.weather : null;
        final weatherInfo = _getWeatherInfo(weather?.description);

        return Container(
          width: double.infinity,
          padding: EdgeInsets.all(20.w),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppColors.primary,
                weatherInfo.color.withAlpha(204),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16.r),
            boxShadow: [
              BoxShadow(
                color: weatherInfo.color.withAlpha(76),
                blurRadius: 15,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Merhaba,',
                      style: TextStyle(
                        fontSize: 14.sp,
                        color: Colors.white70,
                      ),
                    ),
                    SizedBox(height: 4.h),
                    Text(
                      'Dr. ${user?.name ?? ''}',
                      style: TextStyle(
                        fontSize: 22.sp,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    SizedBox(height: 12.h),
                    Row(
                      children: [
                        const Icon(Icons.calendar_today_outlined,
                            color: Colors.white70, size: 14),
                        SizedBox(width: 6.w),
                        Text(
                          _todayFormatted(),
                          style:
                              TextStyle(fontSize: 13.sp, color: Colors.white70),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              if (weather != null)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Icon(
                      weatherInfo.icon,
                      color: Colors.white,
                      size: 32.sp,
                    ),
                    SizedBox(height: 4.h),
                    Text(
                      '${weather.temperature.round()}°C',
                      style: TextStyle(
                        fontSize: 24.sp,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      weather.description,
                      style: TextStyle(
                        fontSize: 12.sp,
                        color: Colors.white.withAlpha(204),
                      ),
                    ),
                  ],
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildPatientListSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Hastalarım',
          style: TextStyle(
            fontSize: 18.sp,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        SizedBox(height: 12.h),
        BlocBuilder<DashboardCubit, DashboardState>(
          builder: (context, state) {
            if (state is DashboardLoading) {
              return const Center(child: CircularProgressIndicator());
            }
            if (state is DashboardError) {
              return Center(
                child: Text(
                  state.message,
                  style: TextStyle(color: AppColors.error, fontSize: 14.sp),
                ),
              );
            }
            if (state is DashboardPatientsLoaded) {
              if (state.patients.isEmpty) {
                return _buildEmptyPatients();
              }
              return _buildPatientList(state.patients);
            }
            return const SizedBox();
          },
        ),
      ],
    );
  }

  Widget _buildEmptyPatients() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(32.w),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        children: [
          Icon(Icons.people_outline, size: 48.sp, color: AppColors.textDisabled),
          SizedBox(height: 12.h),
          Text(
            'Henüz hastanız yok',
            style: TextStyle(
              fontSize: 14.sp,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPatientList(List<UserEntity> patients) {
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: patients.length,
      separatorBuilder: (_, __) => SizedBox(height: 8.h),
      itemBuilder: (context, index) {
        final patient = patients[index];
        return InkWell(
          onTap: () {
            final authState = context.read<AuthCubit>().state;
            if (authState is AuthAuthenticated) {
              _showPatientOptions(context, patient, authState.user);
            }
          },
          borderRadius: BorderRadius.circular(12.r),
          child: Container(
          padding: EdgeInsets.all(16.w),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(12.r),
            border: Border.all(color: AppColors.divider),
          ),
          child: Row(
            children: [
              CircleAvatar(
                radius: 22.r,
                backgroundColor: AppColors.primaryLight,
                child: Text(
                  patient.name.isNotEmpty ? patient.name[0].toUpperCase() : '?',
                  style: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      patient.name,
                      style: TextStyle(
                        fontSize: 15.sp,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    SizedBox(height: 2.h),
                    Text(
                      patient.email,
                      style: TextStyle(
                        fontSize: 13.sp,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: AppColors.textDisabled, size: 20.sp),
            ],
          ),
          ),
        );
      },
    );
  }

  String _todayFormatted() {
    final now = DateTime.now();
    const months = [
      'Ocak', 'Şubat', 'Mart', 'Nisan', 'Mayıs', 'Haziran',
      'Temmuz', 'Ağustos', 'Eylül', 'Ekim', 'Kasım', 'Aralık'
    ];
    return '${now.day} ${months[now.month - 1]} ${now.year}';
  }

  void _showPatientOptions(BuildContext context, UserEntity patient, UserEntity doctor) {
    showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
      ),
      builder: (BuildContext bottomSheetContext) {
        return SafeArea(
          child: Padding(
            padding: EdgeInsets.symmetric(vertical: 20.h),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Hasta: ${patient.name}',
                  style: TextStyle(
                    fontSize: 18.sp,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                SizedBox(height: 16.h),
                ListTile(
                  leading: Icon(Icons.description_outlined, color: AppColors.primary),
                  title: const Text('Reçeteler'),
                  onTap: () {
                    Navigator.pop(bottomSheetContext);
                    context.push(
                      RouteNames.prescriptionList,
                      extra: {
                        'patientId': patient.uid,
                        'patientName': patient.name,
                        'doctorExtra': {
                          'patient': patient,
                          'doctorName': doctor.name,
                        },
                      },
                    );
                  },
                ),
                ListTile(
                  leading: Icon(Icons.science_outlined, color: Colors.teal),
                  title: const Text('Tahliller & İstekler'),
                  onTap: () {
                    Navigator.pop(bottomSheetContext);
                    context.push(
                      RouteNames.labResults,
                      extra: {
                        'patientId': patient.uid,
                        'patientName': patient.name,
                        'isDoctor': true,
                      },
                    );
                  },
                ),
                ListTile(
                  leading: Icon(Icons.assignment_add, color: Colors.orange),
                  title: const Text('Tahlil İsteği Oluştur'),
                  onTap: () {
                    Navigator.pop(bottomSheetContext);
                    context.push(
                      RouteNames.createTestRequest,
                      extra: {
                        'patient': patient,
                        'doctorId': doctor.uid,
                        'doctorName': doctor.name,
                      },
                    );
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
