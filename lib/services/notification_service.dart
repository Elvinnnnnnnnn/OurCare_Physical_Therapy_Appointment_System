import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:intl/intl.dart';

class NotificationService {
  static final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  static Future<void> init() async {
    tz.initializeTimeZones();
    tz.setLocalLocation(tz.local);

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

    final granted = await androidPlugin?.areNotificationsEnabled();
      print("NOTIFICATION PERMISSION: $granted");
    }

    static Future<void> scheduleAllReminders({
      required DateTime appointmentDateTime,
    }) async {
      appointmentDateTime = appointmentDateTime.toLocal();

      final now = DateTime.now();

      await _notifications.zonedSchedule(
    111,
    'Reminder',
    'Appointment Successful, wait for another reminder for your appointment',
    tz.TZDateTime.now(tz.local).add(const Duration(seconds: 10)),
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

  print("TEST NOTIFICATION SCHEDULED");

    print("NOW: $now");
    print("APPOINTMENT: $appointmentDateTime");

    final baseId = appointmentDateTime.millisecondsSinceEpoch ~/ 1000;

    final reminders = [
      {
        "id": baseId + 1,
        "time": appointmentDateTime.subtract(const Duration(days: 5)),
        "label": "5 days"
      },
      {
        "id": baseId + 2,
        "time": appointmentDateTime.subtract(const Duration(hours: 24)),
        "label": "24 hours"
      },
      {
        "id": baseId + 3,
        "time": appointmentDateTime.subtract(const Duration(hours: 1)),
        "label": "1 hour"
      },
      {
        "id": baseId + 4,
        "time": appointmentDateTime.subtract(const Duration(minutes: 10)),
        "label": "10 minutes"
      },
    ];

    if (reminders.every((r) => (r["time"] as DateTime).isBefore(now))) {
      print("All reminders are in the past. Scheduling fallback.");

      await _notifications.zonedSchedule(
        baseId + 999,
        'Appointment Reminder',
        'Your appointment is very soon',
        tz.TZDateTime.now(tz.local).add(const Duration(seconds: 10)),
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
    }

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
      'Welcome',
      'You are all set to begin.',
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