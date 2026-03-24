import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:meditrack/core/constants/app_constants.dart';
import 'package:meditrack/core/di/injection.dart';
import 'package:meditrack/core/router/route_names.dart';
import 'package:meditrack/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:meditrack/features/auth/presentation/cubit/auth_state.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  String _selectedRole = AppConstants.rolePatient;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _onRegisterPressed(BuildContext context) {
    if (_formKey.currentState?.validate() ?? false) {
      context.read<AuthCubit>().register(
            email: _emailController.text.trim(),
            password: _passwordController.text,
            name: _nameController.text.trim(),
            role: _selectedRole,
          );
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<AuthCubit>(),
      child: BlocConsumer<AuthCubit, AuthState>(
        listener: (context, state) {
          if (state is AuthAuthenticated) {
            if (state.user.isDoctor) {
              context.go(RouteNames.doctorDashboard);
            } else {
              context.go(RouteNames.patientDashboard);
            }
          } else if (state is AuthError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: Theme.of(context).colorScheme.error,
              ),
            );
          }
        },
        builder: (context, state) {
          return Scaffold(
            appBar: AppBar(
              title: const Text('Kayıt Ol'),
              centerTitle: true,
            ),
            body: SafeArea(
              child: SingleChildScrollView(
                padding: EdgeInsets.symmetric(horizontal: 24.w),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      SizedBox(height: 24.h),
                      _buildNameField(),
                      SizedBox(height: 16.h),
                      _buildEmailField(),
                      SizedBox(height: 16.h),
                      _buildPasswordField(),
                      SizedBox(height: 24.h),
                      _buildRoleSelector(context),
                      SizedBox(height: 32.h),
                      _buildRegisterButton(context, state),
                      SizedBox(height: 16.h),
                      _buildLoginLink(context),
                      SizedBox(height: 24.h),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildNameField() {
    return TextFormField(
      controller: _nameController,
      keyboardType: TextInputType.name,
      textInputAction: TextInputAction.next,
      textCapitalization: TextCapitalization.words,
      decoration: const InputDecoration(
        labelText: 'Ad Soyad',
        hintText: 'Adınız Soyadınız',
        prefixIcon: Icon(Icons.person_outline),
        border: OutlineInputBorder(),
      ),
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return 'Ad soyad gerekli';
        }
        if (value.trim().length < 3) {
          return 'Ad soyad en az 3 karakter olmalı';
        }
        return null;
      },
    );
  }

  Widget _buildEmailField() {
    return TextFormField(
      controller: _emailController,
      keyboardType: TextInputType.emailAddress,
      textInputAction: TextInputAction.next,
      decoration: const InputDecoration(
        labelText: 'E-posta',
        hintText: 'ornek@email.com',
        prefixIcon: Icon(Icons.email_outlined),
        border: OutlineInputBorder(),
      ),
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return 'E-posta gerekli';
        }
        if (!value.contains('@')) {
          return 'Geçerli bir e-posta girin';
        }
        return null;
      },
    );
  }

  Widget _buildPasswordField() {
    return TextFormField(
      controller: _passwordController,
      obscureText: _obscurePassword,
      textInputAction: TextInputAction.done,
      decoration: InputDecoration(
        labelText: 'Şifre',
        hintText: '••••••••',
        prefixIcon: const Icon(Icons.lock_outline),
        border: const OutlineInputBorder(),
        helperText: 'En az 6 karakter',
        suffixIcon: IconButton(
          icon: Icon(
            _obscurePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined,
          ),
          onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
        ),
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Şifre gerekli';
        }
        if (value.length < 6) {
          return 'Şifre en az 6 karakter olmalı';
        }
        return null;
      },
    );
  }

  Widget _buildRoleSelector(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Rolünüz',
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
        ),
        SizedBox(height: 12.h),
        SegmentedButton<String>(
          segments: const [
            ButtonSegment(
              value: AppConstants.rolePatient,
              label: Text('Hasta'),
              icon: Icon(Icons.person),
            ),
            ButtonSegment(
              value: AppConstants.roleDoctor,
              label: Text('Doktor'),
              icon: Icon(Icons.local_hospital_outlined),
            ),
          ],
          selected: {_selectedRole},
          onSelectionChanged: (value) {
            setState(() => _selectedRole = value.first);
          },
          style: ButtonStyle(
            minimumSize: WidgetStateProperty.all(
              Size(double.infinity, 48.h),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRegisterButton(BuildContext context, AuthState state) {
    final isLoading = state is AuthLoading;
    return FilledButton(
      onPressed: isLoading ? null : () => _onRegisterPressed(context),
      style: FilledButton.styleFrom(
        minimumSize: Size(double.infinity, 52.h),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12.r),
        ),
      ),
      child: isLoading
          ? SizedBox(
              width: 20.w,
              height: 20.h,
              child: const CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.white,
              ),
            )
          : Text(
              'Kayıt Ol',
              style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.w600),
            ),
    );
  }

  Widget _buildLoginLink(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          'Zaten hesabınız var mı?',
          style: TextStyle(
            fontSize: 14.sp,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
        TextButton(
          onPressed: () => context.pop(),
          child: Text(
            'Giriş Yapın',
            style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w600),
          ),
        ),
      ],
    );
  }
}
