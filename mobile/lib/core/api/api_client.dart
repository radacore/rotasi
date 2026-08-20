import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../constants.dart';

/// Client HTTP ke backend ROTASI (endpoint `/api/v1/*`).
class ApiClient {
  ApiClient({http.Client? httpClient}) : _http = httpClient ?? http.Client();

  static const _tokenKey = 'device_token';
  static const _deviceUuidKey = 'device_uuid';

  final http.Client _http;

  String? _token;

  /// Token Sanctum perangkat, dibaca dari penyimpanan lokal.
  Future<String?> token() async {
    if (_token != null) return _token;
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_tokenKey);
  }

  /// Registrasi perangkat ke backend. Memicu `POST /api/v1/device/register`.
  Future<void> registerDevice({
    required String androidId,
    required String appVersion,
    String? deviceName,
  }) async {
    final res = await _http.post(
      Uri.parse('${AppConfig.apiBaseUrl}${ApiEndpoints.deviceRegister}'),
      headers: _jsonHeaders(),
      body: jsonEncode({
        'android_id': androidId,
        'app_version': appVersion,
        'device_name': deviceName,
      }),
    );

    if (res.statusCode >= 300) {
      throw ApiException('Registrasi perangkat gagal (${res.statusCode})');
    }

    final body = jsonDecode(res.body) as Map<String, dynamic>;
    final data = body['data'] as Map<String, dynamic>;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_deviceUuidKey, data['device_uuid'] as String);
    await prefs.setString(_tokenKey, data['token'] as String);
    _token = data['token'] as String;
  }

  Future<http.Response> get(
    String path, {
    Map<String, String>? query,
  }) async {
    return _request('GET', path, query: query);
  }

  Future<http.Response> post(
    String path, {
    Map<String, dynamic>? body,
  }) async {
    return _request('POST', path, body: body);
  }

  Future<http.Response> put(
    String path, {
    Map<String, dynamic>? body,
  }) async {
    return _request('PUT', path, body: body);
  }

  Future<http.Response> _request(
    String method,
    String path, {
    Map<String, String>? query,
    Map<String, dynamic>? body,
  }) async {
    final uri = Uri.parse('${AppConfig.apiBaseUrl}$path')
        .replace(queryParameters: query);
    final headers = _jsonHeaders();
    final authToken = await token();
    if (authToken != null) headers['Authorization'] = 'Bearer $authToken';

    late http.Response res;
    switch (method) {
      case 'GET':
        res = await _http.get(uri, headers: headers);
      case 'POST':
        res = await _http.post(
          uri,
          headers: headers,
          body: body == null ? null : jsonEncode(body),
        );
      case 'PUT':
        res = await _http.put(
          uri,
          headers: headers,
          body: body == null ? null : jsonEncode(body),
        );
      default:
        throw ArgumentError('Method tidak didukung: $method');
    }
    return res;
  }

  Map<String, String> _jsonHeaders() => {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
      };
}

class ApiException implements Exception {
  ApiException(this.message);
  final String message;

  @override
  String toString() => message;
}
