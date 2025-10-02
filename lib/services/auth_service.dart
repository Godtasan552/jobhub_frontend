import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:get_storage/get_storage.dart';

class AuthService {
  static final _storage = GetStorage();
  static final String baseUrl = dotenv.env['BASE_URL'] ?? '';

  /// Register
  static Future<Map<String, dynamic>> register({
    required String name,
    required String email,
    required String password,
    required String phone,
    required String location,
  }) async {
    final url = Uri.parse('$baseUrl/api/v1/auth/register');

    final response = await http.post(
      url,
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "name": name,
        "email": email,
        "password": password,
        "phone": phone,
        "location": location,
      }),
    );

    return jsonDecode(response.body);
  }

  /// Login
  static Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    final url = Uri.parse('$baseUrl/api/v1/auth/login');

    final response = await http.post(
      url,
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "email": email,
        "password": password,
      }),
    );

    final data = jsonDecode(response.body);

    if (data['success'] == true) {
      final accessToken = data['data']['tokens']['accessToken'];
      final refreshToken = data['data']['tokens']['refreshToken'];
      final user = data['data']['user'];
      final userId = data['data']['user']['id'];

      if (accessToken != null && userId != null) {
        await _storage.write('token', accessToken);
        await _storage.write('refreshToken', refreshToken);
        await _storage.write('userId', userId);
        await _storage.write('user', user);
        
        print('Token saved successfully');
        print('User: ${user['name']} (${user['email']})');
        print('User ID: $userId');
        // ตรวจสอบว่าบันทึกสำเร็จ
        final savedToken = _storage.read('token');
        final savedUserId = _storage.read('userId');
        print('Token stored: ${savedToken != null ? "Yes" : "No"}');
        print('UserId stored: ${savedUserId != null ? savedUserId : "No"}');
      } else {
        print('No accessToken in response');
      }
    }

    return data;
  }

  /// ดึง token ที่เก็บไว้
  static String? getToken() {
    final token = _storage.read('token');
    print('📖 getToken called, returning: ${token != null ? "Token exists" : "NULL"}');
    return token;
  }

  /// ดึง refresh token
  static String? getRefreshToken() {
    return _storage.read('refreshToken');
  }

  /// ดึงข้อมูล User
  static Map<String, dynamic>? getUser() {
    return _storage.read('user');
  }

  /// logout
  static Future<void> logout() async {
    await _storage.erase();
    print('🗑️ Storage cleared');
  }
}