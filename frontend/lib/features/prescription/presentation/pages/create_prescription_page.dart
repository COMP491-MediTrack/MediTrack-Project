import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:meditrack/core/di/injection.dart';
import 'package:meditrack/core/theme/app_colors.dart';
import 'package:meditrack/features/auth/domain/entities/user_entity.dart';
import 'package:meditrack/features/prescription/domain/entities/ddi_result_entity.dart';
import 'package:meditrack/features/prescription/domain/entities/drug_item_entity.dart';
import 'package:meditrack/features/prescription/presentation/cubit/prescription_cubit.dart';
import 'package:meditrack/features/prescription/presentation/cubit/prescription_state.dart';
import 'package:meditrack/features/prescription/presentation/widgets/drug_search_sheet.dart';

class CreatePrescriptionPage extends StatefulWidget {
  final UserEntity patient;
  final String doctorName;
  final PrescriptionCubit? sharedCubit;

  const CreatePrescriptionPage({
    super.key,
    required this.patient,
    required this.doctorName,
    this.sharedCubit,
  });

  @override
  State<CreatePrescriptionPage> createState() => _CreatePrescriptionPageState();
}

class _CreatePrescriptionPageState extends State<CreatePrescriptionPage> {
  final List<DrugItemEntity> _selectedDrugs = [];

  void _onDrugAdded(DrugItemEntity drug) {
    setState(() => _selectedDrugs.add(drug));
  }

  void _onDrugRemoved(int index) {
    setState(() => _selectedDrugs.removeAt(index));
  }

  Future<void> _onSavePressed(BuildContext context) async {
    if (_selectedDrugs.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('En az bir ilaç ekleyin')),
      );
      return;
    }

    final genericNames = _selectedDrugs.map((d) => d.genericName).toList();

    if (genericNames.length >= 2) {
      await context.read<PrescriptionCubit>().checkDdi(genericNames);
    } else {
      _savePrescription(context);
    }
  }

  void _savePrescription(BuildContext context, {List<DdiInteractionEntity> interactions = const []}) {
    context.read<PrescriptionCubit>().createPrescription(
          patientId: widget.patient.uid,
          patientName: widget.patient.name,
          doctorName: widget.doctorName,
          drugs: _selectedDrugs,
          interactions: interactions,
        );
  }

  Widget _buildContent(BuildContext context) {
    return BlocConsumer<PrescriptionCubit, PrescriptionState>(
        listener: (context, state) {
          if (state is DdiLoaded) {
            if (state.result.hasInteractions) {
              _showDdiWarningDialog(
                context,
                state,
                (enrichedInteractions) => _savePrescription(context, interactions: enrichedInteractions),
              );
            } else {
              _savePrescription(context);
            }
          } else if (state is PrescriptionCreated) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Reçete başarıyla oluşturuldu'),
                backgroundColor: AppColors.success,
              ),
            );
            context.pop();
          } else if (state is PrescriptionError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: AppColors.error,
              ),
            );
          }
        },
        builder: (context, state) {
          final isLoading = state is PrescriptionLoading || state is DdiChecking;
          return Scaffold(
            appBar: AppBar(
              title: const Text('Yeni Reçete'),
              centerTitle: true,
            ),
            body: Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    padding: EdgeInsets.all(16.w),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildPatientCard(),
                        SizedBox(height: 20.h),
                        _buildDrugListHeader(context),
                        SizedBox(height: 12.h),
                        if (_selectedDrugs.isEmpty)
                          _buildEmptyDrugState()
                        else
                          ..._selectedDrugs.asMap().entries.map(
                                (entry) => _buildDrugCard(entry.key, entry.value),
                              ),
                      ],
                    ),
                  ),
                ),
                _buildBottomBar(context, isLoading),
              ],
            ),
          );
        },
      );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.sharedCubit != null) {
      return BlocProvider.value(
        value: widget.sharedCubit!,
        child: _buildContent(context),
      );
    }
    return BlocProvider(
      create: (_) => getIt<PrescriptionCubit>(),
      child: _buildContent(context),
    );
  }

  Widget _buildPatientCard() {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: AppColors.primaryContainer,
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 24.r,
            backgroundColor: AppColors.primary,
            child: Text(
              widget.patient.name[0].toUpperCase(),
              style: TextStyle(color: Colors.white, fontSize: 18.sp, fontWeight: FontWeight.bold),
            ),
          ),
          SizedBox(width: 12.w),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Hasta',
                style: TextStyle(fontSize: 12.sp, color: AppColors.textSecondary),
              ),
              Text(
                widget.patient.name,
                style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDrugListHeader(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          'İlaçlar',
          style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.w600),
        ),
        TextButton.icon(
          onPressed: () => _showDrugSearchSheet(context),
          icon: const Icon(Icons.add),
          label: const Text('İlaç Ekle'),
        ),
      ],
    );
  }

  Widget _buildEmptyDrugState() {
    return Container(
      height: 120.h,
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.divider),
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: Center(
        child: Text(
          'Henüz ilaç eklenmedi',
          style: TextStyle(color: AppColors.textSecondary, fontSize: 14.sp),
        ),
      ),
    );
  }

  Widget _buildDrugCard(int index, DrugItemEntity drug) {
    return Container(
      margin: EdgeInsets.only(bottom: 8.h),
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.divider),
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  drug.brandName,
                  style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w600),
                ),
                SizedBox(height: 4.h),
                Text(
                  '${drug.dosage} • ${drug.frequency} • ${drug.durationDays} gün',
                  style: TextStyle(fontSize: 12.sp, color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline, color: AppColors.error),
            onPressed: () => _onDrugRemoved(index),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomBar(BuildContext context, bool isLoading) {
    return Container(
      padding: EdgeInsets.fromLTRB(16.w, 12.h, 16.w, 24.h),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: AppColors.divider)),
      ),
      child: FilledButton(
        onPressed: isLoading ? null : () => _onSavePressed(context),
        child: isLoading
            ? SizedBox(
                width: 20.w,
                height: 20.h,
                child: const CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
              )
            : Text(
                'Reçeteyi Kaydet',
                style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.w600),
              ),
      ),
    );
  }

  void _showDrugSearchSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => BlocProvider.value(
        value: context.read<PrescriptionCubit>(),
        child: DrugSearchSheet(onDrugAdded: _onDrugAdded),
      ),
    );
  }

  void _showDdiWarningDialog(
    BuildContext context,
    DdiLoaded state,
    void Function(List<DdiInteractionEntity> interactions) onConfirm,
  ) {
    final cubit = context.read<PrescriptionCubit>();
    final explanations = <int, String>{};
    final expandedIndices = <int>{};

    showDialog(
      context: context,
      builder: (dialogContext) => BlocProvider.value(
        value: cubit,
        child: StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Row(
                children: [
                  Icon(Icons.warning_amber_rounded, color: AppColors.warning, size: 24.sp),
                  SizedBox(width: 8.w),
                  const Text('İlaç Etkileşimi Uyarısı'),
                ],
              ),
              content: SizedBox(
                width: double.maxFinite,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${state.result.interactions.length} etkileşim tespit edildi:',
                        style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w600),
                      ),
                      SizedBox(height: 8.h),
                      ...state.result.interactions.asMap().entries.map(
                        (entry) {
                          final i = entry.value;
                          final index = entry.key;
                          final isExpanded = expandedIndices.contains(index);
                          final hasExplanation = explanations.containsKey(index);

                          return Padding(
                            padding: EdgeInsets.only(bottom: 12.h),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '• ${i.drug1} + ${i.drug2}: ${i.description}',
                                  style: TextStyle(fontSize: 13.sp),
                                ),
                                InkWell(
                                  onTap: () {
                                    if (!hasExplanation) {
                                      cubit.explainDdi(index, i.drug1, i.drug2, i.description);
                                    } else {
                                      setState(() {
                                        if (isExpanded) {
                                          expandedIndices.remove(index);
                                        } else {
                                          expandedIndices.add(index);
                                        }
                                      });
                                    }
                                  },
                                  borderRadius: BorderRadius.circular(4.r),
                                  child: Padding(
                                    padding: EdgeInsets.symmetric(vertical: 4.h, horizontal: 4.w),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          Icons.auto_awesome,
                                          size: 14.sp,
                                          color: AppColors.primary,
                                        ),
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
                                          isExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                                          size: 14.sp,
                                          color: AppColors.primary,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                BlocConsumer<PrescriptionCubit, PrescriptionState>(
                                  listener: (context, state) {
                                    if (state is DdiExplanationLoaded && state.interactionIndex == index) {
                                      setState(() {
                                        explanations[index] = state.explanation;
                                        expandedIndices.add(index);
                                      });
                                    }
                                  },
                                  builder: (context, state) {
                                    if (state is DdiExplaining && state.interactionIndex == index) {
                                      return Padding(
                                        padding: EdgeInsets.only(left: 12.w, top: 4.h),
                                        child: SizedBox(
                                          height: 2.h,
                                          width: 100.w,
                                          child: const LinearProgressIndicator(),
                                        ),
                                      );
                                    }

                                    if (hasExplanation && isExpanded) {
                                      return Container(
                                        margin: EdgeInsets.only(left: 12.w, top: 8.h),
                                        padding: EdgeInsets.all(8.w),
                                        decoration: BoxDecoration(
                                          color: AppColors.primaryContainer.withOpacity(0.5),
                                          borderRadius: BorderRadius.circular(8.r),
                                        ),
                                        child: Text(
                                          explanations[index]!,
                                          style: TextStyle(fontSize: 12.sp, fontStyle: FontStyle.italic),
                                        ),
                                      );
                                    }
                                    return const SizedBox.shrink();
                                  },
                                  buildWhen: (previous, current) =>
                                      (current is DdiExplaining && current.interactionIndex == index) ||
                                      (current is DdiExplanationLoaded && current.interactionIndex == index),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                      SizedBox(height: 8.h),
                      Text(
                        'Yine de reçeteyi kaydetmek istiyor musunuz?',
                        style: TextStyle(fontSize: 14.sp, color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: const Text('İptal'),
                ),
                FilledButton(
                  onPressed: () {
                    Navigator.pop(dialogContext);
                    final enriched = state.result.interactions
                        .asMap()
                        .entries
                        .map((e) => DdiInteractionEntity(
                              drug1: e.value.drug1,
                              drug2: e.value.drug2,
                              description: e.value.description,
                              aiExplanation: explanations[e.key],
                            ))
                        .toList();
                    onConfirm(enriched);
                  },
                  style: FilledButton.styleFrom(backgroundColor: AppColors.warning),
                  child: const Text('Yine de Kaydet'),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
