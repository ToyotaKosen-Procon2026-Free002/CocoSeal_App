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
    if (AppConfig.useDemoData) {
      final encodedImage = base64Encode(imageBytes);
      return DemoData.addOriginalSeal(
        name: name,
        description: description,
        rarity: rarity,
        imageDataUrl: 'data:$imageMimeType;base64,$encodedImage',
      );
    }

    // 最新API仕様:
    // name / description / rarity / owner は query parameter
    // image は multipart/form-data の UploadFile
    final url = Uri.parse('$baseUrl/users/add_original_seal').replace(
      queryParameters: {
        'name': name,
        'description': description,
        'rarity': rarity.toString(),
        'owner': owner,
      },
    );

    final request = http.MultipartRequest('POST', url);

    final headers = await _getHeaders();
    // MultipartRequest が boundary 付き Content-Type を自動設定するため、
    // JSON 用 Content-Type は削除する。
    headers.remove('Content-Type');
    request.headers.addAll(headers);

    String extension = 'png';
    if (imageMimeType == 'image/jpeg' || imageMimeType == 'image/jpg') {
      extension = 'jpg';
    } else if (imageMimeType == 'image/webp') {
      extension = 'webp';
    }

    request.files.add(
      http.MultipartFile.fromBytes(
        'image',
        imageBytes,
        filename: 'seal.$extension',
      ),
    );

    final response = await _send(request);
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



  /// 所持シールの状態を更新する。
  /// statusId = 0: 未配置 / 1: シール帳 / 2: 交換ボックス
  static Future<void> updateDeviceSealStatus({
    required String deviceId,
    required String deviceSealId,
    required int statusId,
    int? bookPage,
    double? bookX,
    double? bookY,
    double? bookRotation,
    double? bookScale,
  }) async {
    if (AppConfig.useDemoData) return;

    final response = await http
        .patch(
          Uri.parse('$baseUrl/users/device_seal'),
          headers: await _getHeaders(),
          body: jsonEncode({
            'device_id': deviceId,
            'id': deviceSealId,
            'status_id': statusId,
            'book_page': bookPage ?? 0,
            'book_x': bookX ?? 0,
            'book_y': bookY ?? 0,
            'book_rotation': bookRotation ?? 0,
            'book_scale': bookScale ?? 1,
          }),
        )
        .timeout(_timeout);

    _decode(response);
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



  /// 親機IDをログイン中のユーザーに登録する。

  /// 親機自体は、事前にサーバーへ初回登録されている必要がある。

  static Future<void> registerGateway(String gatewayId) async {

    final normalizedId = gatewayId.trim().toUpperCase();

    if (normalizedId.isEmpty) {

      throw const ApiException('親機IDを入力してください。');

    }



    if (AppConfig.useDemoData) {

      return;

    }



    final url = Uri.parse('$baseUrl/users/gateway').replace(

      queryParameters: {

        'gateway_id': normalizedId,

      },

    );



    debugPrint('=== 親機登録 POST ===');
    debugPrint('gateway_id: $normalizedId');
    debugPrint('POST URL: $url');

    final response = await http

        .post(

          url,

          headers: await _getHeaders(),

        )

        .timeout(_timeout);



    debugPrint('POST status: ${response.statusCode}');
    debugPrint('POST response: ${utf8.decode(response.bodyBytes)}');

    _decode(response);

  }



  /// ログイン中の親機アカウントに登録された親機一覧を取得する。

  static Future<List<Gateway>> fetchUserGateways() async {

    if (AppConfig.useDemoData) {

      return DemoData.gatewaysFor(await fetchSeals());

    }

    final url = Uri.parse('$baseUrl/users/gateways');

    debugPrint('=== 親機一覧 GET ===');
    debugPrint('GET URL: $url');

    final response = await http
        .get(
          url,
          headers: await _getHeaders(),
        )
        .timeout(_timeout);

    debugPrint('GET status: ${response.statusCode}');
    debugPrint('GET response: ${utf8.decode(response.bodyBytes)}');

    final list = _decode(response) as List<dynamic>;

    return list

        .map((item) => Gateway.fromJson(item as Map<String, dynamic>))

        .toList();

  }



  /// 親機名・配布シール・設置位置を更新する。
static Future<void> updateGateway({
  required String gatewayId,
  required String name,
  String? distributeSealId,
  required double latitude,
  required double longitude,
}) async {
  if (AppConfig.useDemoData) {
    DemoData.updateGateway(
      gatewayId: gatewayId,
      name: name,
      distributeSealId: distributeSealId ?? '',
      latitude: latitude,
      longitude: longitude,
    );
    return;
  }

  // 配布シールが設定されていない場合は
  // 空文字ではなく null を送信する
  final normalizedSealId =
      distributeSealId?.trim();

  final body = <String, dynamic>{
    'device_id': gatewayId,
    'name': name,
    'distribute_seal_id':
        normalizedSealId == null ||
                normalizedSealId.isEmpty
            ? null
            : normalizedSealId,
    'latitude': latitude,
    'longitude': longitude,
  };

  // デバッグ用
  debugPrint('=== 親機情報 PATCH ===');
  debugPrint('gateway_id: $gatewayId');
  debugPrint(
    'PATCH URL: $baseUrl/users/gateway',
  );
  debugPrint(
    'PATCH body: ${jsonEncode(body)}',
  );

  final response = await http
      .patch(
        Uri.parse('$baseUrl/users/gateway'),
        headers: await _getHeaders(),
        body: jsonEncode(body),
      )
      .timeout(_timeout);

  // サーバーから返ってきた内容を確認できるようにする
  debugPrint(
    'PATCH status: ${response.statusCode}',
  );
  debugPrint(
    'PATCH response: '
    '${utf8.decode(response.bodyBytes)}',
  );

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


  /// 指定した子機の今週のウィークリーミッションを取得する
  static Future<List<Map<String, dynamic>>> fetchWeeklyMissions(
    String deviceId,
  ) async {
    final url = Uri.parse(
      '$baseUrl/users/missions/weekly',
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

    final decoded = _decode(response);

    if (decoded is! List) {
      throw const ApiException('ウィークリーミッションの取得結果が不正です。');
    }

    return decoded
        .whereType<Map>()
        .map((item) => Map<String, dynamic>.from(item))
        .toList();
  }

  /// 達成済みミッションの報酬を受け取る
  ///
  /// サーバー側でコインが付与されるため、
  /// Flutter側ではコインを直接加算しない。
  static Future<Map<String, dynamic>> claimMissionReward({
    required String deviceId,
    required String missionId,
  }) async {
    final url = Uri.parse(
      '$baseUrl/users/missions/claim',
    );

    final response = await http
        .post(
          url,
          headers: await _getHeaders(),
          body: jsonEncode({
            'device_id': deviceId,
            'mission_id': missionId,
          }),
        )
        .timeout(_timeout);

    final decoded = _decode(response);

    if (decoded is! Map) {
      throw const ApiException('ミッション報酬の受け取り結果が不正です。');
    }

    return Map<String, dynamic>.from(decoded);
  }


}
