import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notifications = FlutterLocalNotificationsPlugin();

  Future<void> initialize() async {
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );
    const settings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );
    await _notifications.initialize(
      settings,
      onDidReceiveNotificationResponse: (details) {
        _handleNotificationTap(details.payload);
      },
    );
  }

  Future<void> requestPermissions() async {
    await _notifications
        .resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>()
        ?.requestPermissions(
          alert: true,
          badge: true,
          sound: true,
        );
  }

  Future<void> showMatchNotification({
    required String matchName,
    required String matchId,
  }) async {
    const details = NotificationDetails(
      iOS: DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      ),
    );
    await _notifications.show(
      DateTime.now().millisecondsSinceEpoch.remainder(100000),
      "It's a Match!",
      "You matched with $matchName",
      details,
      payload: 'match:$matchId',
    );
  }

  Future<void> showMessageNotification({
    required String senderName,
    required String message,
    required String matchId,
  }) async {
    const details = NotificationDetails(
      iOS: DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      ),
    );
    await _notifications.show(
      DateTime.now().millisecondsSinceEpoch.remainder(100000),
      senderName,
      message,
      details,
      payload: 'chat:$matchId',
    );
  }

  Future<void> showMatchDayReminder({
    required String teamA,
    required String teamB,
    required String city,
  }) async {
    const details = NotificationDetails(
      iOS: DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: false,
        presentSound: true,
      ),
    );
    await _notifications.show(
      DateTime.now().millisecondsSinceEpoch.remainder(100000),
      "Match Day!",
      "$teamA vs $teamB in $city today",
      details,
      payload: 'worldcup',
    );
  }

  void _handleNotificationTap(String? payload) {
    if (payload == null) return;
    // match:ID → switch to chat tab
    // chat:ID → open conversation
    // worldcup → open world cup tab
  }
}
