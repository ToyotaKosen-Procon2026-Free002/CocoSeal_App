import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'screens/admin/admin_home_screen.dart';
import 'screens/parent/parent_home_screen.dart';
import 'screens/auth/login_screen.dart';

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        // 読み込み中
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        // 未ログインならログイン画面へ
        if (!snapshot.hasData) {
          return const LoginScreen();
        }

        // ログイン済みの場合はユーザー情報（role）を取得して分岐
        final user = snapshot.data!;
        return FutureBuilder<DocumentSnapshot>(
          future: FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .get(),
          builder: (context, userSnapshot) {
            if (userSnapshot.connectionState == ConnectionState.waiting) {
              return const Scaffold(
                body: Center(child: CircularProgressIndicator()),
              );
            }

            if (userSnapshot.hasData && userSnapshot.data!.exists) {
              final data = userSnapshot.data!.data() as Map<String, dynamic>?;
              
              // DBの role 値を取得（数値または文字列に対応）
              final dynamic roleValue = data?['role'];

              // 1の場合は親機画面、0・それ以外は保護者画面へ
              if (roleValue == 1 || roleValue == '1') {
                return const AdminHomeScreen();
              } else {
                return const ParentHomeScreen();
              }
            }

            // データが取れなかった場合のデフォルト画面
            return const ParentHomeScreen();
          },
        );
      },
    );
  }
}