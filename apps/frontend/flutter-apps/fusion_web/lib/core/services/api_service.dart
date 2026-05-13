import 'dart:convert';
import 'dart:developer';
import 'package:http/http.dart' as http;
import 'package:fusion_web/core/config/environment_config.dart';

class ApiService {
  static String get baseUrl => EnvironmentConfig.apiBaseUrl;

  final http.Client _client;
  String? _bearerToken;

  ApiService({http.Client? client}) : _client = client ?? http.Client();

  void setBearerToken(String token) {
    _bearerToken = token;
    log('API Service: Bearer token set (length: ${token.length})');
    log('API Service: Token preview: ${token.substring(0, 50)}...');
  }

  void clearToken() {
    _bearerToken = null;
    log('🔐 API Service: Bearer token cleared');
  }

  void _handleUnauthorized() {
    // Clear the expired/invalid token
    clearToken();

    // Import and redirect to login will be handled by the calling code
    // throwing the exception will trigger error handling in the UI layer
    log('🔄 API Service: Cleared token due to 401 Unauthorized');
  }

  Map<String, String> get _headers {
    final headers = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };

    if (_bearerToken != null) {
      headers['Authorization'] = 'Bearer $_bearerToken';
    }

    return headers;
  }

  Future<Map<String, dynamic>> get(String endpoint) async {
    try {
      final url = Uri.parse('$baseUrl$endpoint');
      log('API GET Request: $url');
      log('API Headers: ${_headers.keys.join(', ')}');
      log('Has Authorization: ${_headers.containsKey('Authorization')}');

      final response = await _client.get(url, headers: _headers);
      log('API Response Status: ${response.statusCode}');

      return _handleResponse(response);
    } catch (e) {
      log('API GET Error: $e');
      throw ApiException('GET request failed: $e');
    }
  }

  Future<Map<String, dynamic>> post(
    String endpoint,
    Map<String, dynamic> data,
  ) async {
    try {
      final url = Uri.parse('$baseUrl/$endpoint');
      final response = await _client.post(
        url,
        headers: _headers,
        body: jsonEncode(data),
      );

      return _handleResponse(response);
    } catch (e) {
      throw ApiException('POST request failed: $e');
    }
  }

  Future<Map<String, dynamic>> put(
    String endpoint,
    Map<String, dynamic> data,
  ) async {
    try {
      final url = Uri.parse('$baseUrl/$endpoint');
      final response = await _client.put(
        url,
        headers: _headers,
        body: jsonEncode(data),
      );

      return _handleResponse(response);
    } catch (e) {
      throw ApiException('PUT request failed: $e');
    }
  }

  Future<void> delete(String endpoint) async {
    try {
      final url = Uri.parse('$baseUrl/$endpoint');
      final response = await _client.delete(url, headers: _headers);

      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw ApiException(
          'Delete request failed: ${response.statusCode} ${response.reasonPhrase}',
        );
      }
    } catch (e) {
      throw ApiException('DELETE request failed: $e');
    }
  }

  Future<Map<String, dynamic>> patch(
    String endpoint,
    Map<String, dynamic> data,
  ) async {
    try {
      final url = Uri.parse('$baseUrl/$endpoint');

      log('API PATCH Request: $url');
      log('PATCH Body: $data');

      final response = await _client.patch(
        url,
        headers: _headers,
        body: jsonEncode(data),
      );

      log('API PATCH Status: ${response.statusCode}');

      return _handleResponse(response);
    } catch (e) {
      throw ApiException('PATCH request failed: $e');
    }
  }

  Map<String, dynamic> _handleResponse(http.Response response) {
    log('Response body: ${response.body}');

    if (response.statusCode >= 200 && response.statusCode < 300) {
      if (response.body.isEmpty) {
        return {};
      }

      try {
        final decoded = jsonDecode(response.body);
        if (decoded == null) {
          return {};
        }
        return decoded as Map<String, dynamic>;
      } catch (e) {
        log('JSON decode error: $e');
        return {};
      }
    } else {
      String errorMessage =
          'Request failed: ${response.statusCode} ${response.reasonPhrase}';

      try {
        final errorBody = jsonDecode(response.body) as Map<String, dynamic>;
        if (errorBody.containsKey('message')) {
          errorMessage = errorBody['message'] as String;
        } else if (errorBody.containsKey('error')) {
          errorMessage = errorBody['error'] as String;
        }
      } catch (e) {
        // If error body is not valid JSON, use the default error message
      }

      // Handle 401 Unauthorized - token expired/invalid
      if (response.statusCode == 401) {
        log('🚨 API Service: 401 Unauthorized - Token expired/invalid');
        _handleUnauthorized();
      }

      throw ApiException(errorMessage, statusCode: response.statusCode);
    }
  }

  void dispose() {
    _client.close();
  }
}

class ApiException implements Exception {
  final String message;
  final int? statusCode;

  ApiException(this.message, {this.statusCode});

  @override
  String toString() =>
      'ApiException: $message${statusCode != null ? ' (Status: $statusCode)' : ''}';
}
