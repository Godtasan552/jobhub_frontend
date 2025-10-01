// lib/services/socket_service.dart
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:flutter/foundation.dart';
import 'package:get/get.dart'; // ✅ เพิ่ม
import '../model/notification_model.dart';

class SocketService {
  static final SocketService _instance = SocketService._internal();
  factory SocketService() => _instance;
  SocketService._internal();

  IO.Socket? _socket;
  final String _baseUrl = 'https://jobhubbackend-production-cc57.up.railway.app';
  
  // ✅ ใช้ RxBool แทน
  var isConnected = false.obs;
  
  // Callbacks
  Function(NotificationModel)? onNotificationReceived;
  Function(int)? onUnreadCountChanged;
  Function(String)? onNotificationRead;

  // เชื่อมต่อ Socket
  void connect(String accessToken) {
    if (_socket != null && _socket!.connected) {
      debugPrint('Socket already connected');
      return;
    }

    try {
      _socket = IO.io(_baseUrl, <String, dynamic>{
        'transports': ['websocket'],
        'autoConnect': false,
        'auth': {
          'token': accessToken,
        },
      });

      _socket!.connect();

      // Event Listeners
      _socket!.onConnect((_) {
        debugPrint('✅ Socket connected');
        isConnected.value = true; // ✅ อัพเดท
      });

      _socket!.onDisconnect((_) {
        debugPrint('❌ Socket disconnected');
        isConnected.value = false; // ✅ อัพเดท
      });

      _socket!.onConnectError((error) {
        debugPrint('❌ Socket connection error: $error');
        isConnected.value = false; // ✅ อัพเดท
      });

      _socket!.onError((error) {
        debugPrint('❌ Socket error: $error');
      });

      // รับการแจ้งเตือนใหม่
      _socket!.on('notification', (data) {
        debugPrint('🔔 New notification received: $data');
        try {
          final notification = NotificationModel.fromJson(data);
          onNotificationReceived?.call(notification);
        } catch (e) {
          debugPrint('Error parsing notification: $e');
        }
      });

      // รับจำนวนการแจ้งเตือนที่ยังไม่อ่าน
      _socket!.on('unread_count', (data) {
        debugPrint('📊 Unread count: $data');
        if (data is int) {
          onUnreadCountChanged?.call(data);
        } else if (data is Map && data.containsKey('count')) {
          onUnreadCountChanged?.call(data['count']);
        }
      });

      // รับการอัพเดทว่าอ่านแล้ว
      _socket!.on('mark_notification_read', (data) {
        debugPrint('✅ Notification marked as read: $data');
        if (data is String) {
          onNotificationRead?.call(data);
        } else if (data is Map && data.containsKey('notificationId')) {
          onNotificationRead?.call(data['notificationId']);
        }
      });

    } catch (e) {
      debugPrint('❌ Error connecting socket: $e');
    }
  }

  // ตัดการเชื่อมต่อ
  void disconnect() {
    if (_socket != null) {
      _socket!.disconnect();
      _socket!.dispose();
      _socket = null;
      isConnected.value = false; // ✅ อัพเดท
      debugPrint('Socket disconnected and disposed');
    }
  }

  // ส่ง event เพื่อทำเครื่องหมายว่าอ่านแล้ว
  void markAsRead(String notificationId) {
    if (_socket != null && _socket!.connected) {
      _socket!.emit('mark_notification_read', {'notificationId': notificationId});
    }
  }

  // ขอจำนวนการแจ้งเตือนที่ยังไม่อ่าน
  void requestUnreadCount() {
    if (_socket != null && _socket!.connected) {
      _socket!.emit('get_unread_count');
    }
  }
}