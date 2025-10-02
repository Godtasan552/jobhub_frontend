// lib/controllers/notification_controller.dart

import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import '../model/notification_model.dart';
import '../services/socket_service.dart';
import '../services/notification_service.dart';

class NotificationController extends GetxController {
  final SocketService _socketService = SocketService();
  final GetStorage _storage = GetStorage();
  
  var notifications = <NotificationModel>[].obs;
  var unreadCount = 0.obs;
  var isLoading = false.obs;
  var isConnected = false.obs;
  
  String? _accessToken;

  @override
  void onInit() {
    super.onInit();
    print('🎯 [NotificationController] Initializing...');
    _initializeNotifications();
  }

  void _initializeNotifications() {
  print('🎯 [NotificationController] Starting initialization');
  
  final accessToken = _storage.read('token');

  if (accessToken == null || accessToken.isEmpty) {
    print('⚠️ [NotificationController] No access token found');
    return;
  }

  _accessToken = accessToken; // ✅ เก็บไว้ใช้ต่อ

  print('✅ [NotificationController] Access Token found: ${_accessToken!.substring(0, 20)}...');

  // เชื่อมต่อ Socket
  print('🔌 [NotificationController] Connecting to Socket.IO...');
  _socketService.connect(_accessToken!);

  // ตั้งค่า callbacks
  _socketService.onNotificationReceived = (notification) {
    print('📨 [NotificationController] New notification received: ${notification.title}');
    notifications.insert(0, notification);
    unreadCount.value++;

    print('📊 [NotificationController] Updated counts - Total: ${notifications.length}, Unread: ${unreadCount.value}');
    
    Get.snackbar(
      notification.title,
      notification.message,
      snackPosition: SnackPosition.TOP,
      duration: const Duration(seconds: 3),
    );
  };

  _socketService.onUnreadCountChanged = (count) {
    print('📊 [NotificationController] Unread count changed: $count');
    unreadCount.value = count;
  };

  _socketService.onNotificationRead = (notificationId) {
    print('✅ [NotificationController] Notification marked as read: $notificationId');
    final index = notifications.indexWhere((n) => n.id == notificationId);
    if (index != -1) {
      final notification = notifications[index];
      notifications[index] = notification.copyWith(
        read: true,
        readAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      if (unreadCount.value > 0) unreadCount.value--;
      print('📊 [NotificationController] New unread count: ${unreadCount.value}');
    }
  };

  // อัพเดทสถานะการเชื่อมต่อ
  ever(_socketService.isConnected, (connected) {
    print('🔌 [NotificationController] Socket connection status changed: $connected');
    isConnected.value = connected;
  });

  // โหลดข้อมูลเริ่มต้น
  print('📥 [NotificationController] Loading initial data...');
  loadNotifications();
  loadUnreadCount();
}


  Future<void> loadNotifications() async {
    print('📥 [NotificationController] loadNotifications() called');
    
    if (_accessToken == null) {
      print('⚠️ [NotificationController] No access token, skipping load');
      return;
    }
    
    isLoading.value = true;
    print('⏳ [NotificationController] Loading notifications from API...');

    try {
      final result = await NotificationService.getNotifications(_accessToken!);
      print('✅ [NotificationController] Received ${result.length} notifications from API');
      
      if (result.isNotEmpty) {
        print('📋 [NotificationController] First notification:');
        print('   ID: ${result[0].id}');
        print('   Title: ${result[0].title}');
        print('   Read: ${result[0].read}');
      }
      
      notifications.value = result;
      print('📊 [NotificationController] Updated local notifications list: ${notifications.length} items');
      
    } catch (e) {
      print('❌ [NotificationController] Error loading notifications: $e');
      print('   Stack trace: ${StackTrace.current}');
      Get.snackbar(
        'ข้อผิดพลาด',
        'ไม่สามารถโหลดการแจ้งเตือนได้: $e',
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isLoading.value = false;
      print('✅ [NotificationController] Loading completed. isLoading = false');
    }
  }

  Future<void> loadUnreadCount() async {
    print('📥 [NotificationController] loadUnreadCount() called');
    
    if (_accessToken == null) {
      print('⚠️ [NotificationController] No access token, skipping load');
      return;
    }

    try {
      final count = await NotificationService.getUnreadCount(_accessToken!);
      print('✅ [NotificationController] Unread count from API: $count');
      unreadCount.value = count;
    } catch (e) {
      print('❌ [NotificationController] Error loading unread count: $e');
    }
  }

  Future<void> markAsRead(List<String> notificationIds) async {
    print('✅ [NotificationController] markAsRead() called with ${notificationIds.length} IDs');
    print('   IDs: $notificationIds');
    
    if (_accessToken == null) {
      print('⚠️ [NotificationController] No access token, skipping');
      return;
    }

    try {
      final success = await NotificationService.markAsRead(_accessToken!, notificationIds);
      print('📡 [NotificationController] API response: $success');
      
      if (success) {
        print('✅ [NotificationController] Updating local state...');
        for (var id in notificationIds) {
          final index = notifications.indexWhere((n) => n.id == id);
          if (index != -1 && !notifications[index].read) {
            final notification = notifications[index];
            notifications[index] = NotificationModel(
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
            if (unreadCount.value > 0) unreadCount.value--;
            print('   ✅ Marked as read: $id');
          }
        }
        
        // ส่งผ่าน Socket
        for (var id in notificationIds) {
          _socketService.markAsRead(id);
        }
        
        print('📊 [NotificationController] Final unread count: ${unreadCount.value}');
      }
    } catch (e) {
      print('❌ [NotificationController] Error marking as read: $e');
      Get.snackbar(
        'ข้อผิดพลาด',
        'ไม่สามารถทำเครื่องหมายว่าอ่านแล้วได้',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  Future<void> deleteNotification(String notificationId) async {
    print('🗑️ [NotificationController] deleteNotification() called: $notificationId');
    
    if (_accessToken == null) {
      print('⚠️ [NotificationController] No access token, skipping');
      return;
    }

    try {
      final success = await NotificationService.deleteNotification(_accessToken!, notificationId);
      print('📡 [NotificationController] API response: $success');
      
      if (success) {
        final index = notifications.indexWhere((n) => n.id == notificationId);
        if (index != -1) {
          if (!notifications[index].read && unreadCount.value > 0) {
            unreadCount.value--;
          }
          notifications.removeAt(index);
          print('✅ [NotificationController] Deleted from local list. Remaining: ${notifications.length}');
        }
      }
    } catch (e) {
      print('❌ [NotificationController] Error deleting notification: $e');
      Get.snackbar(
        'ข้อผิดพลาด',
        'ไม่สามารถลบการแจ้งเตือนได้',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  @override
  void onClose() {
    print('🔌 [NotificationController] Closing and disconnecting Socket');
    _socketService.disconnect();
    super.onClose();
  }
}