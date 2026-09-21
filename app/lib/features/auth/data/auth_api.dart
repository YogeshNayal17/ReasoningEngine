import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;

import '../../../core/config/app_environment.dart';
import 'models/auth_user.dart';

class AuthApiException implements Exception {
  const AuthApiException(this.message);
  final String message;
  @override
  String toString() => message;
}

class AuthApi {
  AuthApi(this._baseUrl);
  final String _baseUrl;

  Future<AuthUser> register({required String name, required String email, required String password}) =>
      _post('/auth/register', {'name': name, 'email': email, 'password': password});

  Future<AuthUser> login({required String email, required String password}) =>
      _post('/auth/login', {'email': email, 'password': password});

  Future<UsageSummary> usage(String token) async {
    final response = await http.get(
      Uri.parse('$_baseUrl/auth/usage'),
      headers: {'Authorization': 'Bearer $token'},
    );
    final json = jsonDecode(response.body) as Map<String, dynamic>;
    if (response.statusCode != 200) throw AuthApiException(json['detail'] as String? ?? 'Error');
    return UsageSummary.fromJson(json);
  }

  Future<void> upgrade(String token) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/auth/upgrade'),
      headers: {'Authorization': 'Bearer $token'},
    );
    if (response.statusCode != 200) {
      final json = jsonDecode(response.body) as Map<String, dynamic>;
      throw AuthApiException(json['detail'] as String? ?? 'Upgrade failed');
    }
  }

  Future<AuthUser> _post(String path, Map<String, dynamic> body) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl$path'),
        headers: const {'Content-Type': 'application/json'},
        body: jsonEncode(body),
      );
      final json = jsonDecode(response.body) as Map<String, dynamic>;
      if (response.statusCode != 200) throw AuthApiException(json['detail'] as String? ?? 'Request failed');
      return AuthUser.fromJson(json);
    } on AuthApiException {
      rethrow;
    } catch (_) {
      throw const AuthApiException('Could not reach the server. Check your connection.');
    }
  }
}

final authApiProvider = Provider<AuthApi>((ref) {
  final env = ref.watch(appEnvironmentProvider);
  return AuthApi(env.apiBaseUrl);
});
