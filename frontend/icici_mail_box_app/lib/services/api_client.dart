import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../models/dashboard_summary.dart';
import '../models/master_option.dart';
import '../models/shipment.dart';

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
    await preferences.setString(_baseUrlKey, _normalizeBaseUrl(value));
  }

  Future<String> getBaseUrl() async {
    final preferences = await SharedPreferences.getInstance();
    return preferences.getString(_baseUrlKey) ?? 'http://localhost:5053';
  }

  Future<DashboardSummary> getDashboardSummary() async {
    final response = await _get('/api/dashboard/summary');

    return DashboardSummary.fromJson(_jsonMap(response));
  }

  Future<List<MasterOption>> getBranches() async {
    final response = await _get('/api/masters/branches');
    return _jsonList(response)
        .map((item) => MasterOption.fromJson(item))
        .toList(growable: false);
  }

  Future<List<MasterOption>> getCustomers() async {
    final response = await _get('/api/masters/customers');
    return _jsonList(response)
        .map((item) => MasterOption.fromJson(item))
        .toList(growable: false);
  }

  Future<List<Shipment>> getShipments({
    required String direction,
    String? search,
  }) async {
    final response = await _get(
      '/api/shipments',
      queryParameters: {
        'direction': direction,
        if (search != null && search.trim().isNotEmpty) 'search': search.trim(),
      },
    );

    return _jsonList(response)
        .map((item) => Shipment.fromJson(item))
        .toList(growable: false);
  }

  Future<Shipment> createShipment(CreateShipmentRequest request) async {
    final response = await _send(
      'POST',
      '/api/shipments',
      body: request.toJson(),
      expectedStatusCodes: const {201},
    );
    return Shipment.fromJson(_jsonMap(response));
  }

  Future<void> updateShipmentStatus({
    required int shipmentId,
    required String status,
  }) async {
    await _send(
      'PATCH',
      '/api/shipments/$shipmentId/status',
      body: {
        'status': status,
        'eventDescription': 'Status changed from the ICICI Mail Box application.',
      },
      expectedStatusCodes: const {204},
    );
  }

  Future<http.Response> _get(
    String path, {
    Map<String, String>? queryParameters,
  }) async {
    final baseUrl = await getBaseUrl();
    final uri = Uri.parse('$baseUrl$path').replace(
      queryParameters: queryParameters,
    );
    final response = await _httpClient
        .get(uri, headers: await _headers())
        .timeout(const Duration(seconds: 15));

    _ensureSuccess(response, const {200});
    return response;
  }

  Future<http.Response> _send(
    String method,
    String path, {
    required Map<String, dynamic> body,
    required Set<int> expectedStatusCodes,
  }) async {
    final baseUrl = await getBaseUrl();
    final uri = Uri.parse('$baseUrl$path');
    final headers = await _headers(includeJsonContentType: true);
    final payload = jsonEncode(body);

    final response = switch (method) {
      'POST' => await _httpClient.post(uri, headers: headers, body: payload),
      'PATCH' => await _httpClient.patch(uri, headers: headers, body: payload),
      _ => throw UnsupportedError('Unsupported HTTP method: $method'),
    };

    _ensureSuccess(response, expectedStatusCodes);
    return response;
  }

  Future<Map<String, String>> _headers({bool includeJsonContentType = false}) async {
    final token = await _secureStorage.read(key: _accessTokenKey);
    return {
      'Accept': 'application/json',
      if (includeJsonContentType) 'Content-Type': 'application/json',
      if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
    };
  }

  Map<String, dynamic> _jsonMap(http.Response response) {
    try {
      return jsonDecode(response.body) as Map<String, dynamic>;
    } on FormatException {
      throw ApiException('The API returned an invalid JSON response.');
    }
  }

  List<Map<String, dynamic>> _jsonList(http.Response response) {
    try {
      return (jsonDecode(response.body) as List<dynamic>)
          .cast<Map<String, dynamic>>();
    } on FormatException {
      throw ApiException('The API returned an invalid JSON response.');
    }
  }

  void _ensureSuccess(http.Response response, Set<int> expectedStatusCodes) {
    if (expectedStatusCodes.contains(response.statusCode)) {
      return;
    }

    var message = 'Request failed (${response.statusCode}).';
    try {
      final payload = jsonDecode(response.body) as Map<String, dynamic>;
      message = payload['detail'] as String? ?? payload['title'] as String? ?? message;
    } on FormatException {
      // Non-JSON errors still receive a useful HTTP-status message.
    }

    throw ApiException(message);
  }

  static String _normalizeBaseUrl(String value) {
    final normalized = value.trim().replaceFirst(RegExp(r'/+$'), '');
    final uri = Uri.tryParse(normalized);
    if (normalized.isEmpty || uri == null || !uri.hasScheme || uri.host.isEmpty) {
      throw ApiException('Enter a complete API URL, such as http://localhost:5053.');
    }

    return normalized;
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
