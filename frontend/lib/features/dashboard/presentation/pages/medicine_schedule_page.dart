import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:meditrack/core/di/injection.dart';
import 'package:meditrack/core/theme/app_colors.dart';
import 'package:meditrack/features/prescription/domain/entities/drug_item_entity.dart';
import 'package:meditrack/features/prescription/presentation/cubit/prescription_cubit.dart';
import 'package:meditrack/features/prescription/presentation/cubit/prescription_state.dart';

class MedicineSchedulePage extends StatelessWidget {
  final String patientId;

  const MedicineSchedulePage({super.key, required this.patientId});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<PrescriptionCubit>()..loadPatientPrescriptions(patientId),
      child: DefaultTabController(
        length: 2,
        child: Scaffold(
          appBar: AppBar(
            title: const Text('İlaç Takvimi ve Stoklar'),
            bottom: const TabBar(
              tabs: [
                Tab(text: 'Haftalık Takvim'),
                Tab(text: 'İlaç Stoklarım'),
              ],
            ),
          ),
          body: BlocBuilder<PrescriptionCubit, PrescriptionState>(
            builder: (context, state) {
              if (state is PrescriptionLoading) {
                return const Center(child: CircularProgressIndicator());
              }
              if (state is PrescriptionListLoaded) {
                final activePrescriptions = state.prescriptions.where((p) => p.isActive).toList();
                
                if (activePrescriptions.isEmpty) {
                  return const Center(
                    child: Text('Aktif reçeteniz bulunmuyor.'),
                  );
                }

                // Extract all active drugs
                final List<DrugItemEntity> allDrugs = [];
                for (var p in activePrescriptions) {
                  allDrugs.addAll(p.drugs);
                }

                return TabBarView(
                  children: [
                    _buildWeeklySchedule(allDrugs),
                    _buildStocks(allDrugs),
                  ],
                );
              }
              return const Center(child: Text('Bir hata oluştu.'));
            },
          ),
        ),
      ),
    );
  }

  Widget _buildWeeklySchedule(List<DrugItemEntity> drugs) {
    final days = ['Pazartesi', 'Salı', 'Çarşamba', 'Perşembe', 'Cuma', 'Cumartesi', 'Pazar'];
    
    return ListView.builder(
      padding: EdgeInsets.all(16.w),
      itemCount: days.length,
      itemBuilder: (context, index) {
        return Card(
          margin: EdgeInsets.only(bottom: 16.h),
          child: ExpansionTile(
            title: Text(days[index], style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16.sp)),
            initiallyExpanded: index == DateTime.now().weekday - 1, // Expand today if applicable
            children: drugs.map((drug) {
              return ListTile(
                leading: Container(
                  padding: EdgeInsets.all(8.w),
                  decoration: BoxDecoration(
                    color: AppColors.primaryLight,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.medication, color: AppColors.primary),
                ),
                title: Text(drug.brandName, style: TextStyle(fontWeight: FontWeight.w600)),
                subtitle: Text('Kullanım: ${drug.frequency}'),
              );
            }).toList(),
          ),
        );
      },
    );
  }

  Widget _buildStocks(List<DrugItemEntity> drugs) {
    return ListView.builder(
      padding: EdgeInsets.all(16.w),
      itemCount: drugs.length,
      itemBuilder: (context, index) {
        final drug = drugs[index];
        // Parse frequency (like '2x1') to get total doses per day
        int dosesPerDay = 1;
        if (drug.frequency.contains('x')) {
          final parts = drug.frequency.toLowerCase().split('x');
          if (parts.length == 2) {
             int time = int.tryParse(parts[0].trim()) ?? 1;
             int dose = int.tryParse(parts[1].trim()) ?? 1;
             dosesPerDay = time * dose;
          }
        }
        
        int totalStock = dosesPerDay * drug.durationDays;

        return Card(
          margin: EdgeInsets.only(bottom: 12.h),
          child: ListTile(
            leading: const Icon(Icons.inventory_2_outlined, color: AppColors.primary, size: 32),
            title: Text(drug.brandName, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16.sp)),
            subtitle: Padding(
              padding: EdgeInsets.only(top: 8.h),
              child: Text('${drug.durationDays} günlük tedavi (${drug.frequency})'),
            ),
            trailing: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('Tahmini Kalan:', style: TextStyle(fontSize: 12.sp, color: Colors.grey[600])),
                SizedBox(height: 4.h),
                Text('$totalStock doz', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary, fontSize: 16.sp)),
              ],
            ),
          ),
        );
      },
    );
  }
}
