import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../models/dashboard_summary.dart';

class ApiClient {
  ApiClient({http.Client? httpClient, FlutterSecureStorage? secureStorage})
    : _httpClient = httpClient ?? http.Client(),
      _secureStorage = secureStorage ?? const FlutterSecureStorage();

  static const _baseUrlKey = 'api_base_url';
  static const _accessTokenKey = 'access_token';

  final http.Client _httpClient;
  final FlutterSecureStorage _secureStorage;

  Future<void> saveBaseUrl(String value) async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(_baseUrlKey, value);
  }

  Future<DashboardSummary> getDashboardSummary() async {
    final preferences = await SharedPreferences.getInstance();
    final baseUrl =
        preferences.getString(_baseUrlKey) ?? 'http://localhost:5000';
    final token = await _secureStorage.read(key: _accessTokenKey);
    final response = await _httpClient.get(
      Uri.parse('$baseUrl/api/dashboard/summary'),
      headers: {
        'Accept': 'application/json',
        if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode != 200) {
      throw ApiException('Dashboard request failed (${response.statusCode}).');
    }

    return DashboardSummary.fromJson(
      jsonDecode(response.body) as Map<String, dynamic>,
    );
  }

  Future<void> saveAccessToken(String token) =>
      _secureStorage.write(key: _accessTokenKey, value: token);

  Future<void> clearSession() => _secureStorage.delete(key: _accessTokenKey);
}

class ApiException implements Exception {
  ApiException(this.message);

  final String message;

  @override
  String toString() => message;
}
