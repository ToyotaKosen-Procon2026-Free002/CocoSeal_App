import 'dart:async';
import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import 'models/device.dart';
import 'models/gateway.dart';
import 'models/nearby_communication.dart';
import 'models/seal.dart';
import 'models/user.dart' as app_models;

class ApiException implements Exception {
  final String message;
  final int? statusCode;

  const ApiException(
    this.message, {
    this.statusCode,
  });

  @override
  String toString() => message;
}

class ApiService {
  static const String baseUrl = 'https://coco-seal.mydns.jp';
  static const Duration _timeout = Duration(seconds: 15);

  /// Firebaseの認証トークンを含むHTTPヘッダーを作成する
  static Future<Map<String, String>> _getHeaders() async {
    final firebaseUser = FirebaseAuth.instance.currentUser;

    if (firebaseUser == null) {
      throw const ApiException(
        'ログイン情報がありません。もう一度ログインしてください。',
      );
    }

    final idToken = await firebaseUser.getIdToken();

    if (idToken == null || idToken.isEmpty) {
      throw const ApiException(
        '認証トークンを取得できませんでした。',
      );
    }

    return {
      'Accept': 'application/json',
      'Content-Type': 'application/json; charset=UTF-8',
      'Authorization': 'Bearer $idToken',
    };
  }

  /// APIレスポンスをJSONに変換する
  static dynamic _decode(http.Response response) {
    if (response.statusCode < 200 ||
        response.statusCode >= 300) {
      String message =
          'サーバーとの通信に失敗しました (${response.statusCode})';

      try {
        final body = jsonDecode(
          utf8.decode(response.bodyBytes),
        );

        if (body is Map<String, dynamic>) {
          message = body['description']?.toString() ??
              body['detail']?.toString() ??
              message;
        }
      } catch (_) {
        // JSONとして読み取れない場合は、
        // 最初に設定したメッセージを使用する
      }

      throw ApiException(
        message,
        statusCode: response.statusCode,
      );
    }

    if (response.bodyBytes.isEmpty) {
      return null;
    }

    return jsonDecode(
      utf8.decode(response.bodyBytes),
    );
  }

  /// GETリクエストにbodyが必要な場合に使用する
  static Future<http.Response> _send(
    http.BaseRequest request,
  ) async {
    try {
      final streamed =
          await request.send().timeout(_timeout);

      return await http.Response.fromStream(streamed);
    } on TimeoutException {
      throw const ApiException(
        '通信がタイムアウトしました。',
      );
    } catch (error) {
      debugPrint('Network error: $error');

      throw const ApiException(
        'サーバーに接続できませんでした。',
      );
    }
  }

  /// ログイン中のユーザー情報を取得する
  static Future<app_models.User> fetchUserProfile() async {
    final response = await http
        .get(
          Uri.parse('$baseUrl/users/me'),
          headers: await _getHeaders(),
        )
        .timeout(_timeout);

    return app_models.User.fromJson(
      _decode(response) as Map<String, dynamic>,
    );
  }

  /// ログイン中のユーザー情報を更新する
  static Future<app_models.User> updateUserProfile({
    String? displayName,
    String? email,
    int? role,
  }) async {
    final body = <String, dynamic>{
      if (displayName != null)
        'display_name': displayName,
      if (email != null) 'email': email,
      if (role != null) 'roll': role,
    };

    final response = await http
        .patch(
          Uri.parse('$baseUrl/users/me'),
          headers: await _getHeaders(),
          body: jsonEncode(body),
        )
        .timeout(_timeout);

    return app_models.User.fromJson(
      _decode(response) as Map<String, dynamic>,
    );
  }

  /// 子機をログインユーザーに登録する
  static Future<void> registerChild(
    String deviceId,
  ) async {
    final url = Uri.parse(
      '$baseUrl/users/device',
    ).replace(
      queryParameters: {
        'device_id': deviceId,
      },
    );

    final response = await http
        .post(
          url,
          headers: await _getHeaders(),
        )
        .timeout(_timeout);

    _decode(response);
  }

  /// 登録済み子機の表示名を更新する
  static Future<void> updateChildName({
    required String deviceId,
    required String name,
  }) async {
    final response = await http
        .patch(
          Uri.parse('$baseUrl/users/device'),
          headers: await _getHeaders(),
          body: jsonEncode({
            'device_id': deviceId,
            'name': name,
          }),
        )
        .timeout(_timeout);

    _decode(response);
  }

  /// ログインユーザーの登録済み子機一覧を取得する
  static Future<List<Device>> fetchUserDevices() async {
    final response = await http
        .get(
          Uri.parse('$baseUrl/users/devices'),
          headers: await _getHeaders(),
        )
        .timeout(_timeout);

    final list = _decode(response) as List<dynamic>;

    return list
        .map(
          (item) => Device.fromJson(
            item as Map<String, dynamic>,
          ),
        )
        .toList();
  }

  /// 子機のすれ違い履歴を取得する
  static Future<List<NearbyCommunication>>
      fetchNearbyCommunications({
    required String deviceId,
    required DateTime startAt,
    required DateTime endAt,
  }) async {
    // Swagger仕様では、このGETエンドポイントは
    // JSON bodyを要求する
    final request = http.Request(
      'GET',
      Uri.parse(
        '$baseUrl/users/nearby_communications_log',
      ),
    );

    request.headers.addAll(
      await _getHeaders(),
    );

    request.body = jsonEncode({
      'device_id': deviceId,
      'start_at': startAt.toUtc().toIso8601String(),
      'end_at': endAt.toUtc().toIso8601String(),
    });

    final response = await _send(request);
    final list = _decode(response) as List<dynamic>;

    return list
        .map(
          (item) => NearbyCommunication.fromJson(
            item as Map<String, dynamic>,
          ),
        )
        .toList();
  }

  /// シール一覧を取得する
  static Future<List<Seal>> fetchSeals() async {
    final response = await http
        .get(
          Uri.parse('$baseUrl/users/seals'),
          headers: await _getHeaders(),
        )
        .timeout(_timeout);

    final list = _decode(response) as List<dynamic>;

    return list
        .map(
          (item) => Seal.fromJson(
            item as Map<String, dynamic>,
          ),
        )
        .toList();
  }

  /// 子機が所持しているシールを取得する
  static Future<List<DeviceSeal>> fetchMySeals(
    String deviceId,
  ) async {
    final url = Uri.parse(
      '$baseUrl/users/my_seals',
    ).replace(
      queryParameters: {
        'device_id': deviceId,
      },
    );

    final response = await http
        .get(
          url,
          headers: await _getHeaders(),
        )
        .timeout(_timeout);

    final list = _decode(response) as List<dynamic>;

    return list
        .map(
          (item) => DeviceSeal.fromJson(
            item as Map<String, dynamic>,
          ),
        )
        .toList();
  }

  /// すべての親機情報を取得する
  static Future<List<Gateway>> fetchAllGateways() async {
    final response = await http
        .get(
          Uri.parse('$baseUrl/users/all_gateways'),
          headers: await _getHeaders(),
        )
        .timeout(_timeout);

    final list = _decode(response) as List<dynamic>;

    return list
        .map(
          (item) => Gateway.fromJson(
            item as Map<String, dynamic>,
          ),
        )
        .toList();
  }

  /// シール一覧と所持シールをまとめて取得する
  static Future<SealCollection> fetchSealCollection(
    String deviceId,
  ) async {
    final catalog = await fetchSeals();
    final owned = await fetchMySeals(deviceId);

    return SealCollection(
      catalog: catalog,
      owned: owned,
    );
  }

  /// プッシュ通知トークンを登録する
  static Future<void> registerNotifyToken(
    String token,
  ) async {
    final url = Uri.parse(
      '$baseUrl/users/notify_token',
    ).replace(
      queryParameters: {
        'token': token,
      },
    );

    final response = await http
        .post(
          url,
          headers: await _getHeaders(),
        )
        .timeout(_timeout);

    _decode(response);
  }

  /// プッシュ通知トークンを削除する
  static Future<void> deleteNotifyToken(
    String token,
  ) async {
    final url = Uri.parse(
      '$baseUrl/users/notify_token',
    ).replace(
      queryParameters: {
        'token': token,
      },
    );

    final response = await http
        .delete(
          url,
          headers: await _getHeaders(),
        )
        .timeout(_timeout);

    _decode(response);
  }
}