import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:get/get.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;

class ChatController extends GetxController {
  static final ChatController instance = ChatController._internal();
  factory ChatController() => instance;
  ChatController._internal();

  IO.Socket? _socket;
  var isConnected = false.obs;

  // Callbacks
  Function(dynamic)? onMessage;
  Function(List)? onMessages;
  Function(List)? onConversations;
  Function(int)? onUnreadCount;

  static final String baseUrl = dotenv.env['BASE_URL'] ?? '';

  void connect(String token) {
    if (_socket != null && _socket!.connected) {
      print('Socket already connected');
      return;
    }

    print('Connecting to: $baseUrl');
    print('Token: ${token.substring(0, 20)}...');

    _socket = IO.io(
      baseUrl,
      IO.OptionBuilder()
          .setTransports(['websocket'])
          .disableAutoConnect()
          .setAuth({'token': token})
          .build(),
    );

    _socket!.connect();

    _socket!.onConnect((_) {
      isConnected.value = true;
      print('✅ Socket connected');
      getConversations();
    });

    _socket!.onDisconnect((_) {
      isConnected.value = false;
      print('❌ Socket disconnected');
    });

    _socket!.onConnectError((data) {
      print('❌ Connection Error: $data');
    });

    _socket!.onError((data) {
      print('❌ Socket Error: $data');
    });

    // Listen to conversations
    _socket!.on('conversations', (data) {
      print('📋 Conversations received: $data');
      onConversations?.call(List.from(data));
    });

    // Listen to messages
    _socket!.on('messages', (data) {
      print('💬 Messages received: $data');
      onMessages?.call(List.from(data));
    });

    // Listen to new message
    _socket!.on('message', (data) {
      print('📩 New message: $data');
      onMessage?.call(data);
    });

    // Listen to unread count
    _socket!.on('unread_count', (data) {
      print('🔔 Unread count: $data');
      if (data is Map && data['unreadCount'] != null) {
        onUnreadCount?.call(data['unreadCount']);
      }
    });
  }

  void joinChat(String otherUserId) {
    if (_socket == null || !_socket!.connected) {
      print('❌ Socket not connected, cannot join chat');
      return;
    }
    print('🔗 Joining chat with: $otherUserId');
    _socket!.emit('join_chat', {'otherUserId': otherUserId});
    _socket!.emit('getMessages', {'otherUserId': otherUserId});
  }

  void sendMessage(String otherUserId, String message) {
    if (_socket == null || !_socket!.connected) {
      print('❌ Socket not connected, cannot send message');
      return;
    }
    print('📤 Sending message to: $otherUserId');
    _socket!.emit('send_message', {
      'toUserId': otherUserId,
      'message': message,
    });
  }

  void getConversations() {
    if (_socket == null || !_socket!.connected) {
      print('❌ Socket not connected, cannot get conversations');
      return;
    }
    print('📋 Getting conversations');
    _socket!.emit('getConversations');
  }

  void markAsRead(String otherUserId) {
    if (_socket == null || !_socket!.connected) {
      print('❌ Socket not connected, cannot mark as read');
      return;
    }
    _socket!.emit('mark_read', {'otherUserId': otherUserId});
  }

  void disconnect() {
    _socket?.disconnect();
    _socket?.dispose();
    _socket = null;
    isConnected.value = false;
    print('🔌 Socket disconnected and disposed');
  }

  @override
  void onClose() {
    disconnect();
    super.onClose();
  }
}