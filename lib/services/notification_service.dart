import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:intl/intl.dart';

class NotificationService {
  static final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  static Future<void> init() async {
    try {
      tz.initializeTimeZones();
      tz.setLocalLocation(tz.getLocation('Asia/Manila'));

      const android = AndroidInitializationSettings('@mipmap/ic_launcher');
      const settings = InitializationSettings(android: android);

      await _notifications.initialize(settings);

      await requestPermissions();

    } catch (e) {
      print('INIT ERROR: $e');
    }
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
      try {
        await Future.delayed(const Duration(seconds: 2));

        appointmentDateTime = appointmentDateTime.toLocal();
        final now = DateTime.now();

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

        final formattedTime =
            DateFormat('hh:mm a').format(appointmentDateTime);

        for (var reminder in reminders) {
          final DateTime reminderTime = reminder["time"] as DateTime;

          print("Checking ${reminder["label"]}");
          print("Reminder time: $reminderTime");

          if (reminderTime.isBefore(now)) {
            print("Skipped ${reminder["label"]}");
            continue;
          }

          try {
            _notifications.zonedSchedule(
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
          } catch (e) {
            print('SCHEDULE ERROR: $e');
          }
        }

      } catch (e) {
        print('MAIN SCHEDULE ERROR: $e');
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