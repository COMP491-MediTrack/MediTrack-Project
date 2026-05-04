import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:meditrack/core/di/injection.dart';
import 'package:meditrack/core/router/route_names.dart';
import 'package:meditrack/core/services/notification_service.dart';
import 'package:meditrack/core/theme/app_colors.dart';
import 'package:meditrack/features/auth/domain/entities/user_entity.dart';
import 'package:meditrack/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:meditrack/features/auth/presentation/cubit/auth_state.dart';
import 'package:meditrack/features/dashboard/presentation/cubit/dashboard_cubit.dart';
import 'package:meditrack/features/dashboard/presentation/cubit/dashboard_state.dart';
import 'package:meditrack/features/prescription/domain/entities/prescription_entity.dart';
import 'package:meditrack/features/prescription/presentation/cubit/prescription_cubit.dart';
import 'package:meditrack/features/prescription/presentation/cubit/prescription_state.dart';
import 'package:meditrack/features/dashboard/presentation/cubit/weather_cubit.dart';
import 'package:meditrack/features/dashboard/presentation/cubit/weather_state.dart';
import 'package:meditrack/features/dashboard/data/models/weather_model.dart';
import 'package:meditrack/features/dashboard/data/datasources/weather_remote_datasource.dart';
import 'package:dio/dio.dart';

class PatientDashboardPage extends StatelessWidget {
  const PatientDashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => getIt<DashboardCubit>()),
        BlocProvider(create: (_) => getIt<PrescriptionCubit>()),
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
            if (state.user.doctorId != null) {
              context.read<DashboardCubit>().loadDoctor(state.user.doctorId!);
            }
            context.read<PrescriptionCubit>().loadPatientPrescriptions(
              state.user.uid,
            );
          }
        },
        child: BlocBuilder<AuthCubit, AuthState>(
          builder: (context, authState) {
            final user = authState is AuthAuthenticated ? authState.user : null;
            return Scaffold(
              backgroundColor: AppColors.background,
              appBar: _buildAppBar(context),
              body: SafeArea(
                child: SingleChildScrollView(
                  padding: EdgeInsets.all(20.w),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildWelcomeCard(context, user),
                      SizedBox(height: 16.h),
                      _buildDoctorCard(context),
                      SizedBox(height: 16.h),
                      _buildPharmacyActionCard(context),
                      SizedBox(height: 16.h),
                      _buildScheduleActionCard(context, user),
                      SizedBox(height: 12.h),
                      _buildLabResultsActionCard(context),
                      SizedBox(height: 12.h),
                      _buildReminderCard(context),
                      SizedBox(height: 24.h),
                      _buildPrescriptionsSection(context),
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

  Widget _buildPharmacyActionCard(BuildContext context) {
    return GestureDetector(
      onTap: () => context.push(RouteNames.pharmacy),
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.all(16.w),
        decoration: BoxDecoration(
          color: Colors.red[50],
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(color: Colors.red[200]!),
        ),
        child: Row(
          children: [
            Icon(Icons.local_pharmacy, color: Colors.red[700], size: 28.sp),
            SizedBox(width: 12.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Yakın Nöbetçi Eczaneler',
                    style: TextStyle(
                      fontSize: 15.sp,
                      fontWeight: FontWeight.bold,
                      color: Colors.red[800],
                    ),
                  ),
                  SizedBox(height: 2.h),
                  Text(
                    'Çevrenizdeki açık eczaneleri haritada görün.',
                    style: TextStyle(fontSize: 12.sp, color: Colors.red[600]),
                  ),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios, color: Colors.red[300], size: 16.sp),
          ],
        ),
      ),
    );
  }

  Widget _buildScheduleActionCard(BuildContext context, UserEntity? user) {
    if (user == null) return const SizedBox.shrink();
    return GestureDetector(
      onTap: () => context.push(RouteNames.medicineSchedule, extra: user.uid),
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.all(16.w),
        decoration: BoxDecoration(
          color: AppColors.primaryLight,
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(color: AppColors.primary.withAlpha(51)),
        ),
        child: Row(
          children: [
            Icon(
              Icons.calendar_month_outlined,
              color: AppColors.primary,
              size: 28.sp,
            ),
            SizedBox(width: 12.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'İlaç Takvimim ve Stoklar',
                    style: TextStyle(
                      fontSize: 15.sp,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  SizedBox(height: 2.h),
                  Text(
                    'Haftalık programınızı ve ilaç stok durumunuzu görün.',
                    style: TextStyle(
                      fontSize: 12.sp,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              color: AppColors.primary,
              size: 16.sp,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReminderCard(BuildContext context) {
    return BlocBuilder<PrescriptionCubit, PrescriptionState>(
      builder: (context, state) {
        final activeDrugs = state is PrescriptionListLoaded
            ? state.prescriptions
                  .where((p) => p.isActive)
                  .expand((p) => p.drugs)
                  .toList()
            : [];

        return GestureDetector(
          onTap: () async {
            final granted = await NotificationService.instance
                .requestPermissions();
            if (!context.mounted) return;
            if (!granted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Bildirim izni verilmedi'),
                  backgroundColor: Colors.orange,
                ),
              );
              return;
            }
            if (activeDrugs.isEmpty) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Aktif reçetenizde ilaç bulunamadı'),
                ),
              );
              return;
            }
            await NotificationService.instance.scheduleForDrugs(
              activeDrugs
                  .map(
                    (d) => (
                      name: d.brandName as String,
                      frequency: d.frequency as String,
                    ),
                  )
                  .toList(),
            );
            if (!context.mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  '${activeDrugs.length} ilaç için hatırlatıcı kuruldu',
                ),
                backgroundColor: AppColors.success,
              ),
            );
          },
          child: Container(
            width: double.infinity,
            padding: EdgeInsets.all(16.w),
            decoration: BoxDecoration(
              color: Colors.purple[50],
              borderRadius: BorderRadius.circular(12.r),
              border: Border.all(color: Colors.purple[200]!),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.notifications_active_outlined,
                  color: Colors.purple[700],
                  size: 28.sp,
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Hatırlatıcıları Kur',
                        style: TextStyle(
                          fontSize: 15.sp,
                          fontWeight: FontWeight.bold,
                          color: Colors.purple[800],
                        ),
                      ),
                      SizedBox(height: 2.h),
                      Text(
                        'İlaçlarınız için günlük bildirim alın.',
                        style: TextStyle(
                          fontSize: 12.sp,
                          color: Colors.purple[600],
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios,
                  color: Colors.purple[300],
                  size: 16.sp,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildLabResultsActionCard(BuildContext context) {
    return GestureDetector(
      onTap: () => context.push(RouteNames.labResults),
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.all(16.w),
        decoration: BoxDecoration(
          color: Colors.teal[50],
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(color: Colors.teal[200]!),
        ),
        child: Row(
          children: [
            Icon(Icons.science_outlined, color: Colors.teal[700], size: 28.sp),
            SizedBox(width: 12.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Lab Sonuçları & İstekler',
                    style: TextStyle(
                      fontSize: 15.sp,
                      fontWeight: FontWeight.bold,
                      color: Colors.teal[800],
                    ),
                  ),
                  SizedBox(height: 2.h),
                  Text(
                    'Doktorunuzun eklediği lab sonuçlarını ve tahlil isteklerini görüntüleyin.',
                    style: TextStyle(fontSize: 12.sp, color: Colors.teal[600]),
                  ),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios, color: Colors.teal[300], size: 16.sp),
          ],
        ),
      ),
    );
  }

  AppBar _buildAppBar(BuildContext context) {
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
                      style: TextStyle(fontSize: 14.sp, color: Colors.white70),
                    ),
                    SizedBox(height: 4.h),
                    Text(
                      user?.name ?? '',
                      style: TextStyle(
                        fontSize: 22.sp,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    SizedBox(height: 12.h),
                    Row(
                      children: [
                        const Icon(
                          Icons.calendar_today_outlined,
                          color: Colors.white70,
                          size: 14,
                        ),
                        SizedBox(width: 6.w),
                        Text(
                          _todayFormatted(),
                          style: TextStyle(
                              fontSize: 13.sp, color: Colors.white70),
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

  Widget _buildDoctorCard(BuildContext context) {
    return BlocBuilder<DashboardCubit, DashboardState>(
      builder: (context, state) {
        String doctorName = 'Yükleniyor...';
        if (state is DashboardDoctorLoaded) {
          doctorName = 'Dr. ${state.doctor.name}';
        } else if (state is DashboardError) {
          doctorName = 'Doktor bilgisi alınamadı';
        }

        return Container(
          padding: EdgeInsets.all(16.w),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(12.r),
            border: Border.all(color: AppColors.divider),
          ),
          child: Row(
            children: [
              Container(
                padding: EdgeInsets.all(10.w),
                decoration: BoxDecoration(
                  color: AppColors.primaryLight,
                  borderRadius: BorderRadius.circular(10.r),
                ),
                child: Icon(
                  Icons.medical_services_outlined,
                  color: AppColors.primary,
                  size: 22.sp,
                ),
              ),
              SizedBox(width: 12.w),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Doktorum',
                    style: TextStyle(
                      fontSize: 12.sp,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  SizedBox(height: 2.h),
                  Text(
                    doctorName,
                    style: TextStyle(
                      fontSize: 15.sp,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
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

  Widget _buildPrescriptionsSection(BuildContext context) {
    return BlocBuilder<AuthCubit, AuthState>(
      builder: (context, authState) {
        final user = authState is AuthAuthenticated ? authState.user : null;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Aktif Reçetelerim',
                  style: TextStyle(
                    fontSize: 18.sp,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                if (user != null)
                  TextButton(
                    onPressed: () => context.push(
                      RouteNames.prescriptionList,
                      extra: user.uid,
                    ),
                    child: const Text('Tümünü Gör'),
                  ),
              ],
            ),
            SizedBox(height: 12.h),
            BlocBuilder<PrescriptionCubit, PrescriptionState>(
              builder: (context, state) {
                if (state is PrescriptionLoading) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (state is PrescriptionListLoaded) {
                  final active = state.prescriptions
                      .where((p) => p.isActive)
                      .toList();
                  if (active.isEmpty) {
                    return _emptyPrescriptions();
                  }
                  return Column(
                    children: active
                        .take(2)
                        .map((p) => _buildPrescriptionCard(context, p))
                        .toList(),
                  );
                }
                return _emptyPrescriptions();
              },
            ),
          ],
        );
      },
    );
  }

  Widget _emptyPrescriptions() {
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
          Icon(
            Icons.description_outlined,
            size: 48.sp,
            color: AppColors.textDisabled,
          ),
          SizedBox(height: 12.h),
          Text(
            'Aktif reçeteniz bulunmuyor',
            style: TextStyle(fontSize: 14.sp, color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }

  Widget _buildPrescriptionCard(BuildContext context, PrescriptionEntity p) {
    return GestureDetector(
      onTap: () => context.push(RouteNames.prescriptionDetail, extra: p),
      child: Container(
        width: double.infinity,
        margin: EdgeInsets.only(bottom: 8.h),
        padding: EdgeInsets.all(16.w),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(color: AppColors.divider),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Dr. ${p.doctorName}',
                  style: TextStyle(
                    fontSize: 15.sp,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                  decoration: BoxDecoration(
                    color: AppColors.primaryLight,
                    borderRadius: BorderRadius.circular(6.r),
                  ),
                  child: Text(
                    'Aktif',
                    style: TextStyle(
                      fontSize: 12.sp,
                      color: AppColors.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 6.h),
            Text(
              '${p.drugs.length} ilaç',
              style: TextStyle(fontSize: 13.sp, color: AppColors.textSecondary),
            ),
            SizedBox(height: 4.h),
            Text(
              '${p.createdAt.day}.${p.createdAt.month}.${p.createdAt.year}',
              style: TextStyle(fontSize: 12.sp, color: AppColors.textSecondary),
            ),
          ],
        ),
      ),
    );
  }

  String _todayFormatted() {
    final now = DateTime.now();
    const months = [
      'Ocak',
      'Şubat',
      'Mart',
      'Nisan',
      'Mayıs',
      'Haziran',
      'Temmuz',
      'Ağustos',
      'Eylül',
      'Ekim',
      'Kasım',
      'Aralık',
    ];
    return '${now.day} ${months[now.month - 1]} ${now.year}';
  }
}
