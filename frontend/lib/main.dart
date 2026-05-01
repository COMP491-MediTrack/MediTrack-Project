import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:meditrack/app.dart';
import 'package:meditrack/core/di/injection.dart';
import 'package:meditrack/core/services/notification_service.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await Hive.initFlutter();
  await configureDependencies();
  await NotificationService.instance.init();
  runApp(const MediTrackApp());
}
