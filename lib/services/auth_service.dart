import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:get_storage/get_storage.dart';

class AuthService {
  static final _storage = GetStorage();
  static final String baseUrl = dotenv.env['BASE_URL'] ?? '';

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
        try {
          final parts = accessToken.split('.');
          if (parts.length == 3) {
            final payload = parts[1];
            final normalized = base64Url.normalize(payload);
            final decoded = utf8.decode(base64Url.decode(normalized));
            final Map<String, dynamic> payloadMap = jsonDecode(decoded);

            final userId = payloadMap['userId']?.toString();

            if (userId != null) {
              await _storage.write('token', accessToken);
              await _storage.write('refreshToken', refreshToken);
              await _storage.write('user', user);
              await _storage.write('userId', userId);

              print('✅ Authentication successful'); // ✅ แค่บอกว่าสำเร็จ
              print('✅ User: ${user['name']}');
              print('✅ UserId: $userId');
              print('✅ Tokens stored successfully');
            } else {
              print('❌ No userId found in token');
            }
          }
        } catch (e) {
          print('❌ Error processing authentication: $e');
        }
      }
    }

    return data;
  }

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

  /// ดึง token
  static String? getToken() {
    final token = _storage.read('token');
    return token;
  }

  /// ดึง userId
  static String? getUserId() {
    final userId = _storage.read('userId');
    print('📖 getUserId called, returning: ${userId ?? "NULL"}');
    return userId;
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
