// lib/widgets/notification_badge.dart
// Widget สำหรับแสดง Badge การแจ้งเตือนที่สามารถนำไปใช้ซ้ำได้

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/notification_controller.dart';

class NotificationBadge extends StatelessWidget {
  final VoidCallback? onTap;
  final double iconSize;
  final Color? iconColor;

  const NotificationBadge({
    super.key,
    this.onTap,
    this.iconSize = 24,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    final notificationController = Get.find<NotificationController>();

    return Stack(
      clipBehavior: Clip.none,
      children: [
        IconButton(
          icon: Icon(
            Icons.notifications,
            size: iconSize,
            color: iconColor,
          ),
          onPressed: onTap,
        ),
        Obx(() {
          final count = notificationController.unreadCount.value;
          return count > 0
              ? Positioned(
                  right: 8,
                  top: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: Colors.white,
                        width: 1.5,
                      ),
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 18,
                      minHeight: 18,
                    ),
                    child: Text(
                      count > 99 ? '99+' : count.toString(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                )
              : const SizedBox.shrink();
        }),
      ],
    );
  }
}

// ตัวอย่างการใช้งาน:
// NotificationBadge(
//   onTap: () => Get.toNamed(AppRoutes.NOTIFICATION),
// )