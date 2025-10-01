// lib/views/notification_view.dart

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/notification_controller.dart';
import '../model/notification_model.dart';

class NotificationView extends GetView<NotificationController> {
  const NotificationView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('การแจ้งเตือน'),
        actions: [
          // Badge แสดงจำนวนที่ยังไม่อ่าน
          Obx(() {
            final count = controller.unreadCount.value;
            return count > 0
                ? Padding(
                    padding: const EdgeInsets.only(right: 8.0),
                    child: Center(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.red,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          count > 99 ? '99+' : count.toString(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  )
                : const SizedBox.shrink();
          }),
          // ปุ่มทำเครื่องหมายทั้งหมดว่าอ่านแล้ว
          Obx(() {
            return controller.unreadCount.value > 0
                ? IconButton(
                    icon: const Icon(Icons.done_all),
                    tooltip: 'ทำเครื่องหมายทั้งหมดว่าอ่านแล้ว',
                    onPressed: controller.markAllAsRead,
                  )
                : const SizedBox.shrink();
          }),
          // ปุ่ม Refresh
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'รีเฟรช',
            onPressed: controller.refreshNotifications,
          ),
        ],
      ),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }

        if (controller.notifications.isEmpty) {
          return _buildEmptyState();
        }

        return RefreshIndicator(
          onRefresh: controller.refreshNotifications,
          child: ListView.builder(
            padding: const EdgeInsets.all(8),
            itemCount: controller.notifications.length,
            itemBuilder: (context, index) {
              final notification = controller.notifications[index];
              return _buildNotificationCard(notification);
            },
          ),
        );
      }),
    );
  }

  // แสดงเมื่อไม่มีการแจ้งเตือน
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.notifications_none,
            size: 80,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'ไม่มีการแจ้งเตือน',
            style: TextStyle(
              fontSize: 20,
              color: Colors.grey[600],
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'คุณไม่มีการแจ้งเตือนใดๆ ในขณะนี้',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }

  // การ์ดแสดงการแจ้งเตือนแต่ละอัน
  Widget _buildNotificationCard(NotificationModel notification) {
    return Dismissible(
      key: Key(notification.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        color: Colors.red,
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      confirmDismiss: (direction) async {
        await controller.deleteNotification(notification.id);
        return false; // ให้ controller จัดการลบเอง
      },
      child: Card(
        margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 0),
        elevation: notification.read ? 0 : 2,
        color: notification.read ? Colors.grey[50] : Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(
            color: notification.read ? Colors.grey[300]! : Colors.blue[100]!,
            width: notification.read ? 0.5 : 1.5,
          ),
        ),
        child: InkWell(
          onTap: () async {
            if (!notification.read) {
              await controller.markAsRead(notification.id);
            }
            
            // นำทางไปยัง actionUrl หากมี
            if (notification.actionUrl != null) {
              // TODO: นำทางไปยังหน้าที่เกี่ยวข้อง
              Get.snackbar(
                'ข้อมูล',
                'นำทางไปยัง: ${notification.actionUrl}',
                snackPosition: SnackPosition.BOTTOM,
              );
            }
          },
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ไอคอนตามประเภท
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: notification.read
                        ? Colors.grey[200]
                        : Colors.blue[50],
                    borderRadius: BorderRadius.circular(25),
                  ),
                  child: Center(
                    child: Text(
                      notification.iconType,
                      style: const TextStyle(fontSize: 24),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                // เนื้อหา
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              notification.title,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: notification.read
                                    ? FontWeight.normal
                                    : FontWeight.bold,
                                color: notification.read
                                    ? Colors.grey[700]
                                    : Colors.black,
                              ),
                            ),
                          ),
                          // จุดสีน้ำเงินสำหรับที่ยังไม่อ่าน
                          if (!notification.read)
                            Container(
                              width: 8,
                              height: 8,
                              decoration: const BoxDecoration(
                                color: Colors.blue,
                                shape: BoxShape.circle,
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        notification.message,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            notification.timeAgo,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[500],
                            ),
                          ),
                          // แสดงประเภท
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: _getTypeColor(notification.type),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              _getTypeText(notification.type),
                              style: const TextStyle(
                                fontSize: 10,
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // สีตามประเภท
  Color _getTypeColor(String type) {
    switch (type) {
      case 'job':
        return Colors.blue;
      case 'milestone':
        return Colors.orange;
      case 'payment':
        return Colors.green;
      case 'chat':
        return Colors.purple;
      case 'worker_approval':
        return Colors.teal;
      case 'system':
      default:
        return Colors.grey;
    }
  }

  // ข้อความตามประเภท
  String _getTypeText(String type) {
    switch (type) {
      case 'job':
        return 'งาน';
      case 'milestone':
        return 'เป้าหมาย';
      case 'payment':
        return 'การเงิน';
      case 'chat':
        return 'แชท';
      case 'worker_approval':
        return 'อนุมัติ';
      case 'system':
      default:
        return 'ระบบ';
    }
  }
}