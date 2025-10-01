import 'package:flutter/material.dart';
import '../model/notification_model.dart';
import '../services/socket_service.dart';
import '../services/notification_service.dart';

class NotificationProvider with ChangeNotifier {
  final SocketService _socketService = SocketService();
  List<NotificationModel> _notifications = [];
  int _unreadCount = 0;
  bool _isLoading = false;
  String? _accessToken;

  List<NotificationModel> get notifications => _notifications;
  int get unreadCount => _unreadCount;
  bool get isLoading => _isLoading;
  bool get isConnected => _socketService.isConnected;

  // เริ่มต้น Socket
  void initialize(String accessToken) {
    _accessToken = accessToken;
    
    // เชื่อมต่อ Socket
    _socketService.connect(accessToken);

    // ตั้งค่า callbacks
    _socketService.onNotificationReceived = (notification) {
      _notifications.insert(0, notification);
      _unreadCount++;
      notifyListeners();
    };

    _socketService.onUnreadCountChanged = (count) {
      _unreadCount = count;
      notifyListeners();
    };

    _socketService.onNotificationRead = (notificationId) {
      final index = _notifications.indexWhere((n) => n.id == notificationId);
      if (index != -1) {
        final updatedList = List<NotificationModel>.from(_notifications);
        // สร้าง notification ใหม่ที่มี read = true
        final notification = updatedList[index];
        updatedList[index] = NotificationModel(
          id: notification.id,
          userId: notification.userId,
          type: notification.type,
          title: notification.title,
          message: notification.message,
          referenceId: notification.referenceId,
          referenceType: notification.referenceType,
          read: true,
          readAt: DateTime.now(),
          actionUrl: notification.actionUrl,
          createdAt: notification.createdAt,
          updatedAt: DateTime.now(),
        );
        _notifications = updatedList;
        if (_unreadCount > 0) _unreadCount--;
        notifyListeners();
      }
    };

    // โหลดข้อมูลเริ่มต้น
    loadNotifications();
    loadUnreadCount();
  }

  // โหลดการแจ้งเตือนทั้งหมด
  Future<void> loadNotifications() async {
    if (_accessToken == null) return;
    
    _isLoading = true;
    notifyListeners();

    try {
      _notifications = await NotificationService.getNotifications(_accessToken!);
    } catch (e) {
      debugPrint('Error loading notifications: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // โหลดจำนวนที่ยังไม่อ่าน
  Future<void> loadUnreadCount() async {
    if (_accessToken == null) return;

    try {
      _unreadCount = await NotificationService.getUnreadCount(_accessToken!);
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading unread count: $e');
    }
  }

  // ทำเครื่องหมายว่าอ่านแล้ว
  Future<void> markAsRead(List<String> notificationIds) async {
    if (_accessToken == null) return;

    try {
      final success = await NotificationService.markAsRead(_accessToken!, notificationIds);
      if (success) {
        // อัพเดท local state
        for (var id in notificationIds) {
          final index = _notifications.indexWhere((n) => n.id == id);
          if (index != -1 && !_notifications[index].read) {
            final updatedList = List<NotificationModel>.from(_notifications);
            final notification = updatedList[index];
            updatedList[index] = NotificationModel(
              id: notification.id,
              userId: notification.userId,
              type: notification.type,
              title: notification.title,
              message: notification.message,
              referenceId: notification.referenceId,
              referenceType: notification.referenceType,
              read: true,
              readAt: DateTime.now(),
              actionUrl: notification.actionUrl,
              createdAt: notification.createdAt,
              updatedAt: DateTime.now(),
            );
            _notifications = updatedList;
            if (_unreadCount > 0) _unreadCount--;
          }
        }
        notifyListeners();
        
        // ส่งผ่าน Socket ด้วย (ถ้า backend support)
        for (var id in notificationIds) {
          _socketService.markAsRead(id);
        }
      }
    } catch (e) {
      debugPrint('Error marking as read: $e');
    }
  }

  // ลบการแจ้งเตือน
  Future<void> deleteNotification(String notificationId) async {
    if (_accessToken == null) return;

    try {
      final success = await NotificationService.deleteNotification(_accessToken!, notificationId);
      if (success) {
        final index = _notifications.indexWhere((n) => n.id == notificationId);
        if (index != -1) {
          if (!_notifications[index].read && _unreadCount > 0) {
            _unreadCount--;
          }
          _notifications.removeAt(index);
          notifyListeners();
        }
      }
    } catch (e) {
      debugPrint('Error deleting notification: $e');
    }
  }

  // ตัดการเชื่อมต่อ
  void dispose() {
    _socketService.disconnect();
    super.dispose();
  }
}