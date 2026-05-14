import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:meditrack/core/di/injection.dart';
import 'package:meditrack/core/router/route_names.dart';
import 'package:meditrack/core/theme/app_colors.dart';
import 'package:meditrack/features/prescription/domain/entities/prescription_entity.dart';
import 'package:meditrack/features/prescription/presentation/cubit/prescription_cubit.dart';
import 'package:meditrack/features/prescription/presentation/cubit/prescription_state.dart';

class PrescriptionListPage extends StatefulWidget {
  final String patientId;
  final String? patientName;
  final Map<String, dynamic>? doctorExtra;

  const PrescriptionListPage({
    super.key,
    required this.patientId,
    this.patientName,
    this.doctorExtra,
  });

  @override
  State<PrescriptionListPage> createState() => _PrescriptionListPageState();
}

class _PrescriptionListPageState extends State<PrescriptionListPage> {
  @override
  Widget build(BuildContext context) {
    final isDoctor = widget.doctorExtra != null;
    return BlocProvider(
      create: (_) => getIt<PrescriptionCubit>()..watchPatientPrescriptions(widget.patientId),
      child: BlocConsumer<PrescriptionCubit, PrescriptionState>(
        listener: (context, state) {
          if (state is PrescriptionCreated) {
            context.read<PrescriptionCubit>().loadPatientPrescriptions(widget.patientId);
          }
        },
        buildWhen: (_, current) => current is! PrescriptionCreated,
        builder: (context, state) {
          return Scaffold(
            appBar: AppBar(
              title: Text(
                isDoctor && widget.patientName != null
                    ? widget.patientName!
                    : 'Reçetelerim',
              ),
              centerTitle: true,
              actions: isDoctor
                  ? [
                      IconButton(
                        icon: const Icon(Icons.science_outlined),
                        tooltip: 'Lab Sonuçları',
                        onPressed: () => context.push(
                          RouteNames.labResults,
                          extra: {
                            'patientId': widget.patientId,
                            'patientName': widget.patientName,
                            'isDoctor': true,
                          },
                        ),
                      ),
                      SizedBox(width: 8.w),
                    ]
                  : null,
            ),
            floatingActionButton: isDoctor
                ? FloatingActionButton.extended(
                    onPressed: () => context.push(
                      RouteNames.createPrescription,
                      extra: {
                        ...widget.doctorExtra!,
                        'cubit': context.read<PrescriptionCubit>(),
                      },
                    ),
                    icon: const Icon(Icons.add),
                    label: const Text('Yeni Reçete'),
                  )
                : null,
            body: _buildBody(context, state),
          );
        },
      ),
    );
  }

  Widget _buildBody(BuildContext context, PrescriptionState state) {
    if (state is PrescriptionLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (state is PrescriptionError) {
      return Center(child: Text(state.message));
    }
    if (state is PrescriptionListLoaded) {
      if (state.prescriptions.isEmpty) {
        return _buildEmptyState();
      }
      return ListView.separated(
        padding: EdgeInsets.all(16.w),
        itemCount: state.prescriptions.length,
        separatorBuilder: (_, __) => SizedBox(height: 12.h),
        itemBuilder: (_, index) {
          final prescription = state.prescriptions[index];
          return _buildPrescriptionCard(context, prescription);
        },
      );
    }
    return const SizedBox();
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.receipt_long_outlined, size: 64.sp, color: AppColors.textSecondary),
          SizedBox(height: 16.h),
          Text(
            'Henüz reçeteniz yok',
            style: TextStyle(fontSize: 16.sp, color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }

  Widget _buildPrescriptionCard(BuildContext context, PrescriptionEntity prescription) {
    return InkWell(
      onTap: () => context.push(RouteNames.prescriptionDetail, extra: prescription),
      borderRadius: BorderRadius.circular(12.r),
      child: Container(
        padding: EdgeInsets.all(16.w),
        decoration: BoxDecoration(
          color: Colors.white,
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
                  'Dr. ${prescription.doctorName}',
                  style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w600),
                ),
                _buildStatusChip(prescription.isActive),
              ],
            ),
            SizedBox(height: 8.h),
            ...prescription.drugs.map(
              (drug) => Padding(
                padding: EdgeInsets.only(bottom: 2.h),
                child: Text(
                  '• ${drug.brandName}',
                  style: TextStyle(fontSize: 13.sp, color: AppColors.textSecondary),
                ),
              ),
            ),
            SizedBox(height: 4.h),
            Text(
              _formatDate(prescription.createdAt),
              style: TextStyle(fontSize: 12.sp, color: AppColors.textSecondary),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusChip(bool isActive) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
      decoration: BoxDecoration(
        color: isActive ? AppColors.primaryContainer : AppColors.errorContainer,
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(
          color: isActive ? AppColors.primary.withAlpha(77) : AppColors.error.withAlpha(77),
        ),
      ),
      child: Text(
        isActive ? 'Aktif' : 'Tamamlandı',
        style: TextStyle(
          fontSize: 12.sp,
          color: isActive ? AppColors.primaryDark : AppColors.error,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}.${date.month}.${date.year}';
  }
}
