import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:form_validate/services/chat_service.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:dio/dio.dart';
import '../services/chat_service.dart';

class ChatController extends GetxController {
  static final ChatController instance = ChatController._internal();
  factory ChatController() => instance;
  ChatController._internal();

  IO.Socket? _socket;
  var isConnected = false.obs;
  
  late final ChatService chatService;
  final Dio _dio = Dio();

  // Callbacks
  Function(dynamic)? onMessage;
  Function(List)? onMessages;
  Function(List)? onConversations;
  Function(int)? onUnreadCount;

  static final String baseUrl = dotenv.env['BASE_URL'] ?? '';

  @override
  void onInit() {
    super.onInit();
    _dio.options.baseUrl = baseUrl;
    chatService = ChatService(_dio);
  }

  void connect(String token) {
    print('🔌 ========== CONNECT START ==========');
    
    if (_socket != null && _socket!.connected) {
      print('⚠️ Socket already connected');
      return;
    }

    print('🌐 Connecting to: $baseUrl');

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
      print('✅ Socket connected');
      isConnected.value = true;
    });

    _socket!.onDisconnect((_) {
      print('❌ Socket disconnected');
      isConnected.value = false;
    });

    _socket!.onConnectError((data) {
      print('❌ Connection Error: $data');
    });

    _socket!.onError((data) {
      print('❌ Socket Error: $data');
    });

    // Listen for real-time messages
    _socket!.on('receive_message', (data) {
      print('📨 New message received via socket');
      print('Data: $data');
      
      if (onMessage != null) {
        onMessage!(data);
      }
    });

    // Listen for message sent confirmation
    _socket!.on('message_sent', (data) {
      print('✅ Message sent confirmed');
      if (onMessage != null) {
        onMessage!(data);
      }
    });

    // Listen for messages read
    _socket!.on('messages_read', (data) {
      print('✅ Messages marked as read');
    });

    // Listen for typing
    _socket!.on('user_typing', (data) {
      print('⌨️ User typing: $data');
    });

    print('✅ Socket listeners set up');
    print('🔌 Calling socket.connect()...');
    
    _socket!.connect();
    
    print('🔌 ===================================');
  }

  // ใช้ HTTP API แทน Socket
  Future<void> getConversations() async {
    try {
      print('📋 Fetching conversations via HTTP...');
      final conversations = await chatService.getConversations();
      
      if (onConversations != null) {
        onConversations!(conversations);
      }
      
    } catch (e) {
      print('❌ Error: $e');
    }
  }

  Future<void> getMessages(String otherUserId) async {
    try {
      print('💬 Fetching messages via HTTP...');
      final messages = await chatService.getMessages(otherUserId);
      
      if (onMessages != null) {
        onMessages!(messages);
      }
      
    } catch (e) {
      print('❌ Error: $e');
    }
  }

  Future<void> getUnreadCount() async {
    try {
      final count = await chatService.getUnreadCount();
      
      if (onUnreadCount != null) {
        onUnreadCount!(count);
      }
      
    } catch (e) {
      print('❌ Error: $e');
    }
  }
  
  // ใช้ Socket สำหรับ real-time
  void joinChat(String otherUserId) {
    if (_socket == null || !_socket!.connected) {
      print('❌ Socket not connected');
      return;
    }

    print('🔗 Joining chat with: $otherUserId');
    
    final userId = GetStorage().read('userId');
    final roomId = _createRoomId(userId, otherUserId);
    
    _socket!.emit('join_chat', {
      'roomId': roomId,
      'otherUserId': otherUserId
    });
  }

  void sendMessage(String otherUserId, String message) {
    if (_socket == null || !_socket!.connected) {
      print('❌ Socket not connected');
      return;
    }

    print('📤 Sending message via Socket');
    
    final userId = GetStorage().read('userId');
    final roomId = _createRoomId(userId, otherUserId);
    
    _socket!.emit('send_message', {
      'roomId': roomId,
      'toUserId': otherUserId,
      'message': message,
      'messageType': 'text'
    });
  }

  void markAsRead(String otherUserId) {
    chatService.markAsRead(otherUserId);
  }

  String _createRoomId(String userId1, String userId2) {
    final ids = [userId1, userId2]..sort();
    return ids.join('-');
  }

  void disconnect() {
    _socket?.disconnect();
    _socket?.dispose();
    _socket = null;
    isConnected.value = false;
    print('🔌 Socket disconnected');
  }

  @override
  void onClose() {
    disconnect();
    super.onClose();
  }
}