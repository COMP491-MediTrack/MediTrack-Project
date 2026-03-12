import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:meditrack/app.dart';
import 'package:meditrack/core/di/injection.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  setupDependencies();
  runApp(const MediTrackApp());
}
