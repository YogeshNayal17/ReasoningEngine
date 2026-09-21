import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../data/auth_api.dart';
import '../../data/models/auth_user.dart';

const _tokenKey = 'auth_token';
const _nameKey = 'user_name';
const _emailKey = 'user_email';
const _isNerdKey = 'is_nerd';
const _userIdKey = 'user_id';

class AuthState {
  const AuthState({this.user, this.isLoading = false, this.error});
  final AuthUser? user;
  final bool isLoading;
  final String? error;

  bool get isAuthenticated => user != null;

  AuthState copyWith({AuthUser? user, bool? isLoading, String? error, bool clearUser = false}) => AuthState(
        user: clearUser ? null : (user ?? this.user),
        isLoading: isLoading ?? this.isLoading,
        error: error,
      );
}

class AuthNotifier extends Notifier<AuthState> {
  final _storage = const FlutterSecureStorage();

  @override
  AuthState build() {
    Future.microtask(_restore);
    return const AuthState(isLoading: true);
  }

  Future<void> _restore() async {
    try {
      final token = await _storage.read(key: _tokenKey);
      if (token == null) { state = const AuthState(); return; }
      final prefs = await SharedPreferences.getInstance();
      final user = AuthUser(
        token: token,
        userId: prefs.getInt(_userIdKey) ?? 0,
        name: prefs.getString(_nameKey) ?? '',
        email: prefs.getString(_emailKey) ?? '',
        isNerd: prefs.getBool(_isNerdKey) ?? false,
      );
      state = AuthState(user: user);
    } catch (_) {
      state = const AuthState();
    }
  }

  Future<void> _save(AuthUser user) async {
    await _storage.write(key: _tokenKey, value: user.token);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_userIdKey, user.userId);
    await prefs.setString(_nameKey, user.name);
    await prefs.setString(_emailKey, user.email);
    await prefs.setBool(_isNerdKey, user.isNerd);
  }

  Future<void> register({required String name, required String email, required String password}) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final user = await ref.read(authApiProvider).register(name: name, email: email, password: password);
      await _save(user);
      state = AuthState(user: user);
    } on AuthApiException catch (e) {
      state = state.copyWith(isLoading: false, error: e.message);
    }
  }

  Future<void> login({required String email, required String password}) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final user = await ref.read(authApiProvider).login(email: email, password: password);
      await _save(user);
      state = AuthState(user: user);
    } on AuthApiException catch (e) {
      state = state.copyWith(isLoading: false, error: e.message);
    }
  }

  Future<void> upgrade() async {
    final token = state.user?.token;
    if (token == null) return;
    await ref.read(authApiProvider).upgrade(token);
    final updated = AuthUser(
      token: token,
      userId: state.user!.userId,
      name: state.user!.name,
      email: state.user!.email,
      isNerd: true,
    );
    await _save(updated);
    state = AuthState(user: updated);
  }

  Future<void> logout() async {
    await _storage.delete(key: _tokenKey);
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    state = const AuthState();
  }
}

final authProvider = NotifierProvider<AuthNotifier, AuthState>(AuthNotifier.new);
