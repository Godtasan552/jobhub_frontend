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
      // เก็บ token ลง storage
      _storage.write('token', data['data']['token']);
      _storage.write('user', data['data']['user']);
    }

    return data;
  }

  /// ดึง token ที่เก็บไว้
  static String? getToken() {
    return _storage.read('token');
  }

  /// logout
  static void logout() {
    _storage.erase();
  }
}
      