import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:meditrack/core/router/route_names.dart';
import 'package:meditrack/features/auth/domain/entities/user_entity.dart';
import 'package:meditrack/features/auth/presentation/pages/login_page.dart';
import 'package:meditrack/features/auth/presentation/pages/register_page.dart';
import 'package:meditrack/features/dashboard/presentation/pages/doctor_dashboard_page.dart';
import 'package:meditrack/features/dashboard/presentation/pages/patient_dashboard_page.dart';
import 'package:meditrack/features/prescription/domain/entities/prescription_entity.dart';
import 'package:meditrack/features/prescription/presentation/pages/create_prescription_page.dart';
import 'package:meditrack/features/prescription/presentation/pages/prescription_detail_page.dart';
import 'package:meditrack/features/prescription/presentation/pages/prescription_list_page.dart';
import 'package:meditrack/features/lab_results/presentation/pages/lab_results_page.dart';
import 'package:meditrack/features/lab_results/presentation/pages/create_test_request_page.dart';
import 'package:meditrack/features/pharmacy/presentation/pages/pharmacy_map_page.dart';

class _AuthStreamNotifier extends ChangeNotifier {
  late final StreamSubscription<User?> _subscription;

  _AuthStreamNotifier() {
    _subscription = FirebaseAuth.instance.authStateChanges().listen((_) {
      notifyListeners();
    });
  }

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}

class AppRouter {
  static final _authNotifier = _AuthStreamNotifier();

  static final router = GoRouter(
    initialLocation: RouteNames.login,
    refreshListenable: _authNotifier,
    redirect: (context, state) {
      final isLoggedIn = FirebaseAuth.instance.currentUser != null;
      final location = state.matchedLocation;
      final isAuthRoute =
          location == RouteNames.login || location == RouteNames.register;

      if (!isLoggedIn && !isAuthRoute) return RouteNames.login;
      return null;
    },
    routes: [
      GoRoute(
        path: RouteNames.login,
        builder: (context, state) => const LoginPage(),
      ),
      GoRoute(
        path: RouteNames.register,
        builder: (context, state) => const RegisterPage(),
      ),
      GoRoute(
        path: RouteNames.doctorDashboard,
        builder: (context, state) => const DoctorDashboardPage(),
      ),
      GoRoute(
        path: RouteNames.patientDashboard,
        builder: (context, state) => const PatientDashboardPage(),
      ),
      GoRoute(
        path: RouteNames.createPrescription,
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>;
          return CreatePrescriptionPage(
            patient: extra['patient'] as UserEntity,
            doctorName: extra['doctorName'] as String,
          );
        },
      ),
      GoRoute(
        path: RouteNames.prescriptionList,
        builder: (context, state) {
          final extra = state.extra;
          if (extra is Map<String, dynamic>) {
            return PrescriptionListPage(
              patientId: extra['patientId'] as String,
              patientName: extra['patientName'] as String?,
              doctorExtra: extra['doctorExtra'] as Map<String, dynamic>?,
            );
          }
          return PrescriptionListPage(patientId: extra as String);
        },
      ),
      GoRoute(
        path: RouteNames.prescriptionDetail,
        builder: (context, state) {
          final prescription = state.extra as PrescriptionEntity;
          return PrescriptionDetailPage(prescription: prescription);
        },
      ),
      GoRoute(
        path: RouteNames.pharmacy,
        builder: (context, state) => const PharmacyMapPage(),
      ),
      GoRoute(
        path: RouteNames.labResults,
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>?;
          return LabResultsPage(
            patientId: extra?['patientId'] as String?,
            patientName: extra?['patientName'] as String?,
            isDoctor: extra?['isDoctor'] as bool? ?? false,
          );
        },
      ),
      GoRoute(
        path: RouteNames.createTestRequest,
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>;
          return CreateTestRequestPage(
            patient: extra['patient'] as UserEntity,
            doctorId: extra['doctorId'] as String,
            doctorName: extra['doctorName'] as String,
          );
        },
      ),
    ],
  );
}
