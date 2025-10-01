import 'dart:convert';
import 'package:http/http.dart' as http;
import '../model/notification_model.dart';

class NotificationService {
  static const String baseUrl = 'https://jobhubbackend-production-cc57.up.railway.app/api/v1';

  // ดึงการแจ้งเตือนทั้งหมด
  static Future<List<NotificationModel>> getNotifications(String accessToken) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/notifications'),
        headers: {
          'Authorization': 'Bearer $accessToken',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List notificationsJson = data['data'] ?? data['notifications'] ?? [];
        return notificationsJson
            .map((json) => NotificationModel.fromJson(json))
            .toList();
      } else {
        throw Exception('Failed to load notifications');
      }
    } catch (e) {
      throw Exception('Error: $e');
    }
  }

  // ดึงจำนวนการแจ้งเตือนที่ยังไม่อ่าน
  static Future<int> getUnreadCount(String accessToken) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/notifications/unread-count'),
        headers: {
          'Authorization': 'Bearer $accessToken',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['count'] ?? data['data']?['count'] ?? 0;
      } else {
        throw Exception('Failed to load unread count');
      }
    } catch (e) {
      throw Exception('Error: $e');
    }
  }

  // ทำเครื่องหมายว่าอ่านแล้ว
  static Future<bool> markAsRead(String accessToken, List<String> notificationIds) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/notifications/mark-read'),
        headers: {
          'Authorization': 'Bearer $accessToken',
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'notificationIds': notificationIds,
        }),
      );

      return response.statusCode == 200;
    } catch (e) {
      throw Exception('Error: $e');
    }
  }

  // ลบการแจ้งเตือน
  static Future<bool> deleteNotification(String accessToken, String notificationId) async {
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/notifications/$notificationId'),
        headers: {
          'Authorization': 'Bearer $accessToken',
          'Content-Type': 'application/json',
        },
      );

      return response.statusCode == 200;
    } catch (e) {
      throw Exception('Error: $e');
    }
  }
}