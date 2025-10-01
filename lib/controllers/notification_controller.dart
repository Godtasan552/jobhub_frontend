import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import '../model/notification_model.dart';
import '../services/socket_service.dart';
import '../services/notification_service.dart';

class NotificationController extends GetxController {
  final SocketService _socketService = SocketService();
  final GetStorage _storage = GetStorage();
  
  // Observable variables
  var notifications = <NotificationModel>[].obs;
  var unreadCount = 0.obs;
  var isLoading = false.obs;
  var isConnected = false.obs;
  
  String? _accessToken;

  @override
  void onInit() {
    super.onInit();
    _initializeNotifications();
  }

  // เริ่มต้น Notification System
  void _initializeNotifications() {
    // ดึง accessToken จาก GetStorage
    _accessToken = _storage.read('accessToken');
    
    if (_accessToken == null || _accessToken!.isEmpty) {
      print('⚠️ No access token found');
      return;
    }

    print('✅ Access Token found: ${_accessToken!.substring(0, 20)}...');
    
    // เชื่อมต่อ Socket
    _socketService.connect(_accessToken!);

    // ตั้งค่า callbacks
    _socketService.onNotificationReceived = (notification) {
      notifications.insert(0, notification);
      unreadCount.value++;
      
      // แสดง snackbar เมื่อมีการแจ้งเตือนใหม่
      Get.snackbar(
        notification.title,
        notification.message,
        snackPosition: SnackPosition.TOP,
        duration: const Duration(seconds: 3),
      );
    };

    _socketService.onUnreadCountChanged = (count) {
      unreadCount.value = count;
    };

    _socketService.onNotificationRead = (notificationId) {
      final index = notifications.indexWhere((n) => n.id == notificationId);
      if (index != -1) {
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
      }
    };

    // ✅ แก้ไขตรงนี้: อัพเดทสถานะการเชื่อมต่อ
    ever(_socketService.isConnected, (connected) {
      isConnected.value = connected; // ✅ ใช้ .value
    });

    // โหลดข้อมูลเริ่มต้น
    loadNotifications();
    loadUnreadCount();
  }

  // ... โค้ดส่วนอื่นๆ เหมือนเดิม
  
  // โหลดการแจ้งเตือนทั้งหมด
  Future<void> loadNotifications() async {
    if (_accessToken == null) return;
    
    isLoading.value = true;

    try {
      final result = await NotificationService.getNotifications(_accessToken!);
      notifications.value = result;
    } catch (e) {
      print('Error loading notifications: $e');
      Get.snackbar(
        'ข้อผิดพลาด',
        'ไม่สามารถโหลดการแจ้งเตือนได้',
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isLoading.value = false;
    }
  }

  // โหลดจำนวนที่ยังไม่อ่าน
  Future<void> loadUnreadCount() async {
    if (_accessToken == null) return;

    try {
      final count = await NotificationService.getUnreadCount(_accessToken!);
      unreadCount.value = count;
    } catch (e) {
      print('Error loading unread count: $e');
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
          }
        }
        
        // ส่งผ่าน Socket ด้วย
        for (var id in notificationIds) {
          _socketService.markAsRead(id);
        }
      }
    } catch (e) {
      print('Error marking as read: $e');
      Get.snackbar(
        'ข้อผิดพลาด',
        'ไม่สามารถทำเครื่องหมายว่าอ่านแล้วได้',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  // ลบการแจ้งเตือน
  Future<void> deleteNotification(String notificationId) async {
    if (_accessToken == null) return;

    try {
      final success = await NotificationService.deleteNotification(_accessToken!, notificationId);
      if (success) {
        final index = notifications.indexWhere((n) => n.id == notificationId);
        if (index != -1) {
          if (!notifications[index].read && unreadCount.value > 0) {
            unreadCount.value--;
          }
          notifications.removeAt(index);
        }
      }
    } catch (e) {
      print('Error deleting notification: $e');
      Get.snackbar(
        'ข้อผิดพลาด',
        'ไม่สามารถลบการแจ้งเตือนได้',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  @override
  void onClose() {
    _socketService.disconnect();
    super.onClose();
  }
}