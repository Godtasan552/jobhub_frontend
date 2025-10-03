import 'package:dio/dio.dart';
import 'package:get_storage/get_storage.dart';

class ChatService {
  final Dio _dio;
  final storage = GetStorage();

  ChatService(this._dio);

  // ฟังก์ชันส่งข้อความผ่าน HTTP
  Future<Map<String, dynamic>> sendMessage(
    String toUserId,
    String message,
  ) async {
    try {
      print('📤 HTTP: Sending message to $toUserId');

      final token = storage.read('token');
      final response = await _dio.post(
        '/api/v1/chat/send',
        data: {'toUserId': toUserId, 'message': message, 'messageType': 'text'},
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );

      print('✅ HTTP: Message sent successfully');

      // ดึงข้อมูลข้อความจาก response
      final data = response.data['data'];

      return data is Map<String, dynamic> ? data : {'message': message};
    } catch (e) {
      print('❌ HTTP Error sending message: $e');
      rethrow;
    }
  }

  // ดึง conversations
  Future<List<dynamic>> getConversations() async {
    try {
      print('📋 Loading conversations...');

      final token = storage.read('token');
      final response = await _dio.get(
        '/api/v1/chat/conversations',
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );

      print('✅ Loaded ${response.data['data'].length} conversations');
      return response.data['data'] ?? [];
    } catch (e) {
      print('❌ Failed to load conversations');
      rethrow;
    }
  }

  Future<List<dynamic>> getMessages(String otherUserId) async {
    try {
      print('💬 Loading messages...');

      final token = storage.read('token');
      final response = await _dio.get(
        '/api/v1/chat/conversations/$otherUserId',
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );

      print('✅ Loaded ${response.data['data'].length} messages');
      return response.data['data'] ?? [];
    } catch (e) {
      print('❌ Failed to load messages');
      rethrow;
    }
  }

  // ดึง unread count
  Future<int> getUnreadCount() async {
    try {
      final token = storage.read('token');
      final response = await _dio.get(
        '/api/v1/chat/unread-count',
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );

      return response.data['data']['total'] ?? 0;
    } catch (e) {
      print('❌ HTTP Error getting unread count: $e');
      return 0;
    }
  }

  // Mark as read
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
        data: {'messageIds': messageIds},
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );

      print('✅ Messages marked as read successfully');
    } catch (e) {
      print('❌ Error marking as read: $e');
    }
  }
}
