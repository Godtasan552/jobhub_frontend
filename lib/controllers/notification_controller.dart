// lib/controllers/notification_controller.dart

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../model/notification_model.dart'; // ✅ เปลี่ยนเป็น model (เอกพจน์)
import '../services/notification_service.dart';

class NotificationController extends GetxController {
  final NotificationService _notificationService = NotificationService();

  // Observable Variables
  var notifications = <NotificationModel>[].obs;
  var unreadCount = 0.obs;
  var isLoading = false.obs;
  var isRefreshing = false.obs;

  // Timer สำหรับ auto-refresh
  Timer? _autoRefreshTimer;

  @override
  void onInit() {
    super.onInit();
    
    // เพิ่ม delay เล็กน้อยเพื่อให้ GetStorage พร้อมก่อน
    Future.delayed(const Duration(milliseconds: 500), () {
      fetchNotifications();
      startAutoRefresh();
    });
  }

  @override
  void onClose() {
    _autoRefreshTimer?.cancel();
    super.onClose();
  }

  // เริ่ม auto-refresh
  void startAutoRefresh() {
    _autoRefreshTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      fetchUnreadCount();
    });
  }

  // ดึงข้อมูลการแจ้งเตือนทั้งหมด
  Future<void> fetchNotifications() async {
    try {
      isLoading.value = true;
      final result = await _notificationService.getNotifications();
      notifications.value = result;
      await fetchUnreadCount();
    } catch (e) {
      print('❌ Error fetching notifications: $e');
      
      // ตรวจสอบว่าเป็น 401 Unauthorized หรือไม่
      if (e.toString().contains('401') || e.toString().contains('Unauthorized')) {
        Get.snackbar(
          'กรุณาเข้าสู่ระบบใหม่',
          'Session หมดอายุ กรุณาเข้าสู่ระบบอีกครั้ง',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.orange,
          colorText: Colors.white,
        );
      } else if (e.toString().contains('Connection refused') || 
                 e.toString().contains('SocketException')) {
        Get.snackbar(
          'ไม่สามารถเชื่อมต่อได้',
          'กรุณาตรวจสอบการเชื่อมต่ออินเทอร์เน็ต',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
      } else {
        Get.snackbar(
          'เกิดข้อผิดพลาด',
          'ไม่สามารถโหลดการแจ้งเตือนได้: $e',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
      }
    } finally {
      isLoading.value = false;
    }
  }

  // Refresh (Pull to Refresh)
  Future<void> refreshNotifications() async {
    try {
      isRefreshing.value = true;
      await fetchNotifications();
      Get.snackbar(
        'สำเร็จ',
        'อัปเดตข้อมูลแล้ว',
        snackPosition: SnackPosition.TOP,
        backgroundColor: Colors.green,
        colorText: Colors.white,
        duration: const Duration(seconds: 1),
      );
    } finally {
      isRefreshing.value = false;
    }
  }

  // ดึงจำนวนที่ยังไม่อ่าน
  Future<void> fetchUnreadCount() async {
    try {
      final count = await _notificationService.getUnreadCount();
      unreadCount.value = count;
    } catch (e) {
      print('❌ Error fetching unread count: $e');
    }
  }

  // ทำเครื่องหมายการแจ้งเตือนเดียวว่าอ่านแล้ว
  Future<void> markAsRead(String notificationId) async {
    try {
      final success = await _notificationService.markSingleAsRead(notificationId);
      
      if (success) {
        // อัปเดต local state
        final index = notifications.indexWhere((n) => n.id == notificationId);
        if (index != -1) {
          notifications[index] = notifications[index].copyWith(
            read: true,
            readAt: DateTime.now(),
          );
          notifications.refresh();
        }
        
        await fetchUnreadCount();
      }
    } catch (e) {
      print('❌ Error marking as read: $e');
    }
  }

  // ทำเครื่องหมายทั้งหมดว่าอ่านแล้ว
  Future<void> markAllAsRead() async {
    try {
      final success = await _notificationService.markAllAsRead(notifications);
      
      if (success) {
        // อัปเดต local state
        notifications.value = notifications.map((n) {
          return n.copyWith(read: true, readAt: DateTime.now());
        }).toList();
        
        unreadCount.value = 0;
        
        Get.snackbar(
          'สำเร็จ',
          'ทำเครื่องหมายทั้งหมดว่าอ่านแล้ว',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.green,
          colorText: Colors.white,
          duration: const Duration(seconds: 2),
        );
      }
    } catch (e) {
      Get.snackbar(
        'เกิดข้อผิดพลาด',
        'ไม่สามารถทำเครื่องหมายได้: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  // ลบการแจ้งเตือน
  Future<void> deleteNotification(String notificationId) async {
    try {
      // แสดง dialog ยืนยัน
      final confirm = await Get.dialog<bool>(
        AlertDialog(
          title: const Text('ยืนยันการลบ'),
          content: const Text('คุณต้องการลบการแจ้งเตือนนี้ใช่หรือไม่?'),
          actions: [
            TextButton(
              onPressed: () => Get.back(result: false),
              child: const Text('ยกเลิก'),
            ),
            TextButton(
              onPressed: () => Get.back(result: true),
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('ลบ'),
            ),
          ],
        ),
      );

      if (confirm == true) {
        final success = await _notificationService.deleteNotification(notificationId);
        
        if (success) {
          notifications.removeWhere((n) => n.id == notificationId);
          await fetchUnreadCount();
          
          Get.snackbar(
            'สำเร็จ',
            'ลบการแจ้งเตือนแล้ว',
            snackPosition: SnackPosition.BOTTOM,
            backgroundColor: Colors.green,
            colorText: Colors.white,
            duration: const Duration(seconds: 2),
          );
        }
      }
    } catch (e) {
      Get.snackbar(
        'เกิดข้อผิดพลาด',
        'ไม่สามารถลบการแจ้งเตือนได้: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  // กรองการแจ้งเตือนที่ยังไม่อ่าน
  List<NotificationModel> get unreadNotifications {
    return notifications.where((n) => !n.read).toList();
  }

  // กรองการแจ้งเตือนที่อ่านแล้ว
  List<NotificationModel> get readNotifications {
    return notifications.where((n) => n.read).toList();
  }
}