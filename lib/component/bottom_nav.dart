// lib/component/bottom_nav.dart

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../screens/dashboard_screen.dart';
import '../screens/create_job.dart';
import '../screens/notification.dart';
import '../screens/profilePage.dart';
import '../controllers/notification_controller.dart';

class BottomNav extends StatefulWidget {
  const BottomNav({super.key});

  @override
  State<BottomNav> createState() => _BottomNavState();
}

class _BottomNavState extends State<BottomNav> {
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    
    // ✅ Debug และสร้าง NotificationController
    print('🔍 BottomNav initialized - checking NotificationController...');
    
    if (!Get.isRegistered<NotificationController>()) {
      Get.put(NotificationController());
      print('✅ NotificationController created in BottomNav');
    } else {
      print('ℹ️ NotificationController already exists');
    }
  }

  // ✅ 5 หน้าเหมือนโค้ดแรก
  final List<Widget> _pages = [
    const DashboardScreen(),
    const CreateJobScreen(),
    const Center(child: Text("Chat ยังไม่ทำ", style: TextStyle(fontSize: 18))),
    const NotificationView(),
    const ProfilePage(),
  ];

  @override
  Widget build(BuildContext context) {
    final notificationController = Get.find<NotificationController>();

    return Scaffold(
      body: _pages[_currentIndex],
      bottomNavigationBar: Obx(() {
        return BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (index) {
            setState(() {
              _currentIndex = index;
            });
          },
          type: BottomNavigationBarType.fixed,
          selectedItemColor: Colors.blue,
          unselectedItemColor: Colors.grey,
          items: [
            const BottomNavigationBarItem(
              icon: Icon(Icons.home),
              label: "Home",
            ),
            const BottomNavigationBarItem(
              icon: Icon(Icons.search),
              label: "Create Job",
            ),
            const BottomNavigationBarItem(
              icon: Icon(Icons.chat),
              label: "Chat",
            ),
            BottomNavigationBarItem(
              icon: Stack(
                clipBehavior: Clip.none,
                children: [
                  const Icon(Icons.notifications),
                  // ✅ Badge แสดงจำนวนแจ้งเตือนที่ยังไม่อ่าน
                  if (notificationController.unreadCount.value > 0)
                    Positioned(
                      right: -6,
                      top: -4,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                        ),
                        constraints: const BoxConstraints(
                          minWidth: 16,
                          minHeight: 16,
                        ),
                        child: Text(
                          notificationController.unreadCount.value > 9
                              ? '9+'
                              : notificationController.unreadCount.value.toString(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 8,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                ],
              ),
              label: "Notification",
            ),
            const BottomNavigationBarItem(
              icon: Icon(Icons.person),
              label: "Profile",
            ),
          ],
        );
      }),
    );
  }
}