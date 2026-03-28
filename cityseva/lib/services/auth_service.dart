import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/complaint_model.dart';

class AuthService {
  static const _baseUrl = 'https://cityseva-backend.onrender.com/api/auth';

  static Map<String, String> get _headers => {
        'Content-Type': 'application/json',
      };

  // Register
  static Future<AuthResult> register({
    required String name,
    required String email,
    required String password,
    required String phone,
    required String role,
  }) async {
    try {
      final res = await http
          .post(
            Uri.parse('$_baseUrl/register'),
            headers: _headers,
            body: jsonEncode({
              'name': name,
              'email': email,
              'password': password,
              'phone': phone,
              'role': role,
            }),
          )
          .timeout(const Duration(seconds: 15));

      final data = jsonDecode(res.body);

      if (res.statusCode == 201) {
        await _saveToken(data['token']);
        return AuthResult(
          success: true,
          user: UserModel.fromMap(data['user']),
          token: data['token'],
        );
      } else {
        return AuthResult(success: false, message: data['message']);
      }
    } catch (e) {
      return AuthResult(success: false, message: 'Network error. Please check your connection.');
    }
  }

  // Login
  static Future<AuthResult> login({
    required String email,
    required String password,
  }) async {
    try {
      final res = await http
          .post(
            Uri.parse('$_baseUrl/login'),
            headers: _headers,
            body: jsonEncode({'email': email, 'password': password}),
          )
          .timeout(const Duration(seconds: 15));

      final data = jsonDecode(res.body);

      if (res.statusCode == 200) {
        await _saveToken(data['token']);
        return AuthResult(
          success: true,
          user: UserModel.fromMap(data['user']),
          token: data['token'],
        );
      } else {
        return AuthResult(success: false, message: data['message']);
      }
    } catch (e) {
      return AuthResult(success: false, message: 'Network error. Please check your connection.');
    }
  }

  // Verify saved token on app start
  static Future<AuthResult> verifyToken() async {
    try {
      final token = await getToken();
      if (token == null) return AuthResult(success: false, message: 'No token');

      final res = await http
          .get(
            Uri.parse('$_baseUrl/verify'),
            headers: {..._headers, 'Authorization': 'Bearer $token'},
          )
          .timeout(const Duration(seconds: 10));

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        return AuthResult(
          success: true,
          user: UserModel.fromMap(data['user']),
          token: token,
        );
      }
      await clearToken();
      return AuthResult(success: false, message: 'Session expired');
    } catch (_) {
      return AuthResult(success: false, message: 'Network error');
    }
  }

  static Future<void> _saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('auth_token', token);
  }

  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('auth_token');
  }

  static Future<void> clearToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
  }
}

class AuthResult {
  final bool success;
  final UserModel? user;
  final String? token;
  final String? message;

  AuthResult({required this.success, this.user, this.token, this.message});
}
