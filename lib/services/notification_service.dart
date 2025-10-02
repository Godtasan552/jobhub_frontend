// lib/services/notification_service.dart
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../model/notification_model.dart';

class NotificationService {
  static final String baseUrl = dotenv.env['BASE_URL'] ?? '';

  // ✅ แก้ไข: เพิ่ม /api/v1 ใน path
  static Future<List<NotificationModel>> getNotifications(String accessToken) async {
    print('📡 [NotificationService] GET /api/v1/notifications');
    print('   URL: $baseUrl/api/v1/notifications');
    print('   Token: ${accessToken.substring(0, 20)}...');
    
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/v1/notifications'), // ✅ แก้ไขตรงนี้
        headers: {
          'Authorization': 'Bearer $accessToken',
          'Content-Type': 'application/json',
        },
      );

      print('📡 [NotificationService] Response status: ${response.statusCode}');
      print('📡 [NotificationService] Response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        print('📡 [NotificationService] Parsed data: $data');
        
        final List notificationsJson = data['data'] ?? data['notifications'] ?? [];
        print('📡 [NotificationService] Notifications array length: ${notificationsJson.length}');
        
        final notifications = notificationsJson
            .map((json) => NotificationModel.fromJson(json))
            .toList();
        
        print('✅ [NotificationService] Successfully parsed ${notifications.length} notifications');
        return notifications;
      } else {
        print('❌ [NotificationService] Failed with status: ${response.statusCode}');
        throw Exception('Failed to load notifications: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ [NotificationService] Exception: $e');
      throw Exception('Error: $e');
    }
  }

  // ✅ แก้ไข: เพิ่ม /api/v1 ใน path
  static Future<int> getUnreadCount(String accessToken) async {
    print('📡 [NotificationService] GET /api/v1/notifications/unread-count');
    
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/v1/notifications/unread-count'), // ✅ แก้ไขตรงนี้
        headers: {
          'Authorization': 'Bearer $accessToken',
          'Content-Type': 'application/json',
        },
      );

      print('📡 [NotificationService] Response status: ${response.statusCode}');
      print('📡 [NotificationService] Response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final count = data['count'] ?? data['data']?['count'] ?? 0;
        print('✅ [NotificationService] Unread count: $count');
        return count;
      } else {
        throw Exception('Failed to load unread count');
      }
    } catch (e) {
      print('❌ [NotificationService] Exception: $e');
      throw Exception('Error: $e');
    }
  }

  // ✅ แก้ไข: เพิ่ม /api/v1 ใน path
  static Future<bool> markAsRead(String accessToken, List<String> notificationIds) async {
    print('📡 [NotificationService] POST /api/v1/notifications/mark-read');
    print('   IDs: $notificationIds');
    
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/v1/notifications/mark-read'), // ✅ แก้ไขตรงนี้
        headers: {
          'Authorization': 'Bearer $accessToken',
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'notificationIds': notificationIds,
        }),
      );

      print('📡 [NotificationService] Response status: ${response.statusCode}');
      print('📡 [NotificationService] Response body: ${response.body}');

      return response.statusCode == 200;
    } catch (e) {
      print('❌ [NotificationService] Exception: $e');
      throw Exception('Error: $e');
    }
  }

  // ✅ แก้ไข: เพิ่ม /api/v1 ใน path
  static Future<bool> deleteNotification(String accessToken, String notificationId) async {
    print('📡 [NotificationService] DELETE /api/v1/notifications/$notificationId');
    
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/api/v1/notifications/$notificationId'), // ✅ แก้ไขตรงนี้
        headers: {
          'Authorization': 'Bearer $accessToken',
          'Content-Type': 'application/json',
        },
      );

      print('📡 [NotificationService] Response status: ${response.statusCode}');
      print('📡 [NotificationService] Response body: ${response.body}');

      return response.statusCode == 200;
    } catch (e) {
      print('❌ [NotificationService] Exception: $e');
      throw Exception('Error: $e');
    }
  }
}