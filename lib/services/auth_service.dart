import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../config/api_config.dart';
import '../models/user_model.dart';
import 'api_service.dart';
import 'notification_service.dart';

class AuthService extends ChangeNotifier {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  final ApiService _apiService = ApiService();
  UserModel? _currentUser;
  bool _isLoading = false;

  UserModel? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  bool get isAuthenticated => _apiService.isAuthenticated && _currentUser != null;

  static const String _userKey = 'current_user_data';

  Future<void> init() async {
    await _apiService.init();
    final prefs = await SharedPreferences.getInstance();
    final userJson = prefs.getString(_userKey);
    if (userJson != null) {
      try {
        _currentUser = UserModel.fromJson(jsonDecode(userJson));
      } catch (_) {}
    }

    if (_apiService.isAuthenticated) {
      try {
        await getProfile();
      } catch (_) {}
    }
    notifyListeners();
  }

  Future<AuthResponse> login({
    required String email,
    required String password,
    String? fcmToken,
  }) async {
    _isLoading = true;
    notifyListeners();
    try {
      String resolvedFcmToken = fcmToken ?? '';
      if (resolvedFcmToken.isEmpty) {
        try {
          resolvedFcmToken = await NotificationService().getOrFetchFcmToken();
        } catch (_) {}
      }

      final res = await _apiService.post(
        ApiConfig.login,
        data: {
          'email': email.trim(),
          'fcm_token': resolvedFcmToken,
          'password': password,
        },
        requiresAuth: false,
      );

      final authResponse = AuthResponse.fromJson(res);
      await _apiService.setToken(authResponse.token);
      _currentUser = authResponse.user;

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_userKey, jsonEncode(authResponse.user.toJson()));

      if (resolvedFcmToken.isNotEmpty) {
        NotificationService().syncFcmTokenWithBackend(resolvedFcmToken).catchError((_) {});
      }

      return authResponse;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<AuthResponse> register({
    required String name,
    required String email,
    required String password,
    String timezone = 'Asia/Jakarta',
    String? fcmToken,
  }) async {
    _isLoading = true;
    notifyListeners();
    try {
      String resolvedFcmToken = fcmToken ?? '';
      if (resolvedFcmToken.isEmpty) {
        try {
          resolvedFcmToken = await NotificationService().getOrFetchFcmToken();
        } catch (_) {}
      }

      final res = await _apiService.post(
        ApiConfig.register,
        data: {
          'name': name.trim(),
          'email': email.trim(),
          'password': password,
          'timezone': timezone,
          'fcm_token': resolvedFcmToken,
        },
        requiresAuth: false,
      );

      final authResponse = AuthResponse.fromJson(res);
      await _apiService.setToken(authResponse.token);
      _currentUser = authResponse.user;

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_userKey, jsonEncode(authResponse.user.toJson()));

      return authResponse;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<UserModel> getProfile() async {
    final res = await _apiService.get(ApiConfig.userProfile);
    _currentUser = UserModel.fromJson(res);

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_userKey, jsonEncode(_currentUser!.toJson()));
    notifyListeners();
    return _currentUser!;
  }

  Future<UserModel> updateProfile({
    required String name,
    required String timezone,
  }) async {
    _isLoading = true;
    notifyListeners();
    try {
      final res = await _apiService.put(
        ApiConfig.userProfile,
        data: {
          'name': name.trim(),
          'timezone': timezone,
          'fcm_token': _currentUser?.fcmToken ?? '0',
        },
      );
      _currentUser = UserModel.fromJson(res);

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_userKey, jsonEncode(_currentUser!.toJson()));
      return _currentUser!;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> logout() async {
    await _apiService.clearToken();
    _currentUser = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_userKey);
    notifyListeners();
  }
}
