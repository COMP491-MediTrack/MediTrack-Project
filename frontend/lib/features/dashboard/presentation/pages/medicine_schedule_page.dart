import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:meditrack/core/constants/app_constants.dart';
import 'package:meditrack/core/di/injection.dart';
import 'package:meditrack/core/theme/app_colors.dart';
import 'package:meditrack/features/prescription/domain/entities/drug_item_entity.dart';
import 'package:meditrack/features/prescription/domain/entities/prescription_entity.dart';
import 'package:meditrack/features/prescription/presentation/cubit/prescription_cubit.dart';
import 'package:meditrack/features/prescription/presentation/cubit/prescription_state.dart';
import 'package:meditrack/features/dashboard/presentation/cubit/streak_cubit.dart';
import 'package:meditrack/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:meditrack/features/auth/presentation/cubit/auth_state.dart';
import 'package:meditrack/features/auth/domain/entities/user_entity.dart';

class MedicineSchedulePage extends StatefulWidget {
  final String patientId;

  const MedicineSchedulePage({super.key, required this.patientId});

  @override
  State<MedicineSchedulePage> createState() => _MedicineSchedulePageState();
}

class _MedicineSchedulePageState extends State<MedicineSchedulePage> {
  final FirebaseFirestore _firestore = getIt<FirebaseFirestore>();
  bool _isSavingTaken = false;
  bool _isLoadingAdherence = true;
  Map<String, int> _takenDoseCountsByDrug = {};
  Map<String, int> _todayTakenDoseCountsByDrug = {};
  List<PrescriptionEntity> _activePrescriptions = [];

  @override
  void initState() {
    super.initState();
    _loadAdherenceCounts();
  }

  Future<void> _loadAdherenceCounts() async {
    try {
      final snapshot = await _firestore
          .collection(AppConstants.adherenceCollection)
          .where('patient_id', isEqualTo: widget.patientId)
          .get();

      final counts = <String, int>{};
      final todayCounts = <String, int>{};
      final now = DateTime.now();
      for (final doc in snapshot.docs) {
        final data = doc.data();
        final drugKey = data['drug_key'] as String?;
        final doseCount = (data['dose_count'] as num?)?.toInt() ?? 1;
        if (drugKey == null || drugKey.isEmpty) continue;
        counts[drugKey] = (counts[drugKey] ?? 0) + doseCount;

        final takenAt = data['taken_at'];
        DateTime? takenAtDate;
        if (takenAt is Timestamp) {
          takenAtDate = takenAt.toDate();
        }
        if (takenAtDate != null &&
            takenAtDate.year == now.year &&
            takenAtDate.month == now.month &&
            takenAtDate.day == now.day) {
          todayCounts[drugKey] = (todayCounts[drugKey] ?? 0) + doseCount;
        }
      }

      if (!mounted) return;
      setState(() {
        _takenDoseCountsByDrug = counts;
        _todayTakenDoseCountsByDrug = todayCounts;
      });
    } finally {
      if (mounted) {
        setState(() => _isLoadingAdherence = false);
      }
    }
  }

  String _drugKey(DrugItemEntity drug) {
    if (drug.barcode.isNotEmpty) {
      return drug.barcode;
    }
    return '${drug.brandName}_${drug.frequency}_${drug.durationDays}'
        .toLowerCase();
  }

  Future<void> _markDrugAsTaken(DrugItemEntity drug) async {
    setState(() => _isSavingTaken = true);
    try {
      final drugKey = _drugKey(drug);
      final dailyLimit = _calculateDosesPerDay(drug.frequency);
      final todayTaken = _todayTakenDoseCountsByDrug[drugKey] ?? 0;

      if (todayTaken >= dailyLimit) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '${drug.brandName} için günlük doz limiti doldu ($dailyLimit/$dailyLimit)',
            ),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }

      await _firestore.collection(AppConstants.adherenceCollection).add({
        'patient_id': widget.patientId,
        'drug_key': drugKey,
        'drug_name': drug.brandName,
        'dose_count': 1,
        'taken_at': Timestamp.now(),
      });

      if (!mounted) return;
      setState(() {
        _takenDoseCountsByDrug[drugKey] =
            (_takenDoseCountsByDrug[drugKey] ?? 0) + 1;
        _todayTakenDoseCountsByDrug[drugKey] =
            (_todayTakenDoseCountsByDrug[drugKey] ?? 0) + 1;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${drug.brandName} için doz kaydedildi'),
          backgroundColor: AppColors.success,
        ),
      );
      await _checkPrescriptionCompletion(drug);
      
      // Trigger streak check
      if (mounted) {
        final authState = context.read<AuthCubit>().state;
        if (authState is AuthAuthenticated) {
          context.read<StreakCubit>().checkAndUpdateStreak(
            authState.user,
            _activePrescriptions,
          );
        }
      }
    } on FirebaseException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Doz kaydedilemedi: ${e.message ?? e.code}'),
          backgroundColor: AppColors.error,
        ),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Doz kaydedilemedi. Lütfen tekrar deneyin.'),
          backgroundColor: AppColors.error,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isSavingTaken = false);
      }
    }
  }

  Future<void> _checkPrescriptionCompletion(DrugItemEntity takenDrug) async {
    final takenDrugKey = _drugKey(takenDrug);
    for (final prescription in _activePrescriptions) {
      if (!prescription.drugs.any((d) => _drugKey(d) == takenDrugKey)) continue;
      final allComplete = prescription.drugs.every((drug) {
        final total = _calculateDosesPerDay(drug.frequency) * drug.durationDays;
        final taken = _takenDoseCountsByDrug[_drugKey(drug)] ?? 0;
        return taken >= total;
      });
      if (allComplete) {
        try {
          await _firestore
              .collection(AppConstants.prescriptionsCollection)
              .doc(prescription.id)
              .update({'status': 'completed'});
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Tebrikler! Tedaviniz tamamlandı.'),
                backgroundColor: AppColors.success,
                duration: Duration(seconds: 4),
              ),
            );
          }
        } catch (_) {}
      }
      break;
    }
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

  ({IconData icon, IconData? detailIcon, Color color}) _medicineVisual(
    DrugItemEntity drug,
  ) {
    final source = '${drug.dosage} ${drug.brandName}'.toLowerCase();
    if (source.contains('tablet')) {
      return (
        icon: Icons.medication_outlined,
        detailIcon: Icons.circle_outlined,
        color: Colors.indigo,
      );
    }
    if (source.contains('kaps') || source.contains('capsule')) {
      return (
        icon: Icons.medication_liquid_outlined,
        detailIcon: Icons.adjust,
        color: Colors.teal,
      );
    }
    if (source.contains('şurup') ||
        source.contains('surup') ||
        source.contains('syrup')) {
      return (
        icon: Icons.local_drink_outlined,
        detailIcon: Icons.restaurant_outlined,
        color: Colors.deepOrange,
      );
    }
    if (source.contains('damla') || source.contains('drop')) {
      return (
        icon: Icons.opacity_outlined,
        detailIcon: Icons.water_drop_outlined,
        color: Colors.blue,
      );
    }
    if (source.contains('enjeks') || source.contains('inject')) {
      return (
        icon: Icons.vaccines_outlined,
        detailIcon: Icons.medical_services_outlined,
        color: Colors.redAccent,
      );
    }
    return (
      icon: Icons.medication,
      detailIcon: null,
      color: AppColors.primary,
    );
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (_) => getIt<PrescriptionCubit>()
            ..watchPatientPrescriptions(widget.patientId),
        ),
        BlocProvider(create: (_) => getIt<StreakCubit>()),
      ],
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
          body: BlocConsumer<PrescriptionCubit, PrescriptionState>(
            listener: (context, state) {
              if (state is PrescriptionListLoaded) {
                _activePrescriptions =
                    state.prescriptions.where((p) => p.isActive).toList();
              }
            },
            builder: (context, state) {
              if (state is PrescriptionLoading) {
                return const Center(child: CircularProgressIndicator());
              }
              if (state is PrescriptionListLoaded) {
                final activePrescriptions =
                    state.prescriptions.where((p) => p.isActive).toList();

                if (activePrescriptions.isEmpty) {
                  return const Center(
                    child: Text('Aktif reçeteniz bulunmuyor.'),
                  );
                }

                // Extract all active drugs
                final List<DrugItemEntity> allDrugs = [];
                final List<_ScheduledDrugEntry> scheduleEntries = [];
                for (var p in activePrescriptions) {
                  allDrugs.addAll(p.drugs);
                  for (final drug in p.drugs) {
                    scheduleEntries.add(
                      _ScheduledDrugEntry(
                        drug: drug,
                        prescriptionDate: DateTime(
                          p.createdAt.year,
                          p.createdAt.month,
                          p.createdAt.day,
                        ),
                      ),
                    );
                  }
                }

                return TabBarView(
                  children: [
                    _buildWeeklySchedule(scheduleEntries),
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

  Widget _buildWeeklySchedule(List<_ScheduledDrugEntry> entries) {
    final days = [
      'Pazartesi',
      'Salı',
      'Çarşamba',
      'Perşembe',
      'Cuma',
      'Cumartesi',
      'Pazar',
    ];
    final now = DateTime.now();
    final todayDate = DateTime(now.year, now.month, now.day);
    final mondayOfThisWeek = todayDate.subtract(Duration(days: now.weekday - 1));

    return ListView.builder(
      padding: EdgeInsets.all(16.w),
      itemCount: days.length + 1,
      itemBuilder: (context, index) {
        if (index == 0) {
          return _buildMedicineIconPreview();
        }

        final dayIndex = index - 1;
        final dayName = days[dayIndex];
        final dayDate = mondayOfThisWeek.add(Duration(days: dayIndex));
        final isToday = dayIndex == DateTime.now().weekday - 1;
        final dayEntries = entries.where((entry) {
          final drug = entry.drug;
          final startDate = entry.prescriptionDate;
          final endDate = startDate.add(Duration(days: drug.durationDays - 1));
          final isInTreatmentWindow =
              !dayDate.isBefore(startDate) && !dayDate.isAfter(endDate);

          final totalStock =
              _calculateDosesPerDay(drug.frequency) * drug.durationDays;
          final takenCount = _takenDoseCountsByDrug[_drugKey(drug)] ?? 0;
          final remaining = (totalStock - takenCount).clamp(0, totalStock);
          if (!isInTreatmentWindow) return false;

          // Keep today's/past entries visible as treatment history,
          // hide only future entries when stock is already exhausted.
          final isFutureDay = dayDate.isAfter(todayDate);
          if (isFutureDay && remaining <= 0) return false;
          return true;
        }).toList();

        return Container(
          margin: EdgeInsets.only(bottom: 8.h),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(12.r),
          ),
          child: ExpansionTile(
            shape: const Border(),
            collapsedShape: const Border(),
            title: Text(
              dayName,
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16.sp),
            ),
            initiallyExpanded:
                isToday, // Expand today by default for quick adherence action
            children: dayEntries.isEmpty
                ? [
                    Padding(
                      padding: EdgeInsets.fromLTRB(16.w, 0, 16.w, 16.h),
                      child: Text(
                        'Bu gün için planlı ilaç bulunmuyor.',
                        style: TextStyle(
                          fontSize: 12.sp,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                  ]
                : dayEntries.map((entry) {
              final drug = entry.drug;
              final visual = _medicineVisual(drug);
              final totalStock =
                  _calculateDosesPerDay(drug.frequency) * drug.durationDays;
              final takenCount = _takenDoseCountsByDrug[_drugKey(drug)] ?? 0;
              final todayTaken =
                  _todayTakenDoseCountsByDrug[_drugKey(drug)] ?? 0;
              final dailyLimit = _calculateDosesPerDay(drug.frequency);
              final dailyLimitReached = todayTaken >= dailyLimit;
              final remaining = (totalStock - takenCount).clamp(0, totalStock);
              return ListTile(
                leading: SizedBox(
                  width: 44.w,
                  height: 44.w,
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Container(
                        width: 40.w,
                        height: 40.w,
                        padding: EdgeInsets.all(8.w),
                        decoration: BoxDecoration(
                          color: visual.color.withAlpha(25),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(visual.icon, color: visual.color, size: 20.sp),
                      ),
                      if (visual.detailIcon != null)
                        Positioned(
                          right: -1.w,
                          bottom: -1.w,
                          child: Container(
                            width: 16.w,
                            height: 16.w,
                            decoration: const BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              visual.detailIcon,
                              size: 10.sp,
                              color: visual.color.withAlpha(210),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                title: Text(
                  drug.brandName,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                subtitle: Text(
                  'Kullanım: ${drug.frequency} • Bugün: $todayTaken/$dailyLimit • Kalan: $remaining',
                ),
                trailing: isToday
                    ? ElevatedButton(
                        onPressed: _isSavingTaken || dailyLimitReached
                            ? null
                            : () => _markDrugAsTaken(drug),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.successContainer,
                          foregroundColor: AppColors.success,
                          elevation: 0,
                        ),
                        child: Text(
                          dailyLimitReached ? 'Limit' : 'Aldım',
                          style: TextStyle(
                            fontSize: 12.sp,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      )
                    : null,
              );
            }).toList(),
          ),
        );
      },
    );
  }

  Widget _buildMedicineIconPreview() {
    Widget previewItem(String label, String dosage, String brand) {
      final visual = _medicineVisual(
        DrugItemEntity(
          brandName: brand,
          genericName: 'preview',
          atcCode: 'preview',
          barcode: '',
          dosage: dosage,
          frequency: 'Günde 1 kez',
          durationDays: 7,
        ),
      );

      return Column(
        children: [
          SizedBox(
            width: 44.w,
            height: 44.w,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  width: 40.w,
                  height: 40.w,
                  padding: EdgeInsets.all(8.w),
                  decoration: BoxDecoration(
                    color: visual.color.withAlpha(25),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(visual.icon, color: visual.color, size: 20.sp),
                ),
                if (visual.detailIcon != null)
                  Positioned(
                    right: -1.w,
                    bottom: -1.w,
                    child: Container(
                      width: 16.w,
                      height: 16.w,
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        visual.detailIcon,
                        size: 10.sp,
                        color: visual.color.withAlpha(210),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          SizedBox(height: 6.h),
          Text(
            label,
            style: TextStyle(
              fontSize: 11.sp,
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      );
    }

    return Container(
      margin: EdgeInsets.only(bottom: 12.h),
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: AppColors.divider),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          previewItem('Tablet', '1 tablet', 'PAROL TABLET'),
          previewItem('Kapsül', '1 kapsül', 'CAMZYOS KAPSÜL'),
          previewItem('Şurup', '5 ml şurup', 'ÖRNEK ŞURUP'),
        ],
      ),
    );
  }

  Widget _buildStocks(List<DrugItemEntity> drugs) {
    if (_isLoadingAdherence) {
      return const Center(child: CircularProgressIndicator());
    }

    return ListView.builder(
      padding: EdgeInsets.all(16.w),
      itemCount: drugs.length,
      itemBuilder: (context, index) {
        final drug = drugs[index];
        final dosesPerDay = _calculateDosesPerDay(drug.frequency);
        int totalStock = dosesPerDay * drug.durationDays;
        final takenCount = _takenDoseCountsByDrug[_drugKey(drug)] ?? 0;
        final remainingStock = (totalStock - takenCount).clamp(0, totalStock);

        return Card(
          margin: EdgeInsets.only(bottom: 12.h),
          child: ListTile(
            leading: const Icon(
              Icons.inventory_2_outlined,
              color: AppColors.primary,
              size: 32,
            ),
            title: Text(
              drug.brandName,
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16.sp),
            ),
            subtitle: Padding(
              padding: EdgeInsets.only(top: 8.h),
              child: Text('${drug.durationDays} günlük tedavi (${drug.frequency})'),
            ),
            trailing: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Kalan Stok:',
                  style: TextStyle(fontSize: 12.sp, color: Colors.grey[600]),
                ),
                SizedBox(height: 4.h),
                Text(
                  '$remainingStock doz',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                    fontSize: 16.sp,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _ScheduledDrugEntry {
  final DrugItemEntity drug;
  final DateTime prescriptionDate;

  const _ScheduledDrugEntry({
    required this.drug,
    required this.prescriptionDate,
  });
}
