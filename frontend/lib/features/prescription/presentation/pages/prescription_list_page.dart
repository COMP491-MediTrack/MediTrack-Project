import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:go_router/go_router.dart';
import 'package:meditrack/core/constants/app_constants.dart';
import 'package:meditrack/core/di/injection.dart';
import 'package:meditrack/core/router/route_names.dart';
import 'package:meditrack/core/theme/app_colors.dart';
import 'package:meditrack/features/prescription/domain/entities/drug_item_entity.dart';
import 'package:meditrack/features/prescription/domain/entities/prescription_entity.dart';
import 'package:meditrack/features/prescription/presentation/cubit/prescription_cubit.dart';
import 'package:meditrack/features/prescription/presentation/cubit/prescription_state.dart';

class PrescriptionListPage extends StatelessWidget {
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
  Widget build(BuildContext context) {
    final isDoctor = doctorExtra != null;
    return BlocProvider(
      create: (_) => getIt<PrescriptionCubit>()..loadPatientPrescriptions(patientId),
      child: Scaffold(
        appBar: AppBar(
          title: Text(isDoctor && patientName != null ? patientName! : 'Reçetelerim'),
          centerTitle: true,
          actions: isDoctor
              ? [
                  IconButton(
                    icon: const Icon(Icons.science_outlined),
                    tooltip: 'Lab Sonuçları',
                    onPressed: () => context.push(
                      RouteNames.labResults,
                      extra: {
                        'patientId': patientId,
                        'patientName': patientName,
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
                  extra: doctorExtra,
                ),
                icon: const Icon(Icons.add),
                label: const Text('Yeni Reçete'),
              )
            : null,
        body: BlocBuilder<PrescriptionCubit, PrescriptionState>(
          builder: (context, state) {
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
              return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                stream: getIt<FirebaseFirestore>()
                    .collection(AppConstants.adherenceCollection)
                    .where('patient_id', isEqualTo: patientId)
                    .snapshots(),
                builder: (context, adherenceSnapshot) {
                  final takenDoseCountsByDrug = <String, int>{};
                  for (final doc in adherenceSnapshot.data?.docs ?? []) {
                    final data = doc.data();
                    final drugKey = data['drug_key'] as String?;
                    final doseCount = (data['dose_count'] as num?)?.toInt() ?? 1;
                    if (drugKey == null || drugKey.isEmpty) continue;
                    takenDoseCountsByDrug[drugKey] =
                        (takenDoseCountsByDrug[drugKey] ?? 0) + doseCount;
                  }

                  return ListView.separated(
                    padding: EdgeInsets.all(16.w),
                    itemCount: state.prescriptions.length,
                    separatorBuilder: (_, __) => SizedBox(height: 12.h),
                    itemBuilder: (_, index) {
                      final prescription = state.prescriptions[index];
                      final isCurrentlyActive = _isPrescriptionCurrentlyActive(
                        prescription,
                        takenDoseCountsByDrug,
                      );
                      return _buildPrescriptionCard(
                        context,
                        prescription,
                        isCurrentlyActive: isCurrentlyActive,
                      );
                    },
                  );
                },
              );
            }
            return const SizedBox();
          },
        ),
      ),
    );
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

  Widget _buildPrescriptionCard(
    BuildContext context,
    PrescriptionEntity prescription, {
    required bool isCurrentlyActive,
  }) {
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
                _buildStatusChip(isCurrentlyActive),
              ],
            ),
            SizedBox(height: 8.h),
            Text(
              '${prescription.drugs.length} ilaç',
              style: TextStyle(fontSize: 13.sp, color: AppColors.textSecondary),
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
          color: isActive
              ? AppColors.primary.withAlpha(77)
              : AppColors.error.withAlpha(77),
        ),
      ),
      child: Text(
        isActive ? 'Aktif' : 'İnaktif',
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

  bool _isPrescriptionCurrentlyActive(
    PrescriptionEntity prescription,
    Map<String, int> takenDoseCountsByDrug,
  ) {
    if (!prescription.isActive || prescription.drugs.isEmpty) return false;

    for (final drug in prescription.drugs) {
      final totalStock = _calculateDosesPerDay(drug.frequency) * drug.durationDays;
      if (totalStock <= 0) continue;
      final takenCount = takenDoseCountsByDrug[_drugKey(drug)] ?? 0;
      final remaining = (totalStock - takenCount).clamp(0, totalStock);
      if (remaining > 0) return true;
    }
    return false;
  }

  String _drugKey(DrugItemEntity drug) {
    if (drug.barcode.isNotEmpty) {
      return drug.barcode;
    }
    return '${drug.brandName}_${drug.frequency}_${drug.durationDays}'
        .toLowerCase();
  }

  int _calculateDosesPerDay(String frequency) {
    final normalized = frequency.toLowerCase();

    final turkishDailyMatch = RegExp(r'günde\s*(\d+)').firstMatch(normalized);
    if (turkishDailyMatch != null) {
      return int.tryParse(turkishDailyMatch.group(1) ?? '') ?? 1;
    }

    if (normalized.contains('x')) {
      final parts = normalized.split('x');
      if (parts.length == 2) {
        final times = int.tryParse(parts[0].trim()) ?? 1;
        final dose = int.tryParse(parts[1].trim()) ?? 1;
        return times * dose;
      }
    }

    if (normalized.contains('haftada')) {
      return 1;
    }

    return 1;
  }
}
