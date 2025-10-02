import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/notification_controller.dart';
import '../screens/notification_screen.dart';

class NotificationBadge extends StatelessWidget {
  const NotificationBadge({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // ✅ ใช้ Get.find แทน Provider
    final NotificationController controller = Get.find<NotificationController>();

    return Obx(() {
      // ✅ Obx จะ rebuild อัตโนมัติเมื่อ unreadCount เปลี่ยน
      return Stack(
        children: [
          IconButton(
            icon: const Icon(Icons.notifications),
            onPressed: () {
              // ✅ ใช้ Get.to แทน Navigator.push
              Get.to(() => const NotificationScreen());
            },
          ),
          if (controller.unreadCount.value > 0)
            Positioned(
              right: 8,
              top: 8,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: const BoxDecoration(
                  color: Colors.red,
                  shape: BoxShape.circle,
                ),
                constraints: const BoxConstraints(
                  minWidth: 20,
                  minHeight: 20,
                ),
                child: Text(
                  controller.unreadCount.value > 99 
                      ? '99+' 
                      : '${controller.unreadCount.value}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
        ],
      );
    });
  }
}