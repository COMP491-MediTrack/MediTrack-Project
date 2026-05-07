import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:meditrack/core/di/injection.dart';
import 'package:meditrack/core/router/route_names.dart';
import 'package:meditrack/core/theme/app_colors.dart';
import 'package:meditrack/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:meditrack/features/auth/presentation/cubit/auth_state.dart';
import 'package:meditrack/features/lab_results/domain/entities/test_request_entity.dart';
import 'package:meditrack/features/lab_results/presentation/cubit/lab_result_cubit.dart';
import 'package:meditrack/features/lab_results/presentation/cubit/lab_result_state.dart';
import 'package:meditrack/features/lab_results/presentation/cubit/test_request_cubit.dart';
import 'package:meditrack/features/lab_results/presentation/cubit/test_request_state.dart';

class LabDashboardPage extends StatelessWidget {
  const LabDashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => getIt<AuthCubit>()..checkAuthStatus()),
        BlocProvider(
          create: (_) => getIt<TestRequestCubit>()..loadAllTestRequests(),
        ),
        BlocProvider(create: (_) => getIt<LabResultCubit>()),
      ],
      child: BlocListener<AuthCubit, AuthState>(
        listener: (context, state) {
          if (state is AuthUnauthenticated) {
            context.go(RouteNames.login);
          }
        },
        child: BlocBuilder<AuthCubit, AuthState>(
          builder: (context, authState) {
            final user =
                authState is AuthAuthenticated ? authState.user : null;
            return Scaffold(
              backgroundColor: AppColors.background,
              appBar: _buildAppBar(context),
              body: SafeArea(
                child: RefreshIndicator(
                  onRefresh: () async =>
                      context.read<TestRequestCubit>().loadAllTestRequests(),
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: EdgeInsets.all(20.w),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildWelcomeCard(user?.name),
                        SizedBox(height: 24.h),
                        _buildUploadFeedback(),
                        _buildRequestsSection(context),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
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

  Widget _buildWelcomeCard(String? name) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF00695C), Color(0xFF26A69A)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16.r),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF00695C).withAlpha(76),
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
                  name ?? '',
                  style: TextStyle(
                    fontSize: 22.sp,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                SizedBox(height: 8.h),
                Text(
                  'Laboratuvar Paneli',
                  style: TextStyle(fontSize: 13.sp, color: Colors.white70),
                ),
              ],
            ),
          ),
          Icon(Icons.science_rounded, color: Colors.white.withAlpha(204), size: 48.sp),
        ],
      ),
    );
  }

  /// LabResultCubit'ten gelen upload feedback'i gösterir
  Widget _buildUploadFeedback() {
    return BlocConsumer<LabResultCubit, LabResultState>(
      listener: (context, state) {
        if (state is LabResultUploaded) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Lab sonucu başarıyla yüklendi'),
              backgroundColor: AppColors.success,
            ),
          );
          // Listeyi yenile
          context.read<TestRequestCubit>().loadAllTestRequests();
        }
        if (state is LabResultError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: AppColors.error,
            ),
          );
        }
      },
      builder: (context, state) {
        if (state is LabResultUploading) {
          return Padding(
            padding: EdgeInsets.only(bottom: 16.h),
            child: Container(
              padding: EdgeInsets.all(14.w),
              decoration: BoxDecoration(
                color: AppColors.primaryContainer,
                borderRadius: BorderRadius.circular(12.r),
              ),
              child: Row(
                children: [
                  SizedBox(
                    width: 18.w,
                    height: 18.h,
                    child: const CircularProgressIndicator(strokeWidth: 2),
                  ),
                  SizedBox(width: 12.w),
                  Text(
                    'PDF yükleniyor...',
                    style:
                        TextStyle(fontSize: 14.sp, color: AppColors.textPrimary),
                  ),
                ],
              ),
            ),
          );
        }
        return const SizedBox.shrink();
      },
    );
  }

  Widget _buildRequestsSection(BuildContext context) {
    return BlocBuilder<TestRequestCubit, TestRequestState>(
      builder: (context, state) {
        if (state is TestRequestLoading) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.only(top: 60),
              child: CircularProgressIndicator(),
            ),
          );
        }

        if (state is TestRequestError) {
          return Center(
            child: Padding(
              padding: EdgeInsets.only(top: 40.h),
              child: Column(
                children: [
                  Icon(Icons.error_outline,
                      size: 48.sp, color: AppColors.error),
                  SizedBox(height: 12.h),
                  Text(state.message,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          fontSize: 14.sp, color: AppColors.textSecondary)),
                  SizedBox(height: 16.h),
                  FilledButton(
                    onPressed: () =>
                        context.read<TestRequestCubit>().loadAllTestRequests(),
                    child: const Text('Tekrar Dene'),
                  ),
                ],
              ),
            ),
          );
        }

        if (state is TestRequestsLoaded) {
          final all = state.testRequests;
          final pending =
              all.where((r) => r.status == 'Bekliyor').toList();
          final completed =
              all.where((r) => r.status != 'Bekliyor').toList();

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSectionHeader(
                'Bekleyen İstekler',
                pending.length,
                Colors.orange,
              ),
              SizedBox(height: 12.h),
              if (pending.isEmpty)
                _buildEmpty('Bekleyen tahlil isteği yok')
              else
                ...pending.map(
                  (r) => _buildRequestCard(context, r, isPending: true),
                ),
              SizedBox(height: 24.h),
              _buildSectionHeader(
                'Tamamlananlar',
                completed.length,
                AppColors.success,
              ),
              SizedBox(height: 12.h),
              if (completed.isEmpty)
                _buildEmpty('Henüz tamamlanmış istek yok')
              else
                ...completed.map(
                  (r) => _buildRequestCard(context, r, isPending: false),
                ),
              SizedBox(height: 24.h),
            ],
          );
        }

        return const SizedBox.shrink();
      },
    );
  }

  Widget _buildSectionHeader(String title, int count, Color color) {
    return Row(
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 18.sp,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        SizedBox(width: 8.w),
        Container(
          padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 2.h),
          decoration: BoxDecoration(
            color: color.withAlpha(30),
            borderRadius: BorderRadius.circular(12.r),
          ),
          child: Text(
            '$count',
            style: TextStyle(
              fontSize: 13.sp,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEmpty(String message) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(24.w),
      margin: EdgeInsets.only(bottom: 8.h),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: AppColors.divider),
      ),
      child: Text(
        message,
        textAlign: TextAlign.center,
        style: TextStyle(fontSize: 14.sp, color: AppColors.textSecondary),
      ),
    );
  }

  Widget _buildRequestCard(
    BuildContext context,
    TestRequestEntity request, {
    required bool isPending,
  }) {
    return Container(
      margin: EdgeInsets.only(bottom: 12.h),
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(
          color: isPending
              ? Colors.orange.withAlpha(76)
              : AppColors.divider,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Başlık satırı
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      request.patientName != null
                          ? 'Hasta: ${request.patientName}'
                          : 'Hasta ID: ${request.patientId.substring(0, 8)}...',
                      style: TextStyle(
                        fontSize: 15.sp,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    SizedBox(height: 2.h),
                    Text(
                      'Dr. ${request.doctorName}',
                      style: TextStyle(
                          fontSize: 13.sp, color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),
              _buildStatusBadge(request.status),
            ],
          ),
          SizedBox(height: 10.h),
          // İstenen tahliller
          Wrap(
            spacing: 6.w,
            runSpacing: 4.h,
            children: request.requestedTests
                .map(
                  (t) => Chip(
                    label: Text(t, style: TextStyle(fontSize: 11.sp)),
                    backgroundColor: AppColors.primaryContainer,
                    side: BorderSide.none,
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    padding: EdgeInsets.symmetric(horizontal: 4.w),
                  ),
                )
                .toList(),
          ),
          SizedBox(height: 10.h),
          // Tarih + Aksiyon
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _formatDate(request.createdAt),
                style: TextStyle(
                    fontSize: 12.sp, color: AppColors.textDisabled),
              ),
              if (isPending)
                FilledButton.icon(
                  onPressed: () =>
                      _pickAndUploadResult(context, request.patientId),
                  icon: Icon(Icons.upload_file, size: 16.sp),
                  label: Text('Sonuç Yükle', style: TextStyle(fontSize: 13.sp)),
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF00695C),
                    padding: EdgeInsets.symmetric(
                        horizontal: 14.w, vertical: 8.h),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    final isPending = status == 'Bekliyor';
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
      decoration: BoxDecoration(
        color: isPending
            ? Colors.orange.withAlpha(30)
            : AppColors.successContainer,
        borderRadius: BorderRadius.circular(8.r),
      ),
      child: Text(
        status,
        style: TextStyle(
          fontSize: 12.sp,
          fontWeight: FontWeight.w600,
          color: isPending ? Colors.orange[800] : AppColors.success,
        ),
      ),
    );
  }

  Future<void> _pickAndUploadResult(
      BuildContext context, String patientId) async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
      withData: true,
    );
    if (result == null || result.files.isEmpty) return;
    final file = result.files.first;
    if (file.bytes == null) return;
    if (!context.mounted) return;

    context.read<LabResultCubit>().uploadLabResult(
          patientId: patientId,
          bytes: file.bytes!,
          fileName: file.name,
        );
  }

  String _formatDate(DateTime date) {
    const months = [
      'Oca', 'Şub', 'Mar', 'Nis', 'May', 'Haz',
      'Tem', 'Ağu', 'Eyl', 'Eki', 'Kas', 'Ara',
    ];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }
}
