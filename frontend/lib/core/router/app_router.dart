import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:meditrack/core/router/route_names.dart';
import 'package:meditrack/features/auth/presentation/pages/login_page.dart';
import 'package:meditrack/features/auth/presentation/pages/register_page.dart';
import 'package:meditrack/features/dashboard/presentation/pages/doctor_dashboard_page.dart';
import 'package:meditrack/features/dashboard/presentation/pages/patient_dashboard_page.dart';

/// GoRouter'ı Firebase auth state değişikliklerinde yenileyen notifier.
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

      // Giriş yapmamış kullanıcı korumalı sayfaya gitmeye çalışıyor
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
    ],
  );
}
