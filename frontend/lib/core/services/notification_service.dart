
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

class NotificationService {
  static final NotificationService instance = NotificationService._();
  NotificationService._();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  bool _initialized = false;

  Future<void> init() async {
    if (_initialized) return;
    

    tz.initializeTimeZones();

    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const darwinSettings = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: darwinSettings,
      macOS: darwinSettings,
    );

    await _plugin.initialize(initSettings);
    _initialized = true;
  }

  Future<bool> requestPermissions() async {
    

    final android = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    if (android != null) {
      return await android.requestNotificationsPermission() ?? false;
    }

    final ios = _plugin.resolvePlatformSpecificImplementation<
        IOSFlutterLocalNotificationsPlugin>();
    if (ios != null) {
      return await ios.requestPermissions(
            alert: true,
            badge: true,
            sound: true,
          ) ??
          false;
    }

    final macos = _plugin.resolvePlatformSpecificImplementation<
        MacOSFlutterLocalNotificationsPlugin>();
    if (macos != null) {
      return await macos.requestPermissions(
            alert: true,
            badge: true,
            sound: true,
          ) ??
          false;
    }

    return false;
  }

  /// Anlık bildirim gönder
  Future<void> showNotification({
    required int id,
    required String title,
    required String body,
  }) async {
    

    const androidDetails = AndroidNotificationDetails(
      'meditrack_channel',
      'MediTrack Bildirimleri',
      channelDescription: 'İlaç hatırlatıcıları',
      importance: Importance.high,
      priority: Priority.high,
    );

    const details = NotificationDetails(
      android: androidDetails,
      iOS: DarwinNotificationDetails(),
      macOS: DarwinNotificationDetails(),
    );

    await _plugin.show(id, title, body, details);
  }

  /// Günlük tekrarlayan ilaç hatırlatıcısı kur
  Future<void> scheduleDailyReminder({
    required int id,
    required String drugName,
    required int hour,
    required int minute,
  }) async {
    

    const androidDetails = AndroidNotificationDetails(
      'meditrack_reminders',
      'İlaç Hatırlatıcıları',
      channelDescription: 'Günlük ilaç hatırlatıcıları',
      importance: Importance.high,
      priority: Priority.high,
    );

    const details = NotificationDetails(
      android: androidDetails,
      iOS: DarwinNotificationDetails(),
      macOS: DarwinNotificationDetails(),
    );

    await _plugin.zonedSchedule(
      id,
      'İlaç Zamanı 💊',
      '$drugName almanın zamanı geldi.',
      _nextInstanceOf(hour, minute),
      details,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  /// Reçetedeki ilaçlar için hatırlatıcı kur
  /// Frekansa göre saat atar: 1x→08:00, 2x→08+20, 3x→08+14+20, 4x→08+12+16+20
  Future<void> scheduleForDrugs(List<({String name, String frequency})> drugs) async {
    

    await cancelAll();

    int idCounter = 100;
    for (final drug in drugs) {
      final times = _timesForFrequency(drug.frequency);
      for (final time in times) {
        await scheduleDailyReminder(
          id: idCounter++,
          drugName: drug.name,
          hour: time.$1,
          minute: time.$2,
        );
      }
    }
  }

  List<(int, int)> _timesForFrequency(String frequency) {
    switch (frequency) {
      case 'Günde 2 kez':
        return [(8, 0), (20, 0)];
      case 'Günde 3 kez':
        return [(8, 0), (14, 0), (20, 0)];
      case 'Günde 4 kez':
        return [(8, 0), (12, 0), (16, 0), (20, 0)];
      case 'Haftada 1 kez':
        return [(9, 0)];
      case 'Gerektiğinde':
        return [];
      default: // Günde 1 kez
        return [(8, 0)];
    }
  }

  tz.TZDateTime _nextInstanceOf(int hour, int minute) {
    final now = tz.TZDateTime.now(tz.local);
    var scheduled =
        tz.TZDateTime(tz.local, now.year, now.month, now.day, hour, minute);
    if (scheduled.isBefore(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }
    return scheduled;
  }

  Future<void> cancelAll() async {
    
    await _plugin.cancelAll();
  }

  Future<void> cancel(int id) async {
    
    await _plugin.cancel(id);
  }
}
