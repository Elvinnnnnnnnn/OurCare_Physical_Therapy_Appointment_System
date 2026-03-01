import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:intl/intl.dart';

class NotificationService {
  static final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  static Future<void> init() async {
    tz.initializeTimeZones();
    tz.setLocalLocation(tz.getLocation('Asia/Manila'));

    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const settings = InitializationSettings(android: android);

    await _notifications.initialize(settings);
  }

  static Future<void> requestPermissions() async {
    final androidPlugin =
        _notifications.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();

    await androidPlugin?.requestNotificationsPermission();
    await androidPlugin?.requestExactAlarmsPermission();
  }

  static Future<void> scheduleAllReminders({
    required DateTime appointmentDateTime,
  }) async {
    final now = DateTime.now();

    print("NOW: $now");
    print("APPOINTMENT: $appointmentDateTime");

    final baseId = appointmentDateTime.millisecondsSinceEpoch ~/ 1000;

    final reminders = [
      {
        "id": baseId + 1,
        "time": appointmentDateTime.subtract(const Duration(minutes: 1)),
        "label": "1 minute"
      },
    ];

    final formattedTime =
        DateFormat('hh:mm a').format(appointmentDateTime);

    for (var reminder in reminders) {
      final DateTime reminderTime = reminder["time"] as DateTime;

      print("Checking ${reminder["label"]}");
      print("Reminder time: $reminderTime");

      if (reminderTime.isBefore(now)) {
        print("Skipped ${reminder["label"]} (past time)");
        continue;
      }

      await _notifications.zonedSchedule(
        reminder["id"] as int,
        'Appointment Reminder',
        'Your appointment is at $formattedTime',
        tz.TZDateTime.from(reminderTime, tz.local),
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'appointment_channel',
            'Appointment Reminders',
            importance: Importance.max,
            priority: Priority.high,
          ),
        ),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
      );

      print("Scheduled ${reminder["label"]}");
      print("NOW: ${DateTime.now()}");
      print("APPOINTMENT: $appointmentDateTime");
    }
  }

  static Future<void> showInstantTest() async {
    await _notifications.show(
      999,
      'Test Notification',
      'If you see this immediately, notifications work.',
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'appointment_channel',
          'Appointment Reminders',
          importance: Importance.max,
          priority: Priority.high,
        ),
      ),
    );

    print("INSTANT TEST NOTIFICATION SHOWN");
  }
}