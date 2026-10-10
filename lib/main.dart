import 'auth_gate.dart';
import 'firebase_options.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

final FlutterLocalNotificationsPlugin _localNotifications =
    FlutterLocalNotificationsPlugin();

const AndroidNotificationChannel _notificationChannel =
    AndroidNotificationChannel(
  'coco_seal_alerts',
  'ココ・シール通知',
  description: 'SOSやバッテリー低下などの重要な通知',
  importance: Importance.max,
);

Future<void> _initializeNotifications() async {
  const androidSettings =
      AndroidInitializationSettings('@mipmap/ic_launcher');

  const initializationSettings = InitializationSettings(
    android: androidSettings,
  );

  await _localNotifications.initialize(initializationSettings);

  final androidPlugin =
      _localNotifications.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();

  await androidPlugin?.createNotificationChannel(_notificationChannel);
  await androidPlugin?.requestNotificationsPermission();
}

Future<void> _showForegroundNotification(RemoteMessage message) async {
  final notification = message.notification;

  final title =
      notification?.title ?? message.data['title']?.toString() ?? 'ココ・シール';
  final body = notification?.body ??
      message.data['body']?.toString() ??
      message.data['message']?.toString() ??
      '新しい通知があります';

  await _localNotifications.show(
    message.messageId?.hashCode ??
        DateTime.now().millisecondsSinceEpoch.remainder(100000),
    title,
    body,
    NotificationDetails(
      android: AndroidNotificationDetails(
        _notificationChannel.id,
        _notificationChannel.name,
        channelDescription: _notificationChannel.description,
        importance: Importance.max,
        priority: Priority.high,
        category: AndroidNotificationCategory.alarm,
      ),
    ),
    payload: message.data.isEmpty ? null : message.data.toString(),
  );
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  try {
    final messaging = FirebaseMessaging.instance;

    await messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    await _initializeNotifications();

    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      _showForegroundNotification(message);
    });

    final token = await messaging.getToken();
    debugPrint('FCM token acquired: ${token != null}');
  } catch (e) {
    debugPrint('FirebaseMessaging 初期化スキップ (Web環境等): $e');
  }

  runApp(const CocoSealApp());
}

class CocoSealApp extends StatelessWidget {
  const CocoSealApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ココ・シール',
      theme: ThemeData(
        primarySwatch: Colors.pink,
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.pink),
        useMaterial3: true,
      ),
      home: const AuthGate(),
      debugShowCheckedModeBanner: false,
    );
  }
}
