import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:meditrack/core/theme/app_colors.dart';
import 'package:meditrack/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:meditrack/features/auth/presentation/cubit/auth_state.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  late TextEditingController _nameController;
  bool _isEditing = false;

  @override
  void initState() {
    super.initState();
    _updateController();
  }

  void _updateController() {
    final authState = context.read<AuthCubit>().state;
    if (authState is AuthAuthenticated) {
      _nameController = TextEditingController(text: authState.user.name);
    } else {
      _nameController = TextEditingController();
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthCubit, AuthState>(
      listener: (context, state) {
        if (state is AuthAuthenticated) {
          setState(() {
            _isEditing = false;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Profil başarıyla güncellendi')),
          );
        } else if (state is AuthError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text(state.message), backgroundColor: AppColors.error),
          );
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Profilim'),
          actions: [
            if (!_isEditing)
              IconButton(
                icon: const Icon(Icons.edit_outlined),
                onPressed: () => setState(() => _isEditing = true),
              ),
          ],
        ),
        body: BlocBuilder<AuthCubit, AuthState>(
          builder: (context, state) {
            final user = state is AuthAuthenticated ? state.user : null;
            if (user == null) return const Center(child: CircularProgressIndicator());

            return SingleChildScrollView(
              padding: EdgeInsets.all(24.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  CircleAvatar(
                    radius: 50.r,
                    backgroundColor: AppColors.primaryContainer,
                    child:
                        Icon(Icons.person, size: 50.r, color: AppColors.primary),
                  ),
                  SizedBox(height: 32.h),
                  if (!_isEditing) ...[
                    Text(
                      user.name,
                      style: TextStyle(
                        fontSize: 24.sp,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    SizedBox(height: 8.h),
                    Text(
                      user.email,
                      style: TextStyle(
                        fontSize: 16.sp,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    SizedBox(height: 12.h),
                    Container(
                      padding:
                          EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
                      decoration: BoxDecoration(
                        color: AppColors.primaryLight,
                        borderRadius: BorderRadius.circular(20.r),
                      ),
                      child: Text(
                        user.isDoctor ? 'Doktor' : 'Hasta',
                        style: TextStyle(
                          fontSize: 12.sp,
                          color: AppColors.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    SizedBox(height: 48.h),
                    SizedBox(
                      width: double.infinity,
                      height: 50.h,
                      child: OutlinedButton.icon(
                        onPressed: () => setState(() => _isEditing = true),
                        icon: const Icon(Icons.edit),
                        label: const Text('Profil Bilgilerini Değiştir'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.primary,
                          side: const BorderSide(color: AppColors.primary),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12.r),
                          ),
                        ),
                      ),
                    ),
                  ] else ...[
                    TextField(
                      controller: _nameController,
                      decoration: InputDecoration(
                        labelText: 'İsim Soyisim',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12.r),
                        ),
                        prefixIcon: const Icon(Icons.person_outline),
                      ),
                    ),
                    SizedBox(height: 24.h),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () {
                              setState(() {
                                _isEditing = false;
                                _updateController();
                              });
                            },
                            style: OutlinedButton.styleFrom(
                              minimumSize: Size(double.infinity, 50.h),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12.r),
                              ),
                            ),
                            child: const Text('İptal'),
                          ),
                        ),
                        SizedBox(width: 16.w),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () {
                              final newName = _nameController.text.trim();
                              if (newName.isNotEmpty) {
                                context.read<AuthCubit>().updateName(newName);
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              minimumSize: Size(double.infinity, 50.h),
                              backgroundColor: AppColors.primary,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12.r),
                              ),
                            ),
                            child: const Text('Kaydet'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
