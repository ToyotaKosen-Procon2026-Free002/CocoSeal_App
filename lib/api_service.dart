import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart';

class ApiService {
  static const String baseUrl = "https://coco-seal.mydns.jp";

  static Future<Map<String, String>> _getHeaders() async {
    final idToken = await FirebaseAuth.instance.currentUser?.getIdToken();
    return {
      'Content-Type': 'application/json',
      if (idToken != null) 'Authorization': 'Bearer $idToken',
    };
  }

  static Future<Map<String, dynamic>?> fetchUserProfile() async {
    final url = Uri.parse('$baseUrl/users/me');
    final headers = await _getHeaders();

    final response = await http.get(url, headers: headers);

    if (response.statusCode == 200) {
      // UTF-8でデコードして文字化けを防止
      final decodedBody = utf8.decode(response.bodyBytes);
      return jsonDecode(decodedBody) as Map<String, dynamic>;
    } else {
      print('API Error: ${response.statusCode} - ${response.body}');
      return null;
    }
  }

//　新規会員登録
  static Future<Map<String, dynamic>?> updateUserProfile(String? displayName, String? email, String? role) async {
    final url = Uri.parse('$baseUrl/users/me');
    final headers = await _getHeaders();

    final Map<String, dynamic> bodyData = {};
    if (displayName != null) bodyData['display_name'] = displayName;
    if (email != null) bodyData['email'] = email;
    if (role != null) bodyData['roll'] = role;

    final response = await http.patch(url, headers: headers, body: jsonEncode(bodyData));

    if (response.statusCode == 200) {
      // UTF-8でデコードして文字化けを防止
      final decodedBody = utf8.decode(response.bodyBytes);
      return jsonDecode(decodedBody) as Map<String, dynamic>;
    } else {
      print('API Error: ${response.statusCode} - ${response.body}');
      return null;
    }
  }

/// 子機の登録
  static Future<bool> registerChild(String deviceId) async {
    final url = Uri.parse('$baseUrl/users/device').replace(
      queryParameters: {
        'device_id': deviceId,
      },
    );
    final headers = await _getHeaders();

    try {
      final response = await http.post(
        url,
        headers: headers,
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return true;
      } else {
        print('API Error: ${response.statusCode} - ${response.body}');
        return false;
      }
    } catch (e) {
      print('Network Error: $e');
      return false;
    }
  }

  /// ログインユーザーの登録済みデバイス一覧を取得
  static Future<List<Map<String, dynamic>>?> fetchUserDevices() async {
    final url = Uri.parse('$baseUrl/users/devices');
    final headers = await _getHeaders();

    try {
      final response = await http.get(url, headers: headers);

      if (response.statusCode == 200) {
        final decodedBody = utf8.decode(response.bodyBytes);
        final List<dynamic> list = jsonDecode(decodedBody);
        return list.cast<Map<String, dynamic>>();
      } else {
        print('API Error: ${response.statusCode} - ${response.body}');
        return null;
      }
    } catch (e) {
      print('Network Error: $e');
      return null;
    }
  }
}