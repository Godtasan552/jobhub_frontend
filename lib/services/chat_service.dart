import 'package:dio/dio.dart';
import 'package:get_storage/get_storage.dart';

class ChatService {
  final Dio _dio;
  final storage = GetStorage();
  
  ChatService(this._dio);

  // ใช้ REST API สำหรับดึงข้อมูล
  Future<List<dynamic>> getConversations() async {
    try {
      print('📋 HTTP: Getting conversations');
      
      final token = storage.read('token');
      final response = await _dio.get(
        '/api/v1/chat/conversations',
        options: Options(
          headers: {'Authorization': 'Bearer $token'}
        ),
      );

      print('✅ HTTP: Got ${response.data['data'].length} conversations');
      
      return response.data['data'] ?? [];
      
    } catch (e) {
      print('❌ HTTP Error getting conversations: $e');
      rethrow;
    }
  }

  Future<List<dynamic>> getMessages(String otherUserId) async {
    try {
      print('💬 HTTP: Getting messages with $otherUserId');
      
      final token = storage.read('token');
      final response = await _dio.get(
        '/api/v1/chat/conversations/$otherUserId',
        options: Options(
          headers: {'Authorization': 'Bearer $token'}
        ),
      );

      print('✅ HTTP: Got ${response.data['data'].length} messages');
      
      return response.data['data'] ?? [];
      
    } catch (e) {
      print('❌ HTTP Error getting messages: $e');
      rethrow;
    }
  }

  Future<int> getUnreadCount() async {
    try {
      final token = storage.read('token');
      final response = await _dio.get(
        '/api/v1/chat/unread-count',
        options: Options(
          headers: {'Authorization': 'Bearer $token'}
        ),
      );

      return response.data['data']['total'] ?? 0;
      
    } catch (e) {
      print('❌ HTTP Error getting unread count: $e');
      return 0;
    }
  }

Future<void> markAsRead(String otherUserId, List<String> messageIds) async {
  try {
    if (messageIds.isEmpty) {
      print('⚠️ No messages to mark as read');
      return;
    }
    
    print('✅ Marking ${messageIds.length} messages as read');
    
    final token = storage.read('token');
    await _dio.post(
      '/api/v1/chat/mark-read',
      data: {
        'messageIds': messageIds,  // ส่ง messageIds ตามที่ backend ต้องการ
      },
      options: Options(
        headers: {'Authorization': 'Bearer $token'}
      ),
    );
    
    print('✅ Messages marked as read successfully');
    
  } catch (e) {
    print('❌ Error marking as read: $e');
    // ไม่ throw เพราะไม่ใช่ฟีเจอร์หลัก
  }
}
}