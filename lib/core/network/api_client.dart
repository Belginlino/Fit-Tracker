import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../errors/failures.dart';

class ApiClient {
  static const String _tokenKey = 'fittrack_auth_token';
  String? _authToken;

  ApiClient._();
  static final ApiClient instance = ApiClient._();

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    _authToken = prefs.getString(_tokenKey);
  }

  String? get token => _authToken;
  bool get isAuthenticated => _authToken != null;

  Future<void> setToken(String? token) async {
    _authToken = token;
    final prefs = await SharedPreferences.getInstance();
    if (token != null) {
      await prefs.setString(_tokenKey, token);
    } else {
      await prefs.remove(_tokenKey);
    }
  }

  Map<String, String> _buildHeaders({bool isJson = true}) {
    final headers = <String, String>{};
    if (isJson) {
      headers['Content-Type'] = 'application/json';
    }
    if (_authToken != null) {
      headers['Authorization'] = 'Bearer $_authToken';
    }
    return headers;
  }

  Future<dynamic> get(String url) async {
    try {
      final response = await http.get(Uri.parse(url), headers: _buildHeaders());
      return _processResponse(response);
    } catch (e) {
      if (e is Failure) rethrow;
      throw NetworkFailure(e.toString());
    }
  }

  Future<dynamic> post(String url, {Map<String, dynamic>? body}) async {
    try {
      final response = await http.post(
        Uri.parse(url),
        headers: _buildHeaders(),
        body: body != null ? jsonEncode(body) : null,
      );
      return _processResponse(response);
    } catch (e) {
      if (e is Failure) rethrow;
      throw NetworkFailure(e.toString());
    }
  }

  Future<dynamic> postBytes(String url, Uint8List bytes,
      {String contentType = 'image/jpeg'}) async {
    try {
      final headers = _buildHeaders(isJson: false);
      headers['Content-Type'] = contentType;

      final response = await http.post(
        Uri.parse(url),
        headers: headers,
        body: bytes,
      );
      return _processResponse(response);
    } catch (e) {
      if (e is Failure) rethrow;
      throw NetworkFailure(e.toString());
    }
  }

  Future<dynamic> patch(String url, {Map<String, dynamic>? body}) async {
    try {
      final response = await http.patch(
        Uri.parse(url),
        headers: _buildHeaders(),
        body: body != null ? jsonEncode(body) : null,
      );
      return _processResponse(response);
    } catch (e) {
      if (e is Failure) rethrow;
      throw NetworkFailure(e.toString());
    }
  }

  Future<dynamic> delete(String url) async {
    try {
      final response =
          await http.delete(Uri.parse(url), headers: _buildHeaders());
      return _processResponse(response);
    } catch (e) {
      if (e is Failure) rethrow;
      throw NetworkFailure(e.toString());
    }
  }

  dynamic _processResponse(http.Response response) {
    if (response.statusCode == 401) {
      setToken(null);
      throw const AuthFailure('Session expired. Please sign in again.');
    }

    try {
      final json = jsonDecode(response.body) as Map<String, dynamic>;
      if (json['success'] == true) {
        return json['data'];
      } else {
        final error = json['error'] as Map<String, dynamic>?;
        final message = error?['message'] as String? ?? 'Request failed';
        throw DatabaseFailure(message);
      }
    } catch (e) {
      if (e is Failure) rethrow;
      if (response.statusCode >= 400) {
        throw DatabaseFailure('Server error (${response.statusCode})');
      }
      return null;
    }
  }
}
