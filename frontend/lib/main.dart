import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:meditrack/app.dart';
import 'package:meditrack/core/di/injection.dart';
import 'package:meditrack/core/services/notification_service.dart';
import 'firebase_options.dart';

void main() async {
  try {
    WidgetsFlutterBinding.ensureInitialized();
    debugPrint('Initializing Firebase...');
    await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
    
    debugPrint('Initializing Hive...');
    await Hive.initFlutter();
    
    debugPrint('Configuring dependencies...');
    await configureDependencies();
    
    debugPrint('Initializing Notification Service...');
    await NotificationService.instance.init();
    
    debugPrint('Starting App...');
    runApp(const MediTrackApp());
  } catch (e, stackTrace) {
    debugPrint('CRITICAL INITIALIZATION ERROR: $e');
    debugPrint(stackTrace.toString());
    // Optionally show a basic error app if needed
  }
}
