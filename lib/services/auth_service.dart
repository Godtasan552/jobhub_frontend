import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:get_storage/get_storage.dart';
import 'package:jwt_decode/jwt_decode.dart';

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
      body: jsonEncode({"email": email, "password": password}),
    );

    final data = jsonDecode(response.body);

if (data['success'] == true) {
  final accessToken = data['data']['tokens']['accessToken'];
  final refreshToken = data['data']['tokens']['refreshToken'];
  final user = data['data']['user'];
  
  if (accessToken != null) {
    // Decode JWT เพื่อดึง userId
    try {
      Map<String, dynamic> payload = Jwt.parseJwt(accessToken);
      final userId = payload['userId']?.toString();
      
      print('🔓 Decoded JWT payload: $payload');
      print('🔑 User ID from JWT: $userId');
      
      if (userId != null) {
        await _storage.write('token', accessToken);
        await _storage.write('refreshToken', refreshToken);
        await _storage.write('user', user);
        await _storage.write('userId', userId); // ✅ บันทึก userId จาก JWT
        
        print('✅ Token saved successfully');
        print('✅ UserId saved: $userId');
        print('👤 User: ${user['name']} (${user['email']})');
        
        // ตรวจสอบ
        final savedUserId = _storage.read('userId');
        print('📖 UserId stored: ${savedUserId != null ? "Yes ($savedUserId)" : "No"}');
      } else {
        print('❌ No userId in JWT token');
      }
    } catch (e) {
      print('❌ Error decoding JWT: $e');
    }
  }
}

    return data;
  }

  /// ดึง token ที่เก็บไว้
  static String? getToken() {
    final token = _storage.read('token');
    print(
      '📖 getToken called, returning: ${token != null ? "Token exists" : "NULL"}',
    );
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
