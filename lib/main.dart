import 'auth_gate.dart';
import 'firebase_options.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Web環境などでService Workerがなくてもアプリが止まらないよう try-catch で保護
  try {
    FirebaseMessaging messaging = FirebaseMessaging.instance;
    await messaging.requestPermission();
    String? token = await messaging.getToken();
    print('FCM Token: $token');
  } catch (e) {
    print('FirebaseMessaging 初期化スキップ (Web環境等): $e');
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
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.pink), // ColorSchemeを追加
        useMaterial3: true,
      ),
      home: const AuthGate(),
      debugShowCheckedModeBanner: false,
    );
  }
}