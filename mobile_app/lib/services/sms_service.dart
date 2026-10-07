import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_sms_inbox/flutter_sms_inbox.dart';
import 'package:permission_handler/permission_handler.dart';
import '../models/prediction_result.dart';
import 'onnx_service.dart';

class DeviceSmsItem {
  final String sender;
  final String body;
  final DateTime date;
  final PredictionResult result;

  DeviceSmsItem({
    required this.sender,
    required this.body,
    required this.date,
    required this.result,
  });
}

class SmsService {
  static final SmsService _instance = SmsService._internal();
  factory SmsService() => _instance;
  SmsService._internal();

  final SmsQuery _query = SmsQuery();
  final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();
  bool _isNotificationInitialized = false;

  static const _incomingSmsChannel =
      EventChannel('com.spamdetector.sms_spam_detector_app/incoming_sms');
  Stream<DeviceSmsItem>? _incomingSmsStream;

  /// Listen to live incoming SMS events on Android
  Stream<DeviceSmsItem> listenToIncomingSms() {
    if (_incomingSmsStream != null) return _incomingSmsStream!;

    _incomingSmsStream = _incomingSmsChannel
        .receiveBroadcastStream()
        .asyncMap((dynamic event) async {
      if (event is Map) {
        final sender = event['sender'] as String? ?? 'Unknown';
        final body = event['body'] as String? ?? '';
        final senderLower = sender.toLowerCase();
        final bodyLower = body.toLowerCase();

        // Quietly drop MAHABK messages
        if (senderLower.contains('mahabk') ||
            senderLower.contains('mahabank') ||
            bodyLower.contains('mahabk') ||
            bodyLower.contains('mahabank')) {
          return null;
        }

        final prediction =
            await OnnxService().predict(body, sender: sender);

        if (prediction.isBlockedRule) return null;

        // If Spam, show instant notification alert
        if (prediction.isSpam) {
          showSpamNotification(
            sender: sender,
            body: body,
            spamProbability: prediction.spamProbability,
          );
        }

        return DeviceSmsItem(
          sender: sender,
          body: body,
          date: DateTime.now(),
          result: prediction,
        );
      }
      return null;
    }).where((item) => item != null).cast<DeviceSmsItem>();

    return _incomingSmsStream!;
  }

  /// Request Android Runtime Permissions for SMS and Notifications
  Future<bool> requestPermissions() async {
    if (kIsWeb) return false;

    Map<Permission, PermissionStatus> statuses = await [
      Permission.sms,
      Permission.notification,
    ].request();

    final smsGranted = statuses[Permission.sms]?.isGranted ?? false;
    return smsGranted;
  }

  /// Initialize Android Local Notifications
  Future<void> initNotifications() async {
    if (_isNotificationInitialized || kIsWeb) return;

    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const initSettings = InitializationSettings(android: androidSettings);

    await _notifications.initialize(initSettings);
    _isNotificationInitialized = true;
  }

  /// Show Spam Alert Notification
  Future<void> showSpamNotification({
    required String sender,
    required String body,
    required double spamProbability,
  }) async {
    await initNotifications();

    const androidDetails = AndroidNotificationDetails(
      'spam_alerts_channel',
      'SMS Spam Alerts',
      channelDescription:
          'Notifications triggered when incoming SMS is flagged as Spam by ONNX Model.',
      importance: Importance.max,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
    );

    const details = NotificationDetails(android: androidDetails);

    final percent = (spamProbability * 100).toStringAsFixed(0);
    await _notifications.show(
      DateTime.now().millisecondsSinceEpoch ~/ 1000,
      '🚨 SPAM SMS DETECTED ($percent%)',
      'From $sender: "$body"',
      details,
    );
  }

  /// Read device SMS inbox and quietly drop all MAHABK messages from memory & view
  Future<List<DeviceSmsItem>> fetchAndAnalyzeInbox({int limit = 50}) async {
    if (kIsWeb) return [];

    final hasPermission = await requestPermissions();
    if (!hasPermission) return [];

    try {
      final messages = await _query.querySms(
        kinds: [SmsQueryKind.inbox],
        count: limit,
      );

      final List<DeviceSmsItem> analyzedList = [];
      final onnxService = OnnxService();

      for (var sms in messages) {
        final bodyText = sms.body ?? '';
        final senderText = sms.address ?? 'Unknown';
        final dateObj = sms.date ?? DateTime.now();

        if (bodyText.trim().isEmpty) continue;

        // Quietly filter & drop MAHABK messages for privacy
        final senderLower = senderText.toLowerCase();
        final bodyLower = bodyText.toLowerCase();
        if (senderLower.contains('mahabk') ||
            senderLower.contains('mahabank') ||
            bodyLower.contains('mahabk') ||
            bodyLower.contains('mahabank')) {
          continue; // Quietly ignore and do not include in app memory/UI
        }

        final prediction =
            await onnxService.predict(bodyText, sender: senderText);

        if (prediction.isBlockedRule) {
          continue; // Quietly drop any other blocked rules
        }

        analyzedList.add(
          DeviceSmsItem(
            sender: senderText,
            body: bodyText,
            date: dateObj,
            result: prediction,
          ),
        );
      }

      // Sort strictly by date descending so the newest/current SMS is always at the top
      analyzedList.sort((a, b) => b.date.compareTo(a.date));

      return analyzedList;
    } catch (e) {
      if (kDebugMode) {
        print('Error reading device SMS inbox: $e');
      }
      return [];
    }
  }
}
