import 'package:flutter/material.dart';
import 'package:meditrack/core/router/app_router.dart';
import 'package:meditrack/core/theme/app_theme.dart';

class MediTrackApp extends StatelessWidget {
  const MediTrackApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'MediTrack',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      routerConfig: AppRouter.router,
    );
  }
}
