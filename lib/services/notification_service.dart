// lib/services/notification_service.dart

import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:get_storage/get_storage.dart';
import 'package:http/http.dart' as http;
import '../model/notification_model.dart';

class NotificationService {
  final String baseUrl = dotenv.env['BASE_URL'] ?? 'http://localhost:3000';
  
  // ✅ สร้าง GetStorage instance ใหม่ทุกครั้งเพื่อให้แน่ใจว่าได้ค่าล่าสุด
  GetStorage get _storage => GetStorage();

  // ดึง Access Token
  String? _getAccessToken() {
    // ✅ เปลี่ยนจาก 'accessToken' เป็น 'token' ตามที่เก็บจริง
    final token = _storage.read('token');
    
    // Debug: แสดงข้อมูล Token
    if (token != null) {
      print('🔑 NotificationService - Token: EXISTS (${token.toString().length} chars)');
      print('   First 50 chars: ${token.toString().substring(0, token.toString().length > 50 ? 50 : token.toString().length)}');
    } else {
      print('❌ NotificationService - Token: NULL');
      // ลองตรวจสอบ keys ทั้งหมดที่มีใน storage
      final allKeys = _storage.getKeys();
      print('   Available keys in storage: $allKeys');
    }
    
    return token;
  }

  // Headers พร้อม Authorization
  Map<String, String> _getHeaders() {
    final token = _getAccessToken();
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  // 1. GET /api/v1/notifications – ดูการแจ้งเตือนทั้งหมด
  Future<List<NotificationModel>> getNotifications() async {
    try {
      final url = Uri.parse('$baseUrl/api/v1/notifications');
      final headers = _getHeaders();
      
      print('📩 GET Notifications: $url');
      print('📋 Headers: ${headers.containsKey('Authorization') ? "Has Authorization" : "No Authorization"}');
      
      final response = await http.get(url, headers: headers);
      print('📩 Response Status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        print('📦 Raw API Response: $data');
        
        final List notifications = data['data'] ?? [];
        print('✅ API returned ${notifications.length} notifications');
        
        if (notifications.isNotEmpty) {
          print('📝 First notification sample: ${notifications[0]}');
        }
        
        // แปลง JSON เป็น Model
        final List<NotificationModel> notificationList = [];
        for (var i = 0; i < notifications.length; i++) {
          try {
            final notif = NotificationModel.fromJson(notifications[i]);
            notificationList.add(notif);
            print('   ✓ Parsed notification $i: ${notif.title}');
          } catch (e) {
            print('   ❌ Failed to parse notification $i: $e');
            print('   Raw data: ${notifications[i]}');
          }
        }
        
        print('✅ Successfully parsed ${notificationList.length}/${notifications.length} notifications');
        return notificationList;
      } else if (response.statusCode == 401) {
        print('❌ 401 Unauthorized - Token invalid or expired');
        print('   Response: ${response.body}');
        throw Exception('Unauthorized: Please login again');
      } else {
        print('❌ Error: ${response.statusCode} - ${response.body}');
        throw Exception('Failed to load notifications: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Error getting notifications: $e');
      rethrow;
    }
  }

  // 2. GET /api/v1/notifications/unread-count – ดูจำนวนการแจ้งเตือนที่ยังไม่อ่าน
  Future<int> getUnreadCount() async {
    try {
      final url = Uri.parse('$baseUrl/api/v1/notifications/unread-count');
      final headers = _getHeaders();
      
      final response = await http.get(url, headers: headers);

      print('🔢 GET Unread Count: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['data']['unreadCount'] ?? 0;
      } else if (response.statusCode == 401) {
        print('⚠️ Unread count - 401 Unauthorized (skipping)');
        return 0;
      } else {
        return 0;
      }
    } catch (e) {
      print('❌ Error getting unread count: $e');
      return 0;
    }
  }

  // 3. POST /api/v1/notifications/mark-read – ทำเครื่องหมายว่าอ่านแล้ว
  Future<bool> markAsRead(List<String> notificationIds) async {
    try {
      final url = Uri.parse('$baseUrl/api/v1/notifications/mark-read');
      final body = json.encode({'notificationIds': notificationIds});
      final headers = _getHeaders();

      final response = await http.post(
        url,
        headers: headers,
        body: body,
      );

      print('✅ Mark as Read: ${response.statusCode}');

      if (response.statusCode == 200) {
        return true;
      } else {
        throw Exception('Failed to mark as read');
      }
    } catch (e) {
      print('❌ Error marking as read: $e');
      return false;
    }
  }

  // ทำเครื่องหมายการแจ้งเตือนเดียวว่าอ่านแล้ว
  Future<bool> markSingleAsRead(String notificationId) async {
    return await markAsRead([notificationId]);
  }

  // ทำเครื่องหมายทั้งหมดว่าอ่านแล้ว
  Future<bool> markAllAsRead(List<NotificationModel> notifications) async {
    final unreadIds = notifications
        .where((n) => !n.read)
        .map((n) => n.id)
        .toList();
    
    if (unreadIds.isEmpty) return true;
    
    return await markAsRead(unreadIds);
  }

  // 4. DELETE /api/v1/notifications/:id – ลบการแจ้งเตือน
  Future<bool> deleteNotification(String notificationId) async {
    try {
      final url = Uri.parse('$baseUrl/api/v1/notifications/$notificationId');
      final headers = _getHeaders();
      
      final response = await http.delete(url, headers: headers);

      print('🗑️ Delete Notification: ${response.statusCode}');

      if (response.statusCode == 200) {
        return true;
      } else {
        throw Exception('Failed to delete notification');
      }
    } catch (e) {
      print('❌ Error deleting notification: $e');
      return false;
    }
  }
}