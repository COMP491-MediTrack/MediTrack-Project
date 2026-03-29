import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:meditrack/core/theme/app_colors.dart';
import 'package:meditrack/features/prescription/domain/entities/drug_item_entity.dart';
import 'package:meditrack/features/prescription/domain/entities/drug_search_result_entity.dart';
import 'package:meditrack/features/prescription/presentation/cubit/prescription_cubit.dart';
import 'package:meditrack/features/prescription/presentation/cubit/prescription_state.dart';

class DrugSearchSheet extends StatefulWidget {
  final Function(DrugItemEntity) onDrugAdded;

  const DrugSearchSheet({super.key, required this.onDrugAdded});

  @override
  State<DrugSearchSheet> createState() => _DrugSearchSheetState();
}

class _DrugSearchSheetState extends State<DrugSearchSheet> {
  final _searchController = TextEditingController();
  DrugSearchResultEntity? _selectedDrug;

  final _dosageController = TextEditingController();
  String _selectedFrequency = 'Günde 1 kez';
  int _durationDays = 7;

  final _frequencies = [
    'Günde 1 kez',
    'Günde 2 kez',
    'Günde 3 kez',
    'Günde 4 kez',
    'Haftada 1 kez',
    'Gerektiğinde',
  ];

  @override
  void dispose() {
    _searchController.dispose();
    _dosageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
      ),
      child: Column(
        children: [
          _buildHandle(),
          _buildHeader(),
          Expanded(
            child: _selectedDrug == null
                ? _buildSearchView()
                : _buildDosageView(),
          ),
        ],
      ),
    );
  }

  Widget _buildHandle() {
    return Container(
      margin: EdgeInsets.only(top: 12.h),
      width: 40.w,
      height: 4.h,
      decoration: BoxDecoration(
        color: AppColors.divider,
        borderRadius: BorderRadius.circular(2.r),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 8.h),
      child: Row(
        children: [
          if (_selectedDrug != null)
            IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () => setState(() => _selectedDrug = null),
            ),
          Text(
            _selectedDrug == null ? 'İlaç Ara' : 'Doz Bilgisi',
            style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchView() {
    return Column(
      children: [
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 16.w),
          child: TextField(
            controller: _searchController,
            autofocus: true,
            decoration: const InputDecoration(
              prefixIcon: Icon(Icons.search),
              hintText: 'İlaç adı girin (örn: Majezik)',
            ),
            onChanged: (value) {
              if (value.length >= 2) {
                context.read<PrescriptionCubit>().searchDrugs(value);
              }
            },
          ),
        ),
        SizedBox(height: 8.h),
        Expanded(
          child: BlocBuilder<PrescriptionCubit, PrescriptionState>(
            builder: (context, state) {
              if (state is DrugSearchLoading) {
                return const Center(child: CircularProgressIndicator());
              }
              if (state is DrugSearchLoaded) {
                if (state.results.isEmpty) {
                  return Center(
                    child: Text(
                      'Sonuç bulunamadı',
                      style: TextStyle(color: AppColors.textSecondary, fontSize: 14.sp),
                    ),
                  );
                }
                return ListView.separated(
                  padding: EdgeInsets.symmetric(horizontal: 16.w),
                  itemCount: state.results.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (_, index) {
                    final drug = state.results[index];
                    return ListTile(
                      title: Text(
                        drug.brandName,
                        style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w500),
                      ),
                      subtitle: Text(
                        drug.genericName,
                        style: TextStyle(fontSize: 12.sp, color: AppColors.textSecondary),
                      ),
                      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                      onTap: () => setState(() => _selectedDrug = drug),
                    );
                  },
                );
              }
              return Center(
                child: Text(
                  'İlaç aramak için yazmaya başlayın',
                  style: TextStyle(color: AppColors.textSecondary, fontSize: 14.sp),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildDosageView() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(16.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: EdgeInsets.all(12.w),
            decoration: BoxDecoration(
              color: AppColors.primaryContainer,
              borderRadius: BorderRadius.circular(12.r),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _selectedDrug!.brandName,
                  style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                ),
                Text(
                  _selectedDrug!.genericName,
                  style: TextStyle(fontSize: 13.sp, color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
          SizedBox(height: 20.h),
          Text('Doz', style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w600)),
          SizedBox(height: 8.h),
          TextField(
            controller: _dosageController,
            decoration: const InputDecoration(hintText: 'örn: 400mg, 1 tablet'),
          ),
          SizedBox(height: 16.h),
          Text('Kullanım Sıklığı', style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w600)),
          SizedBox(height: 8.h),
          DropdownButtonFormField<String>(
            value: _selectedFrequency,
            items: _frequencies
                .map((f) => DropdownMenuItem(value: f, child: Text(f)))
                .toList(),
            onChanged: (v) => setState(() => _selectedFrequency = v!),
            decoration: const InputDecoration(),
          ),
          SizedBox(height: 16.h),
          Text('Kullanım Süresi (Gün)', style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w600)),
          SizedBox(height: 8.h),
          Row(
            children: [
              IconButton(
                onPressed: () {
                  if (_durationDays > 1) setState(() => _durationDays--);
                },
                icon: const Icon(Icons.remove_circle_outline),
              ),
              SizedBox(width: 16.w),
              Text(
                '$_durationDays gün',
                style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.w600),
              ),
              SizedBox(width: 16.w),
              IconButton(
                onPressed: () => setState(() => _durationDays++),
                icon: const Icon(Icons.add_circle_outline),
              ),
            ],
          ),
          SizedBox(height: 32.h),
          FilledButton(
            onPressed: _onAddDrug,
            child: Text(
              'Reçeteye Ekle',
              style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  void _onAddDrug() {
    if (_dosageController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Doz bilgisi girin')),
      );
      return;
    }
    final drug = DrugItemEntity(
      brandName: _selectedDrug!.brandName,
      genericName: _selectedDrug!.genericName,
      atcCode: _selectedDrug!.atcCode,
      barcode: _selectedDrug!.barcode,
      dosage: _dosageController.text.trim(),
      frequency: _selectedFrequency,
      durationDays: _durationDays,
    );
    widget.onDrugAdded(drug);
    Navigator.pop(context);
  }
}
