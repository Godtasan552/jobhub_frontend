// lib/services/job_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../model/job_model.dart';
import 'auth_service.dart';

class JobService {
  static final String baseUrl = dotenv.env['BASE_URL'] ?? '';

  /// ดึงงานทั้งหมด
  static Future<Map<String, dynamic>> getAllJobs() async {
    try {
      final token = AuthService.getToken();
      final url = Uri.parse('$baseUrl/api/v1/jobs');

      final response = await http.get(
        url,
        headers: {
          "Content-Type": "application/json",
          if (token != null) "Authorization": "Bearer $token",
        },
      );

      final data = jsonDecode(response.body);

      if (data['success'] == true) {
        List<JobModel> jobs = (data['data'] as List)
            .map((job) => JobModel.fromJson(job))
            .toList();

        return {'success': true, 'jobs': jobs};
      }

      return {
        'success': false,
        'message': data['message'] ?? 'ไม่สามารถดึงข้อมูลงานได้',
      };
    } catch (e) {
      return {'success': false, 'message': 'เกิดข้อผิดพลาด: $e'};
    }
  }

  /// ดึงรายละเอียดงาน
  static Future<Map<String, dynamic>> getJobById(String jobId) async {
    try {
      final token = AuthService.getToken();
      final url = Uri.parse('$baseUrl/api/v1/jobs/$jobId');

      final response = await http.get(
        url,
        headers: {
          "Content-Type": "application/json",
          if (token != null) "Authorization": "Bearer $token",
        },
      );

      final data = jsonDecode(response.body);

      if (data['success'] == true) {
        JobModel job = JobModel.fromJson(data['data']);

        return {'success': true, 'job': job};
      }

      return {
        'success': false,
        'message': data['message'] ?? 'ไม่สามารถดึงข้อมูลงานได้',
      };
    } catch (e) {
      return {'success': false, 'message': 'เกิดข้อผิดพลาด: $e'};
    }
  }
}
