import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'storage_service.dart';

class NotificationService {
  static final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  static Future<void> init() async {
    tz.initializeTimeZones();

    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const DarwinInitializationSettings initializationSettingsIOS =
        DarwinInitializationSettings(
          requestAlertPermission: true,
          requestBadgePermission: true,
          requestSoundPermission: true,
        );

    const InitializationSettings initializationSettings =
        InitializationSettings(
          android: initializationSettingsAndroid,
          iOS: initializationSettingsIOS,
        );

    await _notificationsPlugin.initialize(initializationSettings);

    // Request permissions for Android 13+
    await _notificationsPlugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.requestNotificationsPermission();
  }

  /// Generates a unique integer ID from a Firestore document ID.
  static int getNotificationId(String firestoreId) {
    return firestoreId.hashCode % 0x7FFFFFFF;
  }

  static Future<void> scheduleReminder({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledDate,
  }) async {
    if (!await StorageService.getReminderNotificationsEnabled()) return;

    // Only schedule if the date is in the future
    if (scheduledDate.isBefore(DateTime.now())) return;

    await _notificationsPlugin.zonedSchedule(
      id,
      title,
      body,
      tz.TZDateTime.from(scheduledDate, tz.local),
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'reminder_channel',
          'Reminders',
          importance: Importance.max,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
    );
  }

  static Future<void> cancelReminder(int id) async {
    await _notificationsPlugin.cancel(id);
  }

  static Future<void> cancelAllReminders() async {
    await _notificationsPlugin.cancelAll();
  }

  static Future<void> showInstantNotification({
    required int id,
    required String title,
    required String body,
  }) async {
    await _notificationsPlugin.show(
      id,
      title,
      body,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'vault_download_channel',
          'Vault Downloads',
          importance: Importance.max,
          priority: Priority.high,
          largeIcon: DrawableResourceAndroidBitmap('@mipmap/ic_launcher'),
        ),
        iOS: DarwinNotificationDetails(),
      ),
    );
  }

  static Future<bool> areReminderNotificationsEnabled() {
    return StorageService.getReminderNotificationsEnabled();
  }

  static Future<void> setReminderNotificationsEnabled(bool enabled) async {
    await StorageService.setReminderNotificationsEnabled(enabled);
    if (enabled) {
      await syncAllReminders();
      return;
    }

    await cancelAllReminders();
  }

  /// Syncs all active reminders from Firestore and schedules them locally.
  static Future<void> syncAllReminders() async {
    try {
      if (!await StorageService.getReminderNotificationsEnabled()) {
        await cancelAllReminders();
        return;
      }

      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      final snapshot =
          await FirebaseFirestore.instanceFor(
                app: Firebase.app(),
                databaseId: 'ffpvault',
              )
              .collection('reminders')
              .where('userId', isEqualTo: user.uid)
              .where('isDone', isEqualTo: false)
              .get();

      for (var doc in snapshot.docs) {
        final data = doc.data();
        if (data['notificationEnabled'] == false) {
          await cancelReminder(getNotificationId(doc.id));
          continue;
        }
        if (data['remindAt'] is Timestamp) {
          final DateTime remindAt = (data['remindAt'] as Timestamp).toDate();
          if (remindAt.isAfter(DateTime.now())) {
            await scheduleReminder(
              id: getNotificationId(doc.id),
              title: data['title'] ?? 'Reminder',
              body: data['note'] ?? 'You have a pending task.',
              scheduledDate: remindAt,
            );
          }
        }
      }
      debugPrint(
        'NotificationService: Synced ${snapshot.docs.length} reminders.',
      );
    } catch (e) {
      debugPrint('NotificationService: Error syncing reminders: $e');
    }
  }

  static Future<void> initFCM() async {
    try {
      FirebaseMessaging messaging = FirebaseMessaging.instance;

      NotificationSettings settings = await messaging.requestPermission(
        alert: true,
        announcement: false,
        badge: true,
        carPlay: false,
        criticalAlert: false,
        provisional: false,
        sound: true,
      );

      if (settings.authorizationStatus == AuthorizationStatus.authorized) {
        // On iOS, getToken() can throw apns-token-not-set if called too early.
        // We catch it and rely on onTokenRefresh or a subsequent manual refresh.
        try {
          String? token = await messaging.getToken();
          if (token != null) {
            await saveTokenToDatabase(token);
          }
        } catch (e) {
          debugPrint(
            'NotificationService: Initial FCM token retrieval skipped/failed: $e',
          );
        }

        FirebaseMessaging.instance.onTokenRefresh.listen(saveTokenToDatabase);
      }
    } catch (e) {
      debugPrint('NotificationService: FCM initialization error: $e');
    }
  }

  static Future<void> saveTokenToDatabase(String token) async {
    String? userId = await StorageService.getUserId();
    if (userId != null) {
      try {
        await FirebaseFirestore.instanceFor(
          app: Firebase.app(),
          databaseId: 'ffpvault',
        ).collection('users').doc(userId).set({
          'fcmToken': token,
        }, SetOptions(merge: true));
      } catch (e) {
        debugPrint('Error saving FCM token directly: $e');
      }
    }
  }
}
