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
    _dio.options.connectTimeout = const Duration(seconds: 30);
    _dio.options.receiveTimeout = const Duration(seconds: 30);
    
    // Add interceptor for debugging
    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) {
        print('🌐 HTTP Request: ${options.method} ${options.path}');
        print('🌐 Headers: ${options.headers}');
        return handler.next(options);
      },
      onResponse: (response, handler) {
        print('✅ HTTP Response: ${response.statusCode}');
        print('✅ Data: ${response.data}');
        return handler.next(response);
      },
      onError: (error, handler) {
        print('❌ HTTP Error: ${error.message}');
        print('❌ Response: ${error.response?.data}');
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
  print('🔑 Token: ${token.substring(0, 20)}...');

  _socket = IO.io(
    baseUrl,
    IO.OptionBuilder()
        .setTransports(['websocket'])
        .disableAutoConnect()
        .setAuth({'token': token})
        .build(),
  );

  print('📝 Setting up Socket event listeners...');

  // Connect listener
  _socket!.onConnect((_) {
    print('');
    print('✅ Socket connected');
    isConnected.value = true;
    print('');
  });

  _socket!.onDisconnect((_) {
    print('');
    print('❌ Socket disconnected');
    isConnected.value = false;
    print('');
  });

  _socket!.onConnectError((data) {
    print('❌ Connection Error: $data');
  });

  _socket!.onError((data) {
    print('❌ Socket Error: $data');
  });

  // ฟังทุก event (สำหรับ debug)
  _socket!.onAny((event, data) {
    print('');
    print('📡 ========== SOCKET EVENT ==========');
    print('📡 Event: $event');
    print('📡 Data: $data');
    print('📡 ===================================');
    print('');
  });

  // Listen for receive_message (ข้อความจากคนอื่น)
  _socket!.on('receive_message', (data) {
    print('');
    print('📨 ========== RECEIVE_MESSAGE ==========');
    print('📨 Data: $data');
    
    if (onMessage != null) {
      print('✅ Calling onMessage callback');
      onMessage!(data);
    } else {
      print('⚠️ onMessage callback is null');
    }
    print('📨 ======================================');
    print('');
  });

  // Listen for message_sent (ยืนยันว่าส่งสำเร็จ)
  _socket!.on('message_sent', (data) {
    print('');
    print('✅ ========== MESSAGE_SENT ==========');
    print('✅ Data: $data');
    
    if (onMessage != null) {
      print('✅ Calling onMessage callback');
      onMessage!(data);
    } else {
      print('⚠️ onMessage callback is null');
    }
    print('✅ ===================================');
    print('');
  });

  // ลองฟัง event อื่นๆ ที่อาจใช้
  _socket!.on('message', (data) {
    print('');
    print('📨 ========== MESSAGE EVENT ==========');
    print('📨 Data: $data');
    
    if (onMessage != null) {
      onMessage!(data);
    }
    print('📨 ====================================');
    print('');
  });

  // Listen for new message notification
  _socket!.on('new_message_notification', (data) {
    print('🔔 New message notification: $data');
  });

  // Listen for messages read
  _socket!.on('messages_read', (data) {
    print('✅ Messages marked as read: $data');
  });

  // Listen for typing
  _socket!.on('user_typing', (data) {
    print('⌨️ User typing: $data');
  });

  // Listen for user joined
  _socket!.on('room_joined', (data) {
    print('✅ Room joined: $data');
  });

  print('✅ Socket listeners set up');
  print('🔌 Calling socket.connect()...');
  
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
    
    _socket!.emit('join_chat', {
      'roomId': roomId,
      'otherUserId': otherUserId
    });
    
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
      'messageType': 'text'
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
Future<void> markAsReadWithMessages(String otherUserId, List<String> messageIds) async {
  if (messageIds.isEmpty) {
    print('⚠️ No messages to mark as read');
    return;
  }
  
  try {
    print('✅ Marking ${messageIds.length} messages as read');
    
    final token = GetStorage().read('token');
    await _dio.post(
      '/api/v1/chat/mark-read',
      data: {
        'messageIds': messageIds,
      },
      options: Options(
        headers: {'Authorization': 'Bearer $token'}
      ),
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