import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import 'models/device.dart';
import 'models/gateway.dart';
import 'models/nearby_communication.dart';
import 'models/seal.dart';
import 'models/user.dart' as app_models;
import 'app_config.dart';
import 'demo_data.dart';

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

  /// 子機のひも付けと表示名の保存を一続きで行う。
  ///
  /// 以前の登録処理で「ひも付けだけ成功、名前更新だけ失敗」した子機も、
  /// 自分の一覧に存在することを確認してから名前更新を再開できる。
  static Future<void> registerChildWithName({
    required String deviceId,
    required String name,
  }) async {
    final normalizedId = deviceId.trim();
    try {
      await registerChild(normalizedId);
    } on ApiException catch (registerError) {
      bool alreadyMine;
      try {
        final devices = await fetchUserDevices();
        alreadyMine = devices.any(
          (device) => device.id.trim().toLowerCase() ==
              normalizedId.toLowerCase(),
        );
      } catch (_) {
        throw registerError;
      }
      if (!alreadyMine) throw registerError;
    }

    await updateChildName(deviceId: normalizedId, name: name.trim());
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
    if (AppConfig.useDemoData) return DemoData.devices();
    final response = await http
        .get(
          Uri.parse('$baseUrl/users/devices'),
          headers: await _getHeaders(),
        )
        .timeout(_timeout);

    final list = _decode(response) as List<dynamic>;

    final devices = list
        .map(
          (item) => Device.fromJson(
            item as Map<String, dynamic>,
          ),
        )
        .toList();

    if (!AppConfig.useDemoData) return devices;
    final displayDevices = devices
        .map((device) => device.copyWith(
              coins: DemoData.coins,
              battery: DemoData.battery,
            ))
        .toList();
    if (!displayDevices.any((device) => device.name == 'たろう')) {
      displayDevices.add(
        Device(
          id: 'sample-device-taro',
          name: 'たろう',
          coins: DemoData.coins,
          battery: 76,
          lastTimestamp: DateTime.now().toUtc().toIso8601String(),
        ),
      );
    }
    return displayDevices;
  }

  /// 子機のすれ違い履歴を取得する
  static Future<List<NearbyCommunication>>
      fetchNearbyCommunications({
    required String deviceId,
    required DateTime startAt,
    required DateTime endAt,
  }) async {
    if (AppConfig.useDemoData) {
      final seals = await fetchSeals();
      return DemoData.nearbyCommunications(deviceId, seals);
    }
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
    if (AppConfig.useDemoData) {
      return <Seal>[
        ...DemoData.seals,
        DemoData.neighborhoodAssociationChairSeal,
        ...DemoData.originalSeals,
      ];
    }
    final response = await http
        .get(
          Uri.parse('$baseUrl/users/seals'),
          headers: await _getHeaders(),
        )
        .timeout(_timeout);

    final list = _decode(response) as List<dynamic>;

    final seals = list
        .map(
          (item) => Seal.fromJson(
            item as Map<String, dynamic>,
          ),
        )
        .toList();

    return seals;
  }

  /// 親機が配布するオリジナルシールを登録する。
  static Future<Seal> addOriginalSeal({
    required String name,
    required String description,
    required int rarity,
    required Uint8List imageBytes,
    required String owner,
    String imageMimeType = 'image/png',
  }) async {
    final encodedImage = base64Encode(imageBytes);
    if (AppConfig.useDemoData) {
      return DemoData.addOriginalSeal(
        name: name,
        description: description,
        rarity: rarity,
        imageDataUrl: 'data:$imageMimeType;base64,$encodedImage',
      );
    }
    final response = await http
        .post(
          Uri.parse('$baseUrl/users/add_original_seal'),
          headers: await _getHeaders(),
          body: jsonEncode({
            'name': name,
            'description': description,
            'rarity': rarity,
            'image': encodedImage,
            'owner': owner,
          }),
        )
        .timeout(_timeout);
    return Seal.fromJson(_decode(response) as Map<String, dynamic>);
  }

  static Future<List<Seal>> fetchOriginalSeals(String gatewayId) async {
    if (AppConfig.useDemoData) return List<Seal>.from(DemoData.originalSeals);
    final url = Uri.parse('$baseUrl/users/original_seals').replace(
      queryParameters: {'gateway_id': gatewayId},
    );
    final response = await http
        .get(url, headers: await _getHeaders())
        .timeout(_timeout);
    final list = _decode(response) as List<dynamic>;
    return list
        .map((item) => Seal.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  /// 現在開催中のシールパック一覧を取得する。
  static Future<List<SealPack>> fetchSealPacks() async {
    if (AppConfig.useDemoData) return DemoData.sealPacks;
    final response = await http
        .get(
          Uri.parse('$baseUrl/users/seal_packs'),
          headers: await _getHeaders(),
        )
        .timeout(_timeout);

    final list = _decode(response) as List<dynamic>;
    return list
        .map((item) => SealPack.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  /// サーバー側でシールパックを抽選する。
  static Future<List<Seal>> playSealPack({
    required String packId,
    required int count,
    required String deviceId,
  }) async {
    if (AppConfig.useDemoData) {
      final pack = DemoData.sealPacks.firstWhere((item) => item.id == packId);
      if (!DemoData.spendCoins(deviceId, pack.oncePrice)) {
        throw const ApiException('コインがたりません。');
      }
      final rare = DemoData.seals.where((seal) => seal.rarity == 1).toList();
      final normal = DemoData.seals.where((seal) => seal.rarity == 0).toList();
      final source = packId == 'demo-pack-special'
          ? <Seal>[rare.first, ...normal]
          : DemoData.seals;
      return List<Seal>.generate(
        count,
        (index) => source[index % source.length],
      );
    }
    final url = Uri.parse('$baseUrl/users/seal_pack').replace(
      queryParameters: {
        'pack_id': packId,
        'count': count.toString(),
        'device_id': deviceId,
      },
    );

    final response = await http
        .post(url, headers: await _getHeaders())
        .timeout(_timeout);
    final list = _decode(response) as List<dynamic>;
    return list
        .map((item) => Seal.fromJson(item as Map<String, dynamic>))
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
    if (AppConfig.useDemoData) {
      return DemoData.gatewaysFor(await fetchSeals());
    }
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

  /// ログイン中の親機アカウントに登録された親機一覧を取得する。
  static Future<List<Gateway>> fetchUserGateways() async {
    if (AppConfig.useDemoData) {
      return DemoData.gatewaysFor(await fetchSeals());
    }
    final response = await http
        .get(
          Uri.parse('$baseUrl/users/gateways'),
          headers: await _getHeaders(),
        )
        .timeout(_timeout);

    final list = _decode(response) as List<dynamic>;
    return list
        .map((item) => Gateway.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  /// 親機名・配布シール・設置位置を更新する。
  static Future<void> updateGateway({
    required String gatewayId,
    required String name,
    required String distributeSealId,
    required double latitude,
    required double longitude,
  }) async {
    if (AppConfig.useDemoData) {
      DemoData.updateGateway(
        gatewayId: gatewayId,
        name: name,
        distributeSealId: distributeSealId,
        latitude: latitude,
        longitude: longitude,
      );
      return;
    }
    final response = await http
        .patch(
          Uri.parse('$baseUrl/users/gateway'),
          headers: await _getHeaders(),
          body: jsonEncode({
            'device_id': gatewayId,
            'name': name,
            'distribute_seal_id': distributeSealId,
            'latitude': latitude,
            'longitude': longitude,
          }),
        )
        .timeout(_timeout);
    _decode(response);
  }

  /// シール一覧と所持シールをまとめて取得する
  static Future<SealCollection> fetchSealCollection(
    String deviceId,
  ) async {
    final catalog = await fetchSeals();
    final owned = AppConfig.useDemoData
        ? DemoData.ownedSealsForCatalog(deviceId, catalog)
        : await fetchMySeals(deviceId);

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
