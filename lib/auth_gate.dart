import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'api_service.dart';
import 'auth_navigation.dart';
import 'models/user.dart' as app_models;
import 'screens/admin/admin_home_screen.dart';
import 'screens/auth/login_screen.dart';
import 'screens/parent/parent_home_screen.dart';

class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  Future<app_models.User>? _profileFuture;
  String? _loadedUid;

  Future<app_models.User> _profileFor(User firebaseUser) {
    if (_loadedUid != firebaseUser.uid || _profileFuture == null) {
      _loadedUid = firebaseUser.uid;
      _profileFuture = ApiService.fetchUserProfile();
    }
    return _profileFuture!;
  }

  void _retry(User firebaseUser) {
    setState(() {
      _loadedUid = firebaseUser.uid;
      _profileFuture = ApiService.fetchUserProfile();
    });
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        final firebaseUser = snapshot.data;
        if (firebaseUser == null) {
          _loadedUid = null;
          _profileFuture = null;
          return const LoginScreen();
        }
        return FutureBuilder<app_models.User>(
          future: _profileFor(firebaseUser),
          builder: (context, profileSnapshot) {
            if (profileSnapshot.connectionState == ConnectionState.waiting) {
              return const Scaffold(
                body: Center(child: CircularProgressIndicator()),
              );
            }
            if (profileSnapshot.hasError) {
              return _ApiLoadError(
                message: profileSnapshot.error.toString(),
                onRetry: () => _retry(firebaseUser),
              );
            }
            if (profileSnapshot.data?.roll == 1) {
              return const AdminHomeScreen();
            }
            return const ParentHomeScreen();
          },
        );
      },
    );
  }
}

class _ApiLoadError extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ApiLoadError({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('ユーザー情報を取得できませんでした'),
              const SizedBox(height: 8),
              Text(message, textAlign: TextAlign.center),
              const SizedBox(height: 16),
              ElevatedButton(onPressed: onRetry, child: const Text('再試行')),
              TextButton(
                onPressed: () => logoutAndReturnToLogin(context),
                child: const Text('ログアウト'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
