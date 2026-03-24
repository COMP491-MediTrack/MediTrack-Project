class AppConstants {
  static const String appName = 'MediTrack';

  // FastAPI backend URL
  static const String apiBaseUrl = 'http://localhost:8000/api/v1';

  // Firestore collections
  static const String usersCollection = 'users';
  static const String prescriptionsCollection = 'prescriptions';
  static const String remindersCollection = 'reminders';
  static const String labResultsCollection = 'lab_results';

  // User roles
  static const String roleDoctor = 'doctor';
  static const String rolePatient = 'patient';
}
