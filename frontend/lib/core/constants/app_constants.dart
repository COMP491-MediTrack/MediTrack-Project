class AppConstants {
  static const String appName = 'MediTrack';

  // FastAPI backend URL
  // Geliştirme: backend çalıştıran kişinin IP'sini gir (aynı WiFi olmalı)
  // Örn: http://192.168.1.45:8000/api/v1
  // Simülatörde localhost çalışır, fiziksel cihazda IP gerekir
  static const String apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://localhost:8000/api/v1',
  );

  // Firestore collections
  static const String usersCollection = 'users';
  static const String prescriptionsCollection = 'prescriptions';
  static const String remindersCollection = 'reminders';
  static const String labResultsCollection = 'lab_results';

  // User roles
  static const String roleDoctor = 'doctor';
  static const String rolePatient = 'patient';
}
