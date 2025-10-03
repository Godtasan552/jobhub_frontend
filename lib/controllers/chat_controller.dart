import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:http/http.dart' as storage;
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:dio/dio.dart';
import '../services/chat_service.dart';

import 'package:get_storage/get_storage.dart';

class ChatController extends GetxController {
  static final ChatController instance = ChatController._internal();
  factory ChatController() => instance;
  ChatController._internal() {
    // Initialize ตอนสร้าง instance
    _initializeServices();
  }

  IO.Socket? _socket;
  var isConnected = false.obs;

  late final ChatService chatService;
  late final Dio _dio;

  // Callbacks
  Function(dynamic)? onMessage;
  Function(List)? onMessages;
  Function(List)? onConversations;
  Function(int)? onUnreadCount;

  static final String baseUrl = dotenv.env['BASE_URL'] ?? '';

  // เพิ่มฟังก์ชันนี้ลงไปใน ChatController class

  // ส่งข้อความผ่าน HTTP API

void _initializeServices() {
  print('🔧 Initializing services...');
  _dio = Dio();
  _dio.options.baseUrl = baseUrl;
  
  _dio.interceptors.add(InterceptorsWrapper(
    onRequest: (options, handler) {
      print('🌐 ${options.method} ${options.path}');
      print('🔑 Authenticated: ${options.headers.containsKey('Authorization')}'); // ✅ แค่บอกว่ามี auth
      return handler.next(options);
    },
    onResponse: (response, handler) {
      print('✅ Response: ${response.statusCode}');
      return handler.next(response);
    },
    onError: (error, handler) {
      print('❌ Request failed: ${error.response?.statusCode ?? 'Unknown'}');
      return handler.next(error);
    },
  ));
  
  chatService = ChatService(_dio);
  print('✅ Services initialized');
}
  void connect(String token) {
    print('');
    print('🔌 ========== CONNECT START ==========');

    if (_socket != null && _socket!.connected) {
      print('⚠️ Socket already connected');
      print('🔌 ===================================');
      return;
    }

    print('🌐 Connecting to: $baseUrl');
    print('🔑 Using authentication token'); // ✅ แค่บอกว่ามี token

    _socket = IO.io(
      baseUrl,
      IO.OptionBuilder()
          .setTransports(['websocket'])
          .disableAutoConnect()
          .setAuth({'token': token})
          .build(),
    );

    print('📝 Setting up Socket event listeners...');

    _socket!.onConnect((_) {
      print('✅ Socket connected successfully'); // ✅ แสดงแค่สถานะ
      isConnected.value = true;
    });

    _socket!.onDisconnect((_) {
      print('❌ Socket disconnected');
      isConnected.value = false;
    });

    _socket!.onConnectError((data) {
      print('❌ Connection Error');
    });

    _socket!.onError((data) {
      print('❌ Socket Error occurred');
    });

    print('✅ Socket listeners configured');
    print('🔌 Attempting connection...');

    _socket!.connect();

    print('🔌 ===================================');
    print('');
  }

  // ใช้ HTTP API
  Future<void> getConversations() async {
    print('');
    print('📋 ========== GET CONVERSATIONS (HTTP) ==========');

    try {
      print('📋 Calling chatService.getConversations()...');
      final conversations = await chatService.getConversations();

      print('✅ Got ${conversations.length} conversations');
      print('📦 Data: $conversations');

      if (onConversations != null) {
        print('✅ Calling onConversations callback');
        onConversations!(conversations);
      } else {
        print('⚠️ onConversations callback is null');
      }
    } catch (e, stackTrace) {
      print('❌ Error: $e');
      print('❌ Stack trace: $stackTrace');
    }

    print('📋 ===============================================');
    print('');
  }

  Future<void> getMessages(String otherUserId) async {
    print('');
    print('💬 ========== GET MESSAGES (HTTP) ==========');

    try {
      print('💬 Getting messages with: $otherUserId');
      final messages = await chatService.getMessages(otherUserId);

      print('✅ Got ${messages.length} messages');

      if (onMessages != null) {
        print('✅ Calling onMessages callback');
        onMessages!(messages);
      } else {
        print('⚠️ onMessages callback is null');
      }
    } catch (e, stackTrace) {
      print('❌ Error: $e');
      print('❌ Stack trace: $stackTrace');
    }

    print('💬 ===========================================');
    print('');
  }

  Future<void> getUnreadCount() async {
    try {
      print('🔔 Getting unread count...');
      final count = await chatService.getUnreadCount();

      print('✅ Unread count: $count');

      if (onUnreadCount != null) {
        onUnreadCount!(count);
      }
    } catch (e) {
      print('❌ Error getting unread count: $e');
    }
  }

  // ใช้ Socket สำหรับ real-time
  void joinChat(String otherUserId) {
    print('');
    print('🔗 ========== JOIN CHAT ==========');

    if (_socket == null || !_socket!.connected) {
      print('❌ Socket not connected, cannot join');
      print('🔗 ================================');
      return;
    }

    print('🔗 Joining chat with: $otherUserId');

    final userId = GetStorage().read('userId');
    final roomId = _createRoomId(userId, otherUserId);

    print('🔗 Room ID: $roomId');
    print('🔗 Emitting join_chat event...');

    _socket!.emit('join_chat', {'roomId': roomId, 'otherUserId': otherUserId});

    print('✅ join_chat emitted');
    print('🔗 ================================');
    print('');
  }

  void sendMessage(String otherUserId, String message) async {
    print('📤 Sending message...');

    // ตรวจสอบว่า Socket เชื่อมต่ออยู่หรือไม่
    final isSocketConnected = _socket != null && _socket!.connected;

    if (isSocketConnected) {
      print('📤 Trying Socket first...');

      final userId = GetStorage().read('userId');
      final roomId = _createRoomId(userId, otherUserId);

      _socket!.emit('send_message', {
        'roomId': roomId,
        'toUserId': otherUserId,
        'message': message,
        'messageType': 'text',
      });

      print('✅ send_message emitted via Socket');

      // รอ 1.5 วินาที ถ้า Socket ไม่ตอบกลับ ให้ใช้ HTTP
      await Future.delayed(const Duration(milliseconds: 1500));

      // ตรวจสอบว่าได้รับ callback หรือยัง
      // ถ้ายังไม่ได้รับ ให้ส่งผ่าน HTTP
      print('⚠️ Socket may not respond, sending via HTTP as backup');
      await sendMessageHttp(otherUserId, message);
    } else {
      // ถ้า Socket ไม่เชื่อมต่อ ใช้ HTTP เลย
      print('❌ Socket not connected, using HTTP API');
      await sendMessageHttp(otherUserId, message);
    }
  }

  Future<void> sendMessageHttp(String otherUserId, String message) async {
    print('');
    print('📤 ========== SEND MESSAGE (HTTP) ==========');
    print('📤 To: $otherUserId');
    print('📤 Message: $message');

    try {
      final messageData = await chatService.sendMessage(otherUserId, message);

      print('✅ Message sent via HTTP');
      print('📦 Response: $messageData');

      // เรียก callback เพื่ออัพเดท UI
      if (onMessage != null) {
        print('✅ Calling onMessage callback');
        onMessage!(messageData);
      } else {
        print('⚠️ onMessage callback is null');
      }
    } catch (e, stackTrace) {
      print('❌ Error sending message via HTTP: $e');
      print('❌ Stack trace: $stackTrace');
      rethrow;
    }

    print('📤 ==========================================');
    print('');
  }

  void markAsRead(String otherUserId, List<String> messageIds) {
    print('✅ Marking messages as read for: $otherUserId');
    chatService.markAsRead(otherUserId, messageIds);
  }

  // ใน chat_controller.dart
  Future<void> markAsReadWithMessages(
    String otherUserId,
    List<String> messageIds,
  ) async {
    if (messageIds.isEmpty) {
      print('⚠️ No messages to mark as read');
      return;
    }

    try {
      print('✅ Marking ${messageIds.length} messages as read');

      final token = GetStorage().read('token');
      await _dio.post(
        '/api/v1/chat/mark-read',
        data: {'messageIds': messageIds},
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );

      print('✅ Messages marked as read');
    } catch (e) {
      print('❌ Error marking as read: $e');
    }
  }

  String _createRoomId(String userId1, String userId2) {
    final ids = [userId1, userId2]..sort();
    return ids.join('-');
  }

  void disconnect() {
    print('🔌 Disconnecting socket...');
    _socket?.disconnect();
    _socket?.dispose();
    _socket = null;
    isConnected.value = false;
    print('✅ Socket disconnected');
  }

  @override
  void onClose() {
    disconnect();
    super.onClose();
  }
}
