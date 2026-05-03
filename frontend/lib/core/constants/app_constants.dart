class AppConstants {
  static const String appName = 'MediTrack';

  // FastAPI backend URL
  // Production backend deployed on Render.
  // Local testing can override this with:
  // flutter run --dart-define=API_BASE_URL=http://127.0.0.1:8000/api/v1
  static const String apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://meditrack-project-6io1.onrender.com/api/v1',
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
