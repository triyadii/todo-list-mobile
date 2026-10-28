import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ApiException implements Exception {
  final String message;
  final int? statusCode;

  ApiException(this.message, [this.statusCode]);

  @override
  String toString() => message;
}

class ApiService {
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal();

  static const String _tokenKey = 'jwt_token';
  String? _token;

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString(_tokenKey);
  }

  String? get token => _token;
  bool get isAuthenticated => _token != null && _token!.isNotEmpty;

  Future<void> setToken(String token) async {
    _token = token;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token);
  }

  Future<void> clearToken() async {
    _token = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
  }

  Map<String, String> _getHeaders({bool requiresAuth = true}) {
    final headers = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
    if (requiresAuth && _token != null && _token!.isNotEmpty) {
      headers['Authorization'] = 'Bearer $_token';
    }
    return headers;
  }

  dynamic _handleResponse(http.Response response) {
    dynamic body;
    try {
      body = jsonDecode(response.body);
    } catch (_) {
      throw ApiException(
        'Format respons tidak valid (${response.statusCode})',
        response.statusCode,
      );
    }

    if (response.statusCode >= 200 && response.statusCode < 300) {
      if (body is Map && body.containsKey('data')) {
        return body['data'];
      }
      return body;
    } else {
      String errorMessage = 'Terjadi kesalahan sistem';
      if (body is Map && body.containsKey('message')) {
        errorMessage = body['message'].toString();
      }
      throw ApiException(errorMessage, response.statusCode);
    }
  }

  Future<dynamic> get(String url, {Map<String, String>? queryParams, bool requiresAuth = true}) async {
    try {
      Uri uri = Uri.parse(url);
      if (queryParams != null && queryParams.isNotEmpty) {
        uri = uri.replace(queryParameters: queryParams);
      }

      final response = await http
          .get(
            uri,
            headers: _getHeaders(requiresAuth: requiresAuth),
          )
          .timeout(const Duration(seconds: 30));
      return _handleResponse(response);
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Gagal terhubung ke server: $e');
    }
  }

  Future<dynamic> post(String url, {dynamic data, bool requiresAuth = true}) async {
    try {
      final response = await http
          .post(
            Uri.parse(url),
            headers: _getHeaders(requiresAuth: requiresAuth),
            body: data != null ? jsonEncode(data) : null,
          )
          .timeout(const Duration(seconds: 45));
      return _handleResponse(response);
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Gagal terhubung ke server: $e');
    }
  }

  Future<dynamic> put(String url, {dynamic data, bool requiresAuth = true}) async {
    try {
      final response = await http
          .put(
            Uri.parse(url),
            headers: _getHeaders(requiresAuth: requiresAuth),
            body: data != null ? jsonEncode(data) : null,
          )
          .timeout(const Duration(seconds: 30));
      return _handleResponse(response);
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Gagal terhubung ke server: $e');
    }
  }

  Future<dynamic> delete(String url, {bool requiresAuth = true}) async {
    try {
      final response = await http
          .delete(
            Uri.parse(url),
            headers: _getHeaders(requiresAuth: requiresAuth),
          )
          .timeout(const Duration(seconds: 30));
      return _handleResponse(response);
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Gagal terhubung ke server: $e');
    }
  }
}
