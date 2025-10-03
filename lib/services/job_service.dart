// lib/services/job_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../model/job_model.dart';
import 'auth_service.dart';

class JobService {
  static final String baseUrl = dotenv.env['BASE_URL'] ?? '';

  // ==================== ดึงข้อมูลงาน ====================

  /// GET /api/v1/jobs - ดูงานทั้งหมด
  static Future<Map<String, dynamic>> getAllJobs() async {
    try {
      final token = AuthService.getToken();
      final url = Uri.parse('$baseUrl/api/v1/jobs');

      print('🌐 Fetching jobs from: $url');
      print('🔑 Token exists: ${token != null}');

      final response = await http.get(
        url,
        headers: {
          "Content-Type": "application/json",
          if (token != null) "Authorization": "Bearer $token",
        },
      );

      print('📡 Response status: ${response.statusCode}');
      print('📄 Response body: ${response.body}');

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
      print('❌ JobService Error: $e');
      return {'success': false, 'message': 'เกิดข้อผิดพลาด: $e'};
    }
  }

  /// GET /api/v1/jobs/:id - ดูรายละเอียดงาน
  static Future<Map<String, dynamic>> getJobById(String jobId) async {
    try {
      final token = AuthService.getToken();
      final url = Uri.parse('$baseUrl/api/v1/jobs/$jobId');

      print('🔍 Fetching job detail: $url');

      final response = await http.get(
        url,
        headers: {
          "Content-Type": "application/json",
          if (token != null) "Authorization": "Bearer $token",
        },
      );

      print('📡 Response status: ${response.statusCode}');

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
      print('❌ getJobById Error: $e');
      return {'success': false, 'message': 'เกิดข้อผิดพลาด: $e'};
    }
  }

  /// GET /api/v1/jobs/search - ค้นหางาน
  static Future<Map<String, dynamic>> searchJobs({
    String? search,
    String? category,
    String? type,
  }) async {
    try {
      final token = AuthService.getToken();

      // สร้าง query parameters
      Map<String, String> queryParams = {};
      if (search != null && search.isNotEmpty) queryParams['search'] = search;
      if (category != null && category.isNotEmpty)
        queryParams['category'] = category;
      if (type != null && type.isNotEmpty) queryParams['type'] = type;

      final url = Uri.parse(
        '$baseUrl/api/v1/jobs/search',
      ).replace(queryParameters: queryParams.isNotEmpty ? queryParams : null);

      print('🔎 Searching jobs: $url');

      final response = await http.get(
        url,
        headers: {
          "Content-Type": "application/json",
          if (token != null) "Authorization": "Bearer $token",
        },
      );

      print('📡 Response status: ${response.statusCode}');

      final data = jsonDecode(response.body);

      if (data['success'] == true) {
        List<JobModel> jobs = (data['data'] as List)
            .map((job) => JobModel.fromJson(job))
            .toList();

        return {'success': true, 'jobs': jobs};
      }

      return {
        'success': false,
        'message': data['message'] ?? 'ไม่พบงานที่ค้นหา',
      };
    } catch (e) {
      print('❌ searchJobs Error: $e');
      return {'success': false, 'message': 'เกิดข้อผิดพลาด: $e'};
    }
  }

  /// GET /api/v1/jobs/my/created - ดูงานที่ฉันสร้าง (employer)
  static Future<Map<String, dynamic>> getMyCreatedJobs() async {
    try {
      final token = AuthService.getToken();
      if (token == null) {
        return {'success': false, 'message': 'กรุณาล็อกอินก่อน'};
      }

      final url = Uri.parse('$baseUrl/api/v1/jobs/my/created');

      print('📋 Fetching my created jobs: $url');

      final response = await http.get(
        url,
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
      );

      print('📡 Response status: ${response.statusCode}');

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
      print('❌ getMyCreatedJobs Error: $e');
      return {'success': false, 'message': 'เกิดข้อผิดพลาด: $e'};
    }
  }

  /// GET /api/v1/jobs/my/applied - ดูงานที่ฉันสมัคร (worker)
  static Future<Map<String, dynamic>> getMyAppliedJobs() async {
    try {
      final token = AuthService.getToken();
      if (token == null) {
        return {'success': false, 'message': 'กรุณาล็อกอินก่อน'};
      }

      final url = Uri.parse('$baseUrl/api/v1/jobs/my/applied');

      print('📋 Fetching my applied jobs: $url');

      final response = await http.get(
        url,
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
      );

      print('📡 Response status: ${response.statusCode}');

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
      print('❌ getMyAppliedJobs Error: $e');
      return {'success': false, 'message': 'เกิดข้อผิดพลาด: $e'};
    }
  }

  // ==================== สร้างและจัดการงาน ====================

  /// POST /api/v1/jobs - สร้างงานใหม่ (employer)
  static Future<Map<String, dynamic>> createJob({
    required String title,
    required String description,
    required String type,
    required String category,
    required num budget,
    required String duration,
    required String deadline,
    List<String>? requirements,
    List<String>? attachments,
  }) async {
    try {
      final token = AuthService.getToken();
      if (token == null) {
        return {'success': false, 'message': 'กรุณาล็อกอินก่อน'};
      }

      final url = Uri.parse('$baseUrl/api/v1/jobs');

      print('➕ Creating new job: $url');

      final response = await http.post(
        url,
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
        body: jsonEncode({
          "title": title,
          "description": description,
          "type": type,
          "category": category,
          "budget": budget,
          "duration": duration,
          "deadline": deadline,
          if (requirements != null) "requirements": requirements,
          if (attachments != null) "attachments": attachments,
        }),
      );

      print('📡 Response status: ${response.statusCode}');

      final data = jsonDecode(response.body);

      if (response.statusCode >= 200 && response.statusCode < 300) {
        return {
          'success': true,
          'message': data['message'] ?? 'สร้างงานสำเร็จ',
          'job': data['data'] != null ? JobModel.fromJson(data['data']) : null,
        };
      }

      return {
        'success': false,
        'message': data['message'] ?? 'ไม่สามารถสร้างงานได้',
      };
    } catch (e) {
      print('❌ createJob Error: $e');
      return {'success': false, 'message': 'เกิดข้อผิดพลาด: $e'};
    }
  }

  /// PUT /api/v1/jobs/:id - แก้ไขงาน (เจ้าของงาน)
  static Future<Map<String, dynamic>> updateJob(
    String jobId,
    Map<String, dynamic> updates,
  ) async {
    try {
      final token = AuthService.getToken();
      if (token == null) {
        return {'success': false, 'message': 'กรุณาล็อกอินก่อน'};
      }

      final url = Uri.parse('$baseUrl/api/v1/jobs/$jobId');

      print('✏️ Updating job: $url');

      final response = await http.put(
        url,
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
        body: jsonEncode(updates),
      );

      print('📡 Response status: ${response.statusCode}');

      final data = jsonDecode(response.body);

      if (response.statusCode >= 200 && response.statusCode < 300) {
        return {
          'success': true,
          'message': data['message'] ?? 'แก้ไขงานสำเร็จ',
          'job': data['data'] != null ? JobModel.fromJson(data['data']) : null,
        };
      }

      return {
        'success': false,
        'message': data['message'] ?? 'ไม่สามารถแก้ไขงานได้',
      };
    } catch (e) {
      print('❌ updateJob Error: $e');
      return {'success': false, 'message': 'เกิดข้อผิดพลาด: $e'};
    }
  }

  /// DELETE /api/v1/jobs/:id - ลบงาน (เจ้าของงาน)
  static Future<Map<String, dynamic>> deleteJob(String jobId) async {
    try {
      final token = AuthService.getToken();
      if (token == null) {
        return {'success': false, 'message': 'กรุณาล็อกอินก่อน'};
      }

      final url = Uri.parse('$baseUrl/api/v1/jobs/$jobId');

      print('🗑️ Deleting job: $url');

      final response = await http.delete(
        url,
        headers: {"Authorization": "Bearer $token"},
      );

      print('📡 Response status: ${response.statusCode}');

      final data = jsonDecode(response.body);

      if (response.statusCode >= 200 && response.statusCode < 300) {
        return {'success': true, 'message': data['message'] ?? 'ลบงานสำเร็จ'};
      }

      return {
        'success': false,
        'message': data['message'] ?? 'ไม่สามารถลบงานได้',
      };
    } catch (e) {
      print('❌ deleteJob Error: $e');
      return {'success': false, 'message': 'เกิดข้อผิดพลาด: $e'};
    }
  }

  // ==================== สมัครงานและจัดการใบสมัคร ====================

  /// POST /api/v1/jobs/:id/apply - สมัครงาน (worker)
  static Future<Map<String, dynamic>> applyJob({
    required String jobId,
    required String coverLetter,
    required num proposedBudget,
    String? estimatedDuration,
    List<String>? attachments,
  }) async {
    try {
      final token = AuthService.getToken();
      if (token == null) {
        return {'success': false, 'message': 'กรุณาล็อกอินก่อน'};
      }

      final url = Uri.parse('$baseUrl/api/v1/jobs/$jobId/apply');

      print('📝 Applying for job: $url');

      final response = await http.post(
        url,
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
        body: jsonEncode({
          "coverLetter": coverLetter,
          "proposedBudget": proposedBudget,
          if (estimatedDuration != null) "estimatedDuration": estimatedDuration,
          if (attachments != null) "attachments": attachments,
        }),
      );

      print('📡 Response status: ${response.statusCode}');
      print('📄 Response body: ${response.body}');

      final data = jsonDecode(response.body);

      if (response.statusCode >= 200 && response.statusCode < 300) {
        return {
          'success': true,
          'message': data['message'] ?? 'สมัครงานสำเร็จ',
          'application': data['data'],
        };
      }

      return {
        'success': false,
        'message': data['message'] ?? 'ไม่สามารถสมัครงานได้',
        'statusCode': response.statusCode,
      };
    } catch (e) {
      print('❌ applyJob Error: $e');
      return {'success': false, 'message': 'เกิดข้อผิดพลาด: $e'};
    }
  }

  /// GET /api/v1/jobs/:id/applications - ดูใบสมัครงาน (เจ้าของงาน)
  /// GET /api/v1/jobs/:id/applications - ดูใบสมัครงาน (เจ้าของงาน)
  static Future<Map<String, dynamic>> getJobApplications(String jobId) async {
    try {
      final token = AuthService.getToken();
      if (token == null) {
        return {'success': false, 'message': 'กรุณาล็อกอินก่อน'};
      }

      final url = Uri.parse('$baseUrl/api/v1/jobs/$jobId/applications');
      print('📋 Fetching job applications: $url');

      final response = await http.get(
        url,
        headers: {"Authorization": "Bearer $token"},
      );

      print('📡 Response status: ${response.statusCode}');
      final data = jsonDecode(response.body);

      if (data['success'] == true) {
        // ✅ แก้ไขตรงนี้
        var applicationsData = data['data'];
        List<dynamic> applicationsList;

        if (applicationsData is List) {
          applicationsList = applicationsData;
        } else if (applicationsData is Map) {
          applicationsList =
              applicationsData['applications'] ??
              applicationsData['data'] ??
              [];
        } else {
          applicationsList = [];
        }

        return {'success': true, 'applications': applicationsList};
      }

      return {
        'success': false,
        'message': data['message'] ?? 'ไม่สามารถดึงข้อมูลใบสมัครได้',
      };
    } catch (e) {
      print('❌ getJobApplications Error: $e');
      return {'success': false, 'message': 'เกิดข้อผิดพลาด: $e'};
    }
  }

  /// POST /api/v1/jobs/:id/assign - มอบหมายงาน (เจ้าของงาน)
  static Future<Map<String, dynamic>> assignJob({
    required String jobId,
    required String workerId,
  }) async {
    try {
      final token = AuthService.getToken();
      if (token == null) {
        return {'success': false, 'message': 'กรุณาล็อกอินก่อน'};
      }

      final url = Uri.parse('$baseUrl/api/v1/jobs/$jobId/assign');

      print('👤 Assigning job to worker: $url');

      final response = await http.post(
        url,
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
        body: jsonEncode({"workerId": workerId}),
      );

      print('📡 Response status: ${response.statusCode}');

      final data = jsonDecode(response.body);

      if (response.statusCode >= 200 && response.statusCode < 300) {
        return {
          'success': true,
          'message': data['message'] ?? 'มอบหมายงานสำเร็จ',
          'job': data['data'] != null ? JobModel.fromJson(data['data']) : null,
        };
      }

      return {
        'success': false,
        'message': data['message'] ?? 'ไม่สามารถมอบหมายงานได้',
      };
    } catch (e) {
      print('❌ assignJob Error: $e');
      return {'success': false, 'message': 'เกิดข้อผิดพลาด: $e'};
    }
  }
}
