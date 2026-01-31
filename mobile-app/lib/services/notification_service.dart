import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:workmanager/workmanager.dart';
import 'package:timezone/data/latest.dart' as tz_data;
import '../models/notification_model.dart';
import '../models/crop_care_reminder.dart';

class NotificationService {
  static const String _notificationsKey = 'app_notifications';
  static const String _lastReminderKey = 'last_reminder_time';

  static final FlutterLocalNotificationsPlugin
  _flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

  /// Initialize notifications
  static Future<void> initializeNotifications() async {
    tz_data.initializeTimeZones();

    const AndroidInitializationSettings androidInitializationSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const DarwinInitializationSettings iosInitializationSettings =
        DarwinInitializationSettings(
          requestAlertPermission: true,
          requestBadgePermission: true,
          requestSoundPermission: true,
        );

    const InitializationSettings initializationSettings =
        InitializationSettings(
          android: androidInitializationSettings,
          iOS: iosInitializationSettings,
        );

    await _flutterLocalNotificationsPlugin.initialize(
      settings: initializationSettings,
      onDidReceiveNotificationResponse: _onDidReceiveNotificationResponse,
      onDidReceiveBackgroundNotificationResponse:
          _onDidReceiveNotificationResponse,
    );

    // Request iOS notifications permission
    await _flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin
        >()
        ?.requestPermissions(alert: true, badge: true, sound: true);
  }

  /// Handle notification taps
  static void _onDidReceiveNotificationResponse(
    NotificationResponse notificationResponse,
  ) {
    // Handle notification tapped
    print('Notification tapped: ${notificationResponse.payload}');
  }

  /// Initialize background tasks for reminders
  static Future<void> initializeBackgroundTasks() async {
    await Workmanager().initialize(callbackDispatcher, isInDebugMode: false);

    // Schedule daily reminder task
    await Workmanager().registerPeriodicTask(
      'daily_crop_reminder',
      'cropReminderTask',
      frequency: const Duration(hours: 24),
      initialDelay: const Duration(minutes: 10),
    );
  }

  /// Callback for background tasks
  static void callbackDispatcher() {
    Workmanager().executeTask((task, inputData) async {
      if (task == 'cropReminderTask') {
        await _sendRandomReminder();
      }
      return true;
    });
  }

  /// Send a random crop care reminder
  static Future<void> _sendRandomReminder() async {
    final prefs = await SharedPreferences.getInstance();
    final lastReminderStr = prefs.getString(_lastReminderKey);
    final now = DateTime.now();

    // Only send one reminder per day
    if (lastReminderStr != null) {
      final lastReminder = DateTime.parse(lastReminderStr);
      if (now.difference(lastReminder).inHours < 24) {
        return;
      }
    }

    // Get random reminder
    final reminder =
        cropCareReminders[DateTime.now().millisecondsSinceEpoch %
            cropCareReminders.length];
    final language = prefs.getString('app_language') ?? 'en';
    final message = reminder.messages[language] ?? reminder.messages['en']!;

    // Create and show notification
    await showNotification(
      title: 'Crop Care Reminder',
      body: message,
      type: 'reminder',
      cropName: reminder.cropType != 'general' ? reminder.cropType : null,
    );

    // Store last reminder time
    await prefs.setString(_lastReminderKey, now.toIso8601String());

    // Save to notification history
    await _saveNotification(
      title: 'Crop Care Reminder',
      body: message,
      type: 'reminder',
      language: language,
      cropName: reminder.cropType != 'general' ? reminder.cropType : null,
    );
  }

  /// Show a notification
  static Future<void> showNotification({
    required String title,
    required String body,
    required String type,
    String? cropName,
    String? diseaseName,
    String? language,
  }) async {
    const AndroidNotificationDetails androidNotificationDetails =
        AndroidNotificationDetails(
          'crop_alerts',
          'Crop Alerts',
          channelDescription: 'Notifications for crop health and reminders',
          importance: Importance.max,
          priority: Priority.high,
          showWhen: true,
        );

    const DarwinNotificationDetails iosNotificationDetails =
        DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        );

    const NotificationDetails notificationDetails = NotificationDetails(
      android: androidNotificationDetails,
      iOS: iosNotificationDetails,
    );

    await _flutterLocalNotificationsPlugin.show(
      id: DateTime.now().millisecondsSinceEpoch.remainder(0x7fffffff),
      title: title,
      body: body,
      notificationDetails: notificationDetails,
      payload: 'notification_payload',
    );

    // Save to notification history
    await _saveNotification(
      title: title,
      body: body,
      type: type,
      cropName: cropName,
      diseaseName: diseaseName,
      language: language,
    );
  }

  /// Save notification to history
  static Future<void> _saveNotification({
    required String title,
    required String body,
    required String type,
    String? cropName,
    String? diseaseName,
    String? language,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final lang = language ?? prefs.getString('app_language') ?? 'en';

      final notification = AppNotification(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        title: title,
        body: body,
        type: type,
        createdAt: DateTime.now(),
        cropName: cropName,
        diseaseName: diseaseName,
        language: lang,
      );

      // Get existing notifications
      final notificationsJson = prefs.getStringList(_notificationsKey) ?? [];

      // Add new notification at the beginning
      notificationsJson.insert(0, jsonEncode(notification.toJson()));

      // Keep only last 100 notifications
      final limitedList = notificationsJson.take(100).toList();

      await prefs.setStringList(_notificationsKey, limitedList);
    } catch (e) {
      print('Error saving notification: $e');
    }
  }

  /// Get all notifications
  static Future<List<AppNotification>> getNotifications() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final notificationsJson = prefs.getStringList(_notificationsKey) ?? [];

      return notificationsJson
          .map(
            (notificationStr) =>
                AppNotification.fromJson(jsonDecode(notificationStr)),
          )
          .toList();
    } catch (e) {
      print('Error getting notifications: $e');
      return [];
    }
  }

  /// Get unread notification count
  static Future<int> getUnreadCount() async {
    final notifications = await getNotifications();
    return notifications.where((n) => !n.isRead).length;
  }

  /// Mark notification as read
  static Future<void> markAsRead(String notificationId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final notificationsJson = prefs.getStringList(_notificationsKey) ?? [];

      final updatedList = notificationsJson.map((notificationStr) {
        final notification = AppNotification.fromJson(
          jsonDecode(notificationStr),
        );
        if (notification.id == notificationId) {
          return jsonEncode(notification.copyWith(isRead: true).toJson());
        }
        return notificationStr;
      }).toList();

      await prefs.setStringList(_notificationsKey, updatedList);
    } catch (e) {
      print('Error marking notification as read: $e');
    }
  }

  /// Mark all notifications as read
  static Future<void> markAllAsRead() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final notificationsJson = prefs.getStringList(_notificationsKey) ?? [];

      final updatedList = notificationsJson.map((notificationStr) {
        final notification = AppNotification.fromJson(
          jsonDecode(notificationStr),
        );
        return jsonEncode(notification.copyWith(isRead: true).toJson());
      }).toList();

      await prefs.setStringList(_notificationsKey, updatedList);
    } catch (e) {
      print('Error marking all notifications as read: $e');
    }
  }

  /// Delete a notification
  static Future<void> deleteNotification(String notificationId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final notificationsJson = prefs.getStringList(_notificationsKey) ?? [];

      final updatedList = notificationsJson.where((notificationStr) {
        final notification = AppNotification.fromJson(
          jsonDecode(notificationStr),
        );
        return notification.id != notificationId;
      }).toList();

      await prefs.setStringList(_notificationsKey, updatedList);
    } catch (e) {
      print('Error deleting notification: $e');
    }
  }

  /// Clear all notifications
  static Future<void> clearAll() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_notificationsKey);
    } catch (e) {
      print('Error clearing notifications: $e');
    }
  }

  /// Send detection notification
  static Future<void> sendDetectionNotification({
    required String crop,
    required String disease,
    required double confidence,
    String? language,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final lang = language ?? prefs.getString('app_language') ?? 'en';

    final title = _getLocalizedTitle(disease, lang);
    final body =
        '${_getLocalizedCrop(crop, lang)} detected with ${(confidence * 100).toStringAsFixed(0)}% confidence';

    await showNotification(
      title: title,
      body: body,
      type: 'detection',
      cropName: crop,
      diseaseName: disease,
      language: lang,
    );
  }

  static String _getLocalizedTitle(String disease, String language) {
    final titles = {
      'en': 'Disease Detected',
      'hi': 'रोग पता चला',
      'te': 'వ్యాధి గుర్తించబడింది',
      'ta': 'நோய் கண்டறியப்பட்டது',
      'kn': 'ರೋಗ ಕಂಡುಹಿಡಿಯಲಾಗಿದೆ',
    };
    return titles[language] ?? titles['en']!;
  }

  static String _getLocalizedCrop(String crop, String language) {
    final crops = {
      'en': crop,
      'hi': _getCropHindi(crop),
      'te': _getCropTelugu(crop),
      'ta': _getCropTamil(crop),
      'kn': _getCropKannada(crop),
    };
    return crops[language] ?? crops['en']!;
  }

  static String _getCropHindi(String crop) {
    const map = {'cotton': 'कपास', 'rice': 'चावल', 'corn': 'मकई'};
    return map[crop.toLowerCase()] ?? crop;
  }

  static String _getCropTelugu(String crop) {
    const map = {'cotton': 'పత్తి', 'rice': 'రైస్', 'corn': 'మకై'};
    return map[crop.toLowerCase()] ?? crop;
  }

  static String _getCropTamil(String crop) {
    const map = {'cotton': 'பருத்தி', 'rice': 'நெல்', 'corn': 'சோளம்'};
    return map[crop.toLowerCase()] ?? crop;
  }

  static String _getCropKannada(String crop) {
    const map = {'cotton': 'ಹೊಟ್ಟು', 'rice': 'ಅಕ್ಕಿ', 'corn': 'ಕಾರ್ನ್'};
    return map[crop.toLowerCase()] ?? crop;
  }
}
