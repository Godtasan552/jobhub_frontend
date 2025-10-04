// lib/services/wallet_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'auth_service.dart';

class WalletService {
  static final String baseUrl = dotenv.env['BASE_URL'] ?? '';

  static Future<Map<String, dynamic>> jobPayment({
    required String jobId,
    required String workerId,
    required double amount,
  }) async {
    try {
      final token = AuthService.getToken();
      if (token == null) {
        return {'success': false, 'message': 'กรุณาล็อกอินก่อน'};
      }

      final url = Uri.parse('$baseUrl/api/v1/wallet/job-payment');
      final response = await http.post(
        url,
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
        body: jsonEncode({
          "jobId": jobId,
          "workerId": workerId,
          "amount": amount,
        }),
      );

      return jsonDecode(response.body);
    } catch (e) {
      return {'success': false, 'message': 'เกิดข้อผิดพลาด: $e'};
    }
  }

  static Future<Map<String, dynamic>> getBalance() async {
    try {
      final token = AuthService.getToken();
      if (token == null) {
        return {'success': false, 'message': 'กรุณาล็อกอินก่อน'};
      }

      final url = Uri.parse('$baseUrl/api/v1/wallet');
      final response = await http.get(
        url,
        headers: {"Authorization": "Bearer $token"},
      );

      return jsonDecode(response.body);
    } catch (e) {
      return {'success': false, 'message': 'เกิดข้อผิดพลาด: $e'};
    }
  }
}