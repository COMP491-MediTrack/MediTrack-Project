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
import 'package:meditrack/features/prescription/domain/entities/prescription_entity.dart';
import 'package:meditrack/features/prescription/presentation/cubit/prescription_cubit.dart';
import 'package:meditrack/features/prescription/presentation/cubit/prescription_state.dart';

class PatientDashboardPage extends StatelessWidget {
  const PatientDashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => getIt<AuthCubit>()..checkAuthStatus()),
        BlocProvider(create: (_) => getIt<DashboardCubit>()),
        BlocProvider(create: (_) => getIt<PrescriptionCubit>()),
      ],
      child: BlocListener<AuthCubit, AuthState>(
        listener: (context, state) {
          if (state is AuthUnauthenticated) {
            context.go(RouteNames.login);
          } else if (state is AuthAuthenticated) {
            if (state.user.doctorId != null) {
              context.read<DashboardCubit>().loadDoctor(state.user.doctorId!);
            }
            context.read<PrescriptionCubit>().loadPatientPrescriptions(state.user.uid);
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

  AppBar _buildAppBar(BuildContext context) {
    return AppBar(
      title: const Text('MediTrack'),
      centerTitle: false,
      actions: [
        IconButton(
          icon: const Icon(Icons.logout_outlined),
          tooltip: 'Çıkış Yap',
          onPressed: () => context.read<AuthCubit>().logout(),
        ),
        SizedBox(width: 8.w),
      ],
    );
  }

  Widget _buildWelcomeCard(BuildContext context, UserEntity? user) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.primary, AppColors.primaryDark],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16.r),
      ),
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
              const Icon(Icons.calendar_today_outlined,
                  color: Colors.white70, size: 14),
              SizedBox(width: 6.w),
              Text(
                _todayFormatted(),
                style: TextStyle(fontSize: 13.sp, color: Colors.white70),
              ),
            ],
          ),
        ],
      ),
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
          Icon(Icons.description_outlined, size: 48.sp, color: AppColors.textDisabled),
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
                style: TextStyle(fontSize: 15.sp, fontWeight: FontWeight.w600),
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                decoration: BoxDecoration(
                  color: AppColors.primaryLight,
                  borderRadius: BorderRadius.circular(6.r),
                ),
                child: Text(
                  'Aktif',
                  style: TextStyle(fontSize: 12.sp, color: AppColors.primary, fontWeight: FontWeight.w600),
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
      'Ocak', 'Şubat', 'Mart', 'Nisan', 'Mayıs', 'Haziran',
      'Temmuz', 'Ağustos', 'Eylül', 'Ekim', 'Kasım', 'Aralık'
    ];
    return '${now.day} ${months[now.month - 1]} ${now.year}';
  }
}
