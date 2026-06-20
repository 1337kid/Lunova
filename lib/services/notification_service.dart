import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:permission_handler/permission_handler.dart';
import '../models/cycle_entry.dart';
import 'database_service.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  static const String _periodChannelId = 'period_reminders';
  static const String _fertileChannelId = 'fertile_alerts';
  static const String _generalChannelId = 'general_reminders';

  bool _exactAlarmsGranted = false;

  Future<void> init() async {
    tz.initializeTimeZones();

    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const DarwinInitializationSettings initializationSettingsIOS =
        DarwinInitializationSettings(
          requestAlertPermission: true,
          requestBadgePermission: true,
          requestSoundPermission: true,
        );

    final InitializationSettings initializationSettings =
        InitializationSettings(
          android: initializationSettingsAndroid,
          iOS: initializationSettingsIOS,
        );

    await _flutterLocalNotificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: _onDidReceiveNotificationResponse,
    );

    await _requestPermissions();
    await _createNotificationChannels();
  }

  Future<void> _requestPermissions() async {
    if (await Permission.notification.isDenied) {
      await Permission.notification.request();
    }

    await _requestExactAlarmPermission();
  }

  Future<void> _requestExactAlarmPermission() async {
    if (await Permission.scheduleExactAlarm.isDenied) {
      final status = await Permission.scheduleExactAlarm.request();
      _exactAlarmsGranted = status.isGranted;
    } else {
      _exactAlarmsGranted = await Permission.scheduleExactAlarm.isGranted;
    }

    if (!_exactAlarmsGranted) {
      print('Exact alarms not permitted. Using inexact scheduling.');
    }
  }

  Future<void> _createNotificationChannels() async {
    const AndroidNotificationChannel periodChannel = AndroidNotificationChannel(
      _periodChannelId,
      'Period Reminders',
      description: 'Reminders for upcoming periods and fertility',
      importance: Importance.high,
      enableVibration: true,
      playSound: true,
    );

    const AndroidNotificationChannel fertileChannel =
        AndroidNotificationChannel(
          _fertileChannelId,
          'Fertility Alerts',
          description: 'Alerts for fertile windows and ovulation',
          importance: Importance.high,
          enableVibration: true,
          playSound: true,
        );

    const AndroidNotificationChannel generalChannel =
        AndroidNotificationChannel(
          _generalChannelId,
          'General Reminders',
          description: 'General app reminders',
          importance: Importance.defaultImportance,
        );

    await _flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.createNotificationChannel(periodChannel);
    await _flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.createNotificationChannel(fertileChannel);
    await _flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.createNotificationChannel(generalChannel);
  }

  void _onDidReceiveNotificationResponse(NotificationResponse response) {
    print('Notification tapped: ${response.payload}');
  }

  Future<void> showNotification({
    required int id,
    required String title,
    required String body,
    String? payload,
  }) async {
    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
          _generalChannelId,
          'General Reminders',
          importance: Importance.high,
          priority: Priority.high,
          styleInformation: BigTextStyleInformation(''),
        );

    const DarwinNotificationDetails iOSPlatformChannelSpecifics =
        DarwinNotificationDetails();

    final NotificationDetails platformChannelSpecifics = NotificationDetails(
      android: androidPlatformChannelSpecifics,
      iOS: iOSPlatformChannelSpecifics,
    );

    await _flutterLocalNotificationsPlugin.show(
      id,
      title,
      body,
      platformChannelSpecifics,
      payload: payload,
    );
  }

  Future<void> scheduleNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledDate,
    String? payload,
  }) async {
    final tz.TZDateTime scheduledTZDateTime = tz.TZDateTime.from(
      scheduledDate,
      tz.local,
    );

    if (scheduledTZDateTime.isBefore(tz.TZDateTime.now(tz.local))) {
      return;
    }

    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
          _periodChannelId,
          'Period Reminders',
          importance: Importance.high,
          priority: Priority.high,
          styleInformation: BigTextStyleInformation(''),
        );

    const DarwinNotificationDetails iOSPlatformChannelSpecifics =
        DarwinNotificationDetails();

    final NotificationDetails platformChannelSpecifics = NotificationDetails(
      android: androidPlatformChannelSpecifics,
      iOS: iOSPlatformChannelSpecifics,
    );

    await _flutterLocalNotificationsPlugin.zonedSchedule(
      id,
      title,
      body,
      scheduledTZDateTime,
      platformChannelSpecifics,
      payload: payload,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
    );
  }

  Future<void> schedulePeriodReminder(DateTime periodStartDate) async {
    final reminderDate = periodStartDate.subtract(const Duration(days: 3));

    if (reminderDate.isAfter(DateTime.now())) {
      await scheduleNotification(
        id: 1001,
        title: 'Period Approaching',
        body:
            'Your period is predicted to start on ${_formatDate(periodStartDate)}.',
        scheduledDate: reminderDate,
        payload: 'period_reminder',
      );
    }
  }

  Future<void> scheduleFertileAlert(DateTime fertileStartDate) async {
    final alertDate = fertileStartDate.subtract(const Duration(days: 5));

    if (alertDate.isAfter(DateTime.now())) {
      await scheduleNotification(
        id: 1002,
        title: 'Fertile Window Coming',
        body: 'Your fertile window starts on ${_formatDate(fertileStartDate)}.',
        scheduledDate: alertDate,
        payload: 'fertile_alert',
      );
    }
  }

  Future<void> scheduleOvulationReminder(DateTime ovulationDate) async {
    if (ovulationDate.isAfter(DateTime.now())) {
      await scheduleNotification(
        id: 1003,
        title: 'Ovulation Day',
        body: 'Today is your ovulation day.',
        scheduledDate: ovulationDate,
        payload: 'ovulation_alert',
      );
    }
  }

  Future<void> schedulePeriodSummary(DateTime periodEndDate) async {
    final summaryDate = periodEndDate.add(const Duration(days: 1));

    if (summaryDate.isAfter(DateTime.now())) {
      await scheduleNotification(
        id: 1004,
        title: 'Period Complete',
        body: 'Your period has ended. Log your symptoms.',
        scheduledDate: summaryDate,
        payload: 'period_summary',
      );
    }
  }

  Future<void> scheduleDailyCheckIn() async {
    final now = DateTime.now();
    final checkInTime = DateTime(now.year, now.month, now.day, 20, 0);

    final scheduledDate =
        checkInTime.isAfter(now)
            ? checkInTime
            : checkInTime.add(const Duration(days: 1));

    await scheduleNotification(
      id: 999,
      title: 'Daily Check-In',
      body: 'How are you feeling today? Log your symptoms.',
      scheduledDate: scheduledDate,
      payload: 'daily_checkin',
    );
  }

  Future<void> cancelAllNotifications() async {
    await _flutterLocalNotificationsPlugin.cancelAll();
  }

  Future<void> cancelNotification(int id) async {
    await _flutterLocalNotificationsPlugin.cancel(id);
  }

  Future<void> scheduleAllNotifications(DatabaseService db) async {
    await cancelAllNotifications();

    final periods = db.getPeriodStarts();
    if (periods.isEmpty) {
      return;
    }

    final lastPeriod = periods.last.date;

    final nextPeriod = db.predictNextPeriod();
    if (nextPeriod != null) {
      await schedulePeriodReminder(nextPeriod);

      final periodEndDate = nextPeriod.add(
        Duration(days: db.getSettings().periodLength - 1),
      );
      await schedulePeriodSummary(periodEndDate);
    }

    final fertileWindow = db.getFertileWindow(cycleStartDate: lastPeriod);
    if (fertileWindow.isNotEmpty) {
      await scheduleFertileAlert(fertileWindow.first);

      final ovulationDay = db.getOvulationDay(cycleStartDate: lastPeriod);
      if (ovulationDay != null) {
        await scheduleOvulationReminder(ovulationDay);
      }
    }

    if (periods.isNotEmpty) {
      await scheduleDailyCheckIn();
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}

final notificationService = NotificationService();
