import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:get/get.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;

class ChatController {
  static final ChatController _instance = ChatController._internal();
  factory ChatController() => _instance;
  ChatController._internal();

  IO.Socket? _socket;

  var isConnected = false.obs;

  // Callbacks
  Function(dynamic)? onMessage;
  Function(List)? onMessages;
  Function(List)? onConversations;

  static final String baseUrl = dotenv.env['BASE_URL'] ?? '';

  void connect(String token) {
    if (_socket != null && _socket!.connected) return;

    _socket = IO.io(baseUrl, <String, dynamic>{
      'transports': ['websocket'],
      'autoConnect': false,
      'auth': {'token': token},
    });

    _socket!.connect();


    _socket!.onConnect((_) {
      isConnected.value = true;
      print('================== Socket connected ==================');
      getConversations();
      
    });

    _socket!.onDisconnect((_) {
      isConnected.value = false;
      print('Socket disconnected');
    });

    _socket!.on('conversations', (data) {
      print('Conversations: $data');
      onConversations?.call(List.from(data));
    });

    _socket!.on('messages', (data) {
      print('Messages: $data');
      onMessages?.call(List.from(data));
    });

    _socket!.on('message', (data) {
      print('New message: $data');
      onMessage?.call(data);
    });
  }

  void joinChat(String otherUserId) {
    _socket?.emit('joinChat', {'otherUserId': otherUserId});
    _socket?.emit('getMessages', {'otherUserId': otherUserId});
    getConversations();
  }

  void sendMessage(String otherUserId, String message) {
    _socket?.emit('sendMessage', {'toUserId': otherUserId, 'message': message});
    if (_socket != null && _socket!.connected){
      _socket!.emit('sendMessage', {'toUserId': otherUserId, 'message': message});
    } else {
      print('Socket not connected, cannot send message');
    }
  }

  void getConversations() {
    _socket?.emit('getConversations');
  }

  void disconnect() {
    _socket?.disconnect();
    _socket?.dispose();
    _socket = null;
    isConnected.value = false;
  }
}
