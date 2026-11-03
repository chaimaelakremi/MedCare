import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;

class NotificationService {
  static final _plugin = FlutterLocalNotificationsPlugin();

  static bool get _supported => !kIsWeb;

  static Future<void> initialize() async {
    if (!_supported) return;
    try {
      const android = AndroidInitializationSettings('@mipmap/ic_launcher');
      const darwin = DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
      );
      const linux = LinuxInitializationSettings(defaultActionName: 'Open');

      await _plugin.initialize(
        const InitializationSettings(android: android, iOS: darwin, macOS: darwin, linux: linux),
      );

      if (Platform.isAndroid) {
        await _plugin
            .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
            ?.requestNotificationsPermission();
      }
    } catch (_) {}
  }

  static Future<void> scheduleReminder({
    required int id,
    required String medicationName,
    required String dose,
    required DateTime scheduledTime,
    String locale = 'fr',
  }) async {
    if (!_supported) return;
    try {
      final tzTime = tz.TZDateTime.from(scheduledTime, tz.local);
      final title = locale == 'fr' ? '💊 Heure de vos médicaments' : '💊 Medication Time';
      final body = locale == 'fr'
          ? 'Prenez $medicationName – $dose'
          : 'Take $medicationName – $dose';

      await _plugin.zonedSchedule(
        id,
        title,
        body,
        tzTime,
        NotificationDetails(
          android: AndroidNotificationDetails(
            'medcare_reminders',
            locale == 'fr' ? 'Rappels médicaments' : 'Medication Reminders',
            importance: Importance.high,
            priority: Priority.high,
            color: const Color(0xFF9B7EBD),
          ),
          iOS: const DarwinNotificationDetails(presentAlert: true, presentBadge: true, presentSound: true),
        ),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        matchDateTimeComponents: DateTimeComponents.time,
      );
    } catch (_) {}
  }

  static Future<void> cancel(int id) async {
    if (!_supported) return;
    try {
      await _plugin.cancel(id);
    } catch (_) {}
  }

  static Future<void> cancelAll() async {
    if (!_supported) return;
    try {
      await _plugin.cancelAll();
    } catch (_) {}
  }
}
