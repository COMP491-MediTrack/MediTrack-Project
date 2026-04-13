import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:meditrack/core/di/injection.dart';
import 'package:meditrack/core/theme/app_colors.dart';
import 'package:meditrack/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:meditrack/features/auth/presentation/cubit/auth_state.dart';
import 'package:meditrack/features/lab_results/domain/entities/lab_result_entity.dart';
import 'package:meditrack/features/lab_results/presentation/cubit/lab_result_cubit.dart';
import 'package:meditrack/features/lab_results/presentation/cubit/lab_result_state.dart';
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
      ],
      child: BlocListener<AuthCubit, AuthState>(
        listener: (context, authState) {
          if (authState is AuthAuthenticated) {
            final id = patientId ?? authState.user.uid;
            context.read<LabResultCubit>().loadLabResults(id);
          }
        },
        child: BlocBuilder<AuthCubit, AuthState>(
          builder: (context, authState) {
            final resolvedPatientId = patientId ??
                (authState is AuthAuthenticated ? authState.user.uid : null);

            return Scaffold(
              backgroundColor: AppColors.background,
              appBar: AppBar(
                title: Text(
                  isDoctor && patientName != null
                      ? '$patientName — Lab Sonuçları'
                      : 'Lab Sonuçlarım',
                ),
                centerTitle: true,
              ),
              floatingActionButton: !isDoctor && resolvedPatientId != null
                  ? FloatingActionButton.extended(
                      onPressed: () => _pickAndUpload(context, resolvedPatientId),
                      icon: const Icon(Icons.upload_file),
                      label: const Text('PDF Yükle'),
                    )
                  : null,
              body: BlocConsumer<LabResultCubit, LabResultState>(
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

                  final results = _extractResults(state);
                  if (results != null && results.isEmpty) {
                    return _buildEmptyState();
                  }
                  if (results != null && results.isNotEmpty) {
                    return _buildList(context, results, resolvedPatientId);
                  }

                  return const SizedBox();
                },
              ),
            );
          },
        ),
      ),
    );
  }

  List<LabResultEntity>? _extractResults(LabResultState state) {
    if (state is LabResultsLoaded) return state.results;
    if (state is LabResultUploaded) return state.results;
    if (state is LabResultDeleted) return state.results;
    return null;
  }

  Widget _buildEmptyState() {
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
          if (!isDoctor) ...[
            SizedBox(height: 8.h),
            Text(
              'PDF yüklemek için aşağıdaki butonu kullanın',
              style: TextStyle(fontSize: 13.sp, color: AppColors.textDisabled),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildList(
    BuildContext context,
    List<LabResultEntity> results,
    String? resolvedPatientId,
  ) {
    return ListView.separated(
      padding: EdgeInsets.all(16.w),
      itemCount: results.length,
      separatorBuilder: (_, __) => SizedBox(height: 12.h),
      itemBuilder: (_, index) => _buildCard(context, results[index], resolvedPatientId),
    );
  }

  Widget _buildCard(
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
              if (!isDoctor)
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
        content: Text('"${result.fileName}" silinecek. Emin misiniz?'),
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
