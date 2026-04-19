import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:meditrack/core/di/injection.dart';
import 'package:meditrack/core/theme/app_colors.dart';
import 'package:meditrack/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:meditrack/features/auth/presentation/cubit/auth_state.dart';
import 'package:meditrack/features/lab_results/domain/entities/lab_result_entity.dart';
import 'package:meditrack/features/lab_results/domain/entities/test_request_entity.dart';
import 'package:meditrack/features/lab_results/presentation/cubit/lab_result_cubit.dart';
import 'package:meditrack/features/lab_results/presentation/cubit/lab_result_state.dart';
import 'package:meditrack/features/lab_results/presentation/cubit/test_request_cubit.dart';
import 'package:meditrack/features/lab_results/presentation/cubit/test_request_state.dart';
import 'package:url_launcher/url_launcher.dart';

class LabResultsPage extends StatelessWidget {
  final String? patientId;
  final String? patientName;
  final bool isDoctor;

  const LabResultsPage({
    super.key,
    this.patientId,
    this.patientName,
    this.isDoctor = false,
  });

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => getIt<AuthCubit>()..checkAuthStatus()),
        BlocProvider(create: (_) => getIt<LabResultCubit>()),
        BlocProvider(create: (_) => getIt<TestRequestCubit>()),
      ],
      child: BlocListener<AuthCubit, AuthState>(
        listener: (context, authState) {
          if (authState is AuthAuthenticated) {
            final id = patientId ?? authState.user.uid;
            context.read<LabResultCubit>().loadLabResults(id);
            context.read<TestRequestCubit>().loadTestRequests(id);
          }
        },
        child: BlocBuilder<AuthCubit, AuthState>(
          builder: (context, authState) {
            final resolvedPatientId = patientId ??
                (authState is AuthAuthenticated ? authState.user.uid : null);

            return DefaultTabController(
              length: 2,
              child: Scaffold(
                backgroundColor: AppColors.background,
                appBar: AppBar(
                  title: Text(
                    isDoctor && patientName != null
                        ? '${patientName} — Sonuçlar & İstekler'
                        : 'Lab Sonuçları & İstekler',
                  ),
                  centerTitle: true,
                  bottom: const TabBar(
                    tabs: [
                      Tab(text: 'Sonuçlar'),
                      Tab(text: 'İstekler'),
                    ],
                  ),
                ),
                floatingActionButton: isDoctor && resolvedPatientId != null
                    ? FloatingActionButton.extended(
                        onPressed: () => _pickAndUpload(context, resolvedPatientId),
                        icon: const Icon(Icons.upload_file),
                        label: const Text('PDF Yükle'),
                      )
                    : null,
                body: TabBarView(
                  children: [
                    _buildLabResultsTab(resolvedPatientId),
                    _buildTestRequestsTab(),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildLabResultsTab(String? resolvedPatientId) {
    return BlocConsumer<LabResultCubit, LabResultState>(
      listener: (context, state) {
        if (state is LabResultError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: AppColors.error,
            ),
          );
        }
        if (state is LabResultUploaded) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Lab sonucu başarıyla yüklendi'),
              backgroundColor: AppColors.success,
            ),
          );
        }
      },
      builder: (context, state) {
        if (state is LabResultLoading || state is LabResultUploading) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const CircularProgressIndicator(),
                if (state is LabResultUploading) ...[
                  SizedBox(height: 16.h),
                  Text(
                    'Yükleniyor...',
                    style: TextStyle(
                      fontSize: 14.sp,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ],
            ),
          );
        }

        final results = _extractLabResults(state);
        if (results != null && results.isEmpty) {
          return _buildEmptyLabResultsState();
        }
        if (results != null && results.isNotEmpty) {
          return _buildLabResultsList(context, results, resolvedPatientId);
        }

        return const SizedBox();
      },
    );
  }

  Widget _buildTestRequestsTab() {
    return BlocBuilder<TestRequestCubit, TestRequestState>(
      builder: (context, state) {
        if (state is TestRequestLoading) {
          return const Center(child: CircularProgressIndicator());
        }
        if (state is TestRequestsLoaded) {
          if (state.testRequests.isEmpty) {
            return _buildEmptyTestRequestsState();
          }
          return _buildTestRequestsList(state.testRequests);
        }
        if (state is TestRequestError) {
          return Center(child: Text(state.message));
        }
        return const SizedBox();
      },
    );
  }

  List<LabResultEntity>? _extractLabResults(LabResultState state) {
    if (state is LabResultsLoaded) return state.results;
    if (state is LabResultUploaded) return state.results;
    if (state is LabResultDeleted) return state.results;
    return null;
  }

  Widget _buildEmptyLabResultsState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.science_outlined, size: 64.sp, color: AppColors.textDisabled),
          SizedBox(height: 16.h),
          Text(
            'Henüz lab sonucu yüklenmedi',
            style: TextStyle(fontSize: 16.sp, color: AppColors.textSecondary),
          ),
          if (isDoctor) ...[
            SizedBox(height: 8.h),
            Text(
              'PDF yüklemek için aşağıdaki butonu kullanın',
              style: TextStyle(fontSize: 13.sp, color: AppColors.textDisabled),
            ),
          ] else ...[
            SizedBox(height: 8.h),
            Text(
              'Doktorunuz henüz sonuç yüklemedi',
              style: TextStyle(fontSize: 13.sp, color: AppColors.textDisabled),
            ),
          ]
        ],
      ),
    );
  }

  Widget _buildEmptyTestRequestsState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.assignment_outlined, size: 64.sp, color: AppColors.textDisabled),
          SizedBox(height: 16.h),
          Text(
            'Henüz oluşturulmuş bir istek formu yok',
            style: TextStyle(fontSize: 16.sp, color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }

  Widget _buildLabResultsList(
    BuildContext context,
    List<LabResultEntity> results,
    String? resolvedPatientId,
  ) {
    return ListView.separated(
      padding: EdgeInsets.all(16.w),
      itemCount: results.length,
      separatorBuilder: (_, __) => SizedBox(height: 12.h),
      itemBuilder: (_, index) => _buildLabResultCard(context, results[index], resolvedPatientId),
    );
  }

  Widget _buildTestRequestsList(List<TestRequestEntity> requests) {
    return ListView.separated(
      padding: EdgeInsets.all(16.w),
      itemCount: requests.length,
      separatorBuilder: (_, __) => SizedBox(height: 12.h),
      itemBuilder: (context, index) {
        final request = requests[index];
        return Container(
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
                    'Dr. ${request.doctorName}',
                    style: TextStyle(
                      fontSize: 15.sp,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                    decoration: BoxDecoration(
                      color: AppColors.primaryLight,
                      borderRadius: BorderRadius.circular(6.r),
                    ),
                    child: Text(
                      request.status,
                      style: TextStyle(
                        fontSize: 12.sp,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 8.h),
              Text(
                'İstenen Tahliller:',
                style: TextStyle(
                  fontSize: 13.sp,
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              SizedBox(height: 4.h),
              Wrap(
                spacing: 8.w,
                runSpacing: 4.h,
                children: request.requestedTests.map((test) => Chip(
                  label: Text(test, style: TextStyle(fontSize: 12.sp)),
                  backgroundColor: AppColors.background,
                  side: BorderSide(color: AppColors.divider),
                )).toList(),
              ),
              SizedBox(height: 8.h),
              Text(
                _formatDate(request.createdAt),
                style: TextStyle(fontSize: 12.sp, color: AppColors.textDisabled),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildLabResultCard(
    BuildContext context,
    LabResultEntity result,
    String? resolvedPatientId,
  ) {
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
            child: Icon(Icons.picture_as_pdf, color: AppColors.primary, size: 24.sp),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  result.fileName,
                  style: TextStyle(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: 2.h),
                Text(
                  _formatDate(result.uploadedAt),
                  style: TextStyle(fontSize: 12.sp, color: AppColors.textSecondary),
                ),
                if (result.notes != null && result.notes!.isNotEmpty) ...[
                  SizedBox(height: 2.h),
                  Text(
                    result.notes!,
                    style: TextStyle(fontSize: 12.sp, color: AppColors.textSecondary),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: Icon(Icons.open_in_new, size: 20.sp, color: AppColors.primary),
                tooltip: 'Aç',
                onPressed: () => _openPdf(result.fileUrl),
              ),
              if (isDoctor)
                IconButton(
                  icon: Icon(Icons.delete_outline, size: 20.sp, color: AppColors.error),
                  tooltip: 'Sil',
                  onPressed: () => _confirmDelete(context, result, resolvedPatientId),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _pickAndUpload(BuildContext context, String patientId) async {
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

  Future<void> _openPdf(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  void _confirmDelete(
    BuildContext context,
    LabResultEntity result,
    String? resolvedPatientId,
  ) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Lab Sonucunu Sil'),
        content: Text('"\${result.fileName}" silinecek. Emin misiniz?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('İptal'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              context.read<LabResultCubit>().deleteLabResult(
                    labResultId: result.id,
                    patientId: resolvedPatientId ?? result.patientId,
                    fileName: result.fileName,
                  );
            },
            child: Text('Sil', style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
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
