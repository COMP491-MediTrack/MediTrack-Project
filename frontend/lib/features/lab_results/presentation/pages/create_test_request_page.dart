import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:meditrack/core/theme/app_colors.dart';
import 'package:meditrack/core/di/injection.dart';
import 'package:meditrack/features/auth/domain/entities/user_entity.dart';
import 'package:meditrack/features/lab_results/presentation/cubit/test_request_cubit.dart';
import 'package:meditrack/features/lab_results/presentation/cubit/test_request_state.dart';

class CreateTestRequestPage extends StatefulWidget {
  final UserEntity patient;
  final String doctorId;
  final String doctorName;

  const CreateTestRequestPage({
    super.key,
    required this.patient,
    required this.doctorId,
    required this.doctorName,
  });

  @override
  State<CreateTestRequestPage> createState() => _CreateTestRequestPageState();
}

class _CreateTestRequestPageState extends State<CreateTestRequestPage> {
  final List<String> _availableTests = [
    'Kan Tahlili',
    'İdrar Tahlili',
    'Gaita Tahlili',
    'MR',
    'Röntgen',
    'Ultrason',
    'EKG',
    'BT (Bilgisayarlı Tomografi)',
  ];

  final Set<String> _selectedTests = {};

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<TestRequestCubit>(),
      child: BlocConsumer<TestRequestCubit, TestRequestState>(
        listener: (context, state) {
          if (state is TestRequestCreated) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Tahlil isteği başarıyla oluşturuldu'),
                backgroundColor: AppColors.success,
              ),
            );
            context.pop();
          } else if (state is TestRequestError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: AppColors.error,
              ),
            );
          }
        },
        builder: (context, state) {
          return Scaffold(
            backgroundColor: AppColors.background,
            appBar: AppBar(
              title: const Text('Yeni İstek Formu'),
              centerTitle: true,
            ),
            body: SafeArea(
              child: state is TestRequestLoading
                  ? const Center(child: CircularProgressIndicator())
                  : SingleChildScrollView(
                      padding: EdgeInsets.all(20.w),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildPatientInfoCard(),
                          SizedBox(height: 24.h),
                          Text(
                            'İstenen Tahliller',
                            style: TextStyle(
                              fontSize: 18.sp,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          SizedBox(height: 8.h),
                          Text(
                            'Hastadan istenen tahlilleri aşağıdan seçiniz.',
                            style: TextStyle(
                              fontSize: 14.sp,
                              color: AppColors.textSecondary,
                            ),
                          ),
                          SizedBox(height: 16.h),
                          ..._availableTests.map((test) => _buildTestCheckbox(test)),
                          SizedBox(height: 32.h),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: _selectedTests.isEmpty
                                  ? null
                                  : () {
                                      final id = DateTime.now().millisecondsSinceEpoch.toString();
                                      context.read<TestRequestCubit>().createTestRequest(
                                            testRequestId: id,
                                            patientId: widget.patient.uid,
                                            patientName: widget.patient.name,
                                            doctorId: widget.doctorId,
                                            doctorName: widget.doctorName,
                                            requestedTests: _selectedTests.toList(),
                                          );
                                    },
                              style: ElevatedButton.styleFrom(
                                padding: EdgeInsets.symmetric(vertical: 16.h),
                                backgroundColor: AppColors.primary,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12.r),
                                ),
                              ),
                              child: Text(
                                'İstek Formu Oluştur',
                                style: TextStyle(
                                  fontSize: 16.sp,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildPatientInfoCard() {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: AppColors.divider),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 20.r,
            backgroundColor: AppColors.primaryLight,
            child: Text(
              widget.patient.name.isNotEmpty ? widget.patient.name[0].toUpperCase() : '?',
              style: TextStyle(
                color: AppColors.primary,
                fontWeight: FontWeight.bold,
                fontSize: 16.sp,
              ),
            ),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Hasta: ${widget.patient.name}',
                  style: TextStyle(
                    fontSize: 15.sp,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                SizedBox(height: 4.h),
                Text(
                  widget.patient.email,
                  style: TextStyle(
                    fontSize: 13.sp,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTestCheckbox(String testName) {
    return CheckboxListTile(
      title: Text(
        testName,
        style: TextStyle(
          fontSize: 15.sp,
          fontWeight: _selectedTests.contains(testName) ? FontWeight.bold : FontWeight.normal,
        ),
      ),
      value: _selectedTests.contains(testName),
      activeColor: AppColors.primary,
      contentPadding: EdgeInsets.zero,
      controlAffinity: ListTileControlAffinity.leading,
      onChanged: (bool? value) {
        setState(() {
          if (value == true) {
            _selectedTests.add(testName);
          } else {
            _selectedTests.remove(testName);
          }
        });
      },
    );
  }
}
