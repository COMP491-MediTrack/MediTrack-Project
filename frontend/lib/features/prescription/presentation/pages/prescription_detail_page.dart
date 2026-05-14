import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:meditrack/core/theme/app_colors.dart';
import 'package:meditrack/features/prescription/domain/entities/ddi_result_entity.dart';
import 'package:meditrack/features/prescription/domain/entities/drug_item_entity.dart';
import 'package:meditrack/features/prescription/domain/entities/prescription_entity.dart';

class PrescriptionDetailPage extends StatelessWidget {
  final PrescriptionEntity prescription;

  const PrescriptionDetailPage({super.key, required this.prescription});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Reçete Detayı'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildInfoCard(),
            if (prescription.hasDdiWarnings) ...[
              SizedBox(height: 16.h),
              _buildDdiWarningSection(prescription.interactions),
            ],
            SizedBox(height: 20.h),
            Text(
              'İlaçlar',
              style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.w600),
            ),
            SizedBox(height: 12.h),
            ...prescription.drugs.map(_buildDrugCard),
            SizedBox(height: 16.h),
          ],
        ),
      ),
    );
  }

  Widget _buildDdiWarningSection(List<DdiInteractionEntity> interactions) {
    return Container(
      padding: EdgeInsets.all(14.w),
      decoration: BoxDecoration(
        color: AppColors.warning.withAlpha(20),
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: AppColors.warning.withAlpha(100)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: AppColors.warning, size: 18.sp),
              SizedBox(width: 6.w),
              Text(
                'İlaç Etkileşimi Uyarısı',
                style: TextStyle(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w700,
                  color: AppColors.warning,
                ),
              ),
            ],
          ),
          SizedBox(height: 10.h),
          ...interactions.map((i) => _DdiInteractionItem(interaction: i)),
        ],
      ),
    );
  }

  Widget _buildInfoCard() {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: AppColors.primaryContainer,
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: Column(
        children: [
          _buildInfoRow(Icons.person_outline, 'Hasta', prescription.patientName),
          SizedBox(height: 10.h),
          _buildInfoRow(Icons.medical_services_outlined, 'Doktor', 'Dr. ${prescription.doctorName}'),
          SizedBox(height: 10.h),
          _buildInfoRow(Icons.calendar_today_outlined, 'Tarih', _formatDate(prescription.createdAt)),
          SizedBox(height: 10.h),
          _buildInfoRow(
            Icons.check_circle_outline,
            'Durum',
            prescription.isActive ? 'Aktif' : 'Tamamlandı',
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 18.sp, color: AppColors.primary),
        SizedBox(width: 8.w),
        Text(
          '$label: ',
          style: TextStyle(fontSize: 14.sp, color: AppColors.textSecondary),
        ),
        Expanded(
          child: Text(
            value,
            style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
          ),
        ),
      ],
    );
  }

  Widget _buildDrugCard(DrugItemEntity drug) {
    return Container(
      margin: EdgeInsets.only(bottom: 12.h),
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            drug.brandName,
            style: TextStyle(fontSize: 15.sp, fontWeight: FontWeight.w600),
          ),
          SizedBox(height: 4.h),
          // Text(
          //   drug.genericName,
          //   style: TextStyle(fontSize: 12.sp, color: AppColors.textSecondary),
          // ),
          SizedBox(height: 8.h),
          Wrap(
            spacing: 8.w,
            runSpacing: 4.h,
            children: [
              _buildTag(Icons.medication_outlined, drug.dosage),
              _buildTag(Icons.access_time_outlined, drug.frequency),
              _buildTag(Icons.calendar_month_outlined, '${drug.durationDays} gün'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTag(IconData icon, String text) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
      decoration: BoxDecoration(
        color: AppColors.primaryLight,
        borderRadius: BorderRadius.circular(8.r),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14.sp, color: AppColors.background),
          SizedBox(width: 4.w),
          Text(
            text,
            style: TextStyle(fontSize: 12.sp, color: AppColors.background),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}.${date.month}.${date.year}';
  }
}

class _DdiInteractionItem extends StatefulWidget {
  final DdiInteractionEntity interaction;

  const _DdiInteractionItem({required this.interaction});

  @override
  State<_DdiInteractionItem> createState() => _DdiInteractionItemState();
}

class _DdiInteractionItemState extends State<_DdiInteractionItem> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final i = widget.interaction;
    return Padding(
      padding: EdgeInsets.only(bottom: 10.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${i.drug1} + ${i.drug2}',
            style: TextStyle(
              fontSize: 13.sp,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          SizedBox(height: 2.h),
          Text(
            i.description,
            style: TextStyle(fontSize: 12.sp, color: AppColors.textSecondary),
          ),
          if (i.aiExplanation != null) ...[
            SizedBox(height: 6.h),
            InkWell(
              onTap: () => setState(() => _expanded = !_expanded),
              borderRadius: BorderRadius.circular(4.r),
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 2.h),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.auto_awesome, size: 13.sp, color: AppColors.primary),
                    SizedBox(width: 4.w),
                    Text(
                      'AI Klinik Açıklama',
                      style: TextStyle(
                        fontSize: 11.sp,
                        color: AppColors.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Icon(
                      _expanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                      size: 14.sp,
                      color: AppColors.primary,
                    ),
                  ],
                ),
              ),
            ),
            if (_expanded) ...[
              SizedBox(height: 4.h),
              Container(
                padding: EdgeInsets.all(8.w),
                decoration: BoxDecoration(
                  color: AppColors.primaryContainer,
                  borderRadius: BorderRadius.circular(8.r),
                ),
                child: Text(
                  i.aiExplanation!,
                  style: TextStyle(
                    fontSize: 11.sp,
                    color: AppColors.textPrimary,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
            ],
          ],
        ],
      ),
    );
  }
}
