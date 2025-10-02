import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../screens/dashboard_Screen.dart';
import '../screens/create_job.dart';
import '../screens/notification_screen.dart';
import '../screens/profilePage.dart';
import '../controllers/notification_controller.dart';

class BottomNav extends StatefulWidget {
  const BottomNav({super.key});

  @override
  State<BottomNav> createState() => _BottomNavState();
}

class _BottomNavState extends State<BottomNav> with TickerProviderStateMixin {
  int _currentIndex = 0;
  final NotificationController notificationController = Get.find<NotificationController>();
  late AnimationController _fabAnimationController;
  late Animation<double> _fabScaleAnimation;

  final List<Widget> _pages = [
    const DashboardScreen(),
    const CreateJobScreen(),
    const Center(child: Text("Chat ยังไม่ทำ")),
    const NotificationScreen(),
    const ProfilePage(),
  ];

  @override
  void initState() {
    super.initState();
    _fabAnimationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _fabScaleAnimation = Tween<double>(begin: 1.0, end: 0.85).animate(
      CurvedAnimation(parent: _fabAnimationController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _fabAnimationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 250),
        switchInCurve: Curves.easeInOut,
        switchOutCurve: Curves.easeInOut,
        transitionBuilder: (child, animation) {
          return FadeTransition(
            opacity: animation,
            child: child,
          );
        },
        child: _pages[_currentIndex],
      ),
      extendBody: true,
      floatingActionButton: ScaleTransition(
        scale: _fabScaleAnimation,
        child: FloatingActionButton(
          onPressed: () {
            _fabAnimationController.forward().then((_) {
              _fabAnimationController.reverse();
              setState(() => _currentIndex = 1);
            });
          },
          backgroundColor: const Color(0xFF3B82F6),
          elevation: 8,
          child: const Icon(Icons.add_rounded, size: 30, color: Colors.white),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 20,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          child: BottomAppBar(
            height: 68,
            color: Colors.white,
            shape: const CircularNotchedRectangle(),
            notchMargin: 8,
            child: Obx(() {
              return Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildNavItem(Icons.home_rounded, "หน้าหลัก", 0),
                  _buildNavItem(Icons.chat_bubble_rounded, "แชท", 2),
                  const SizedBox(width: 56), // Space for FAB
                  _buildNotificationItem(3),
                  _buildNavItem(Icons.person_rounded, "โปรไฟล์", 4),
                ],
              );
            }),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(IconData icon, String label, int index) {
    final selected = _currentIndex == index;
    return Expanded(
      child: InkWell(
        onTap: () => setState(() => _currentIndex = index),
        splashColor: const Color(0xFF3B82F6).withOpacity(0.1),
        highlightColor: Colors.transparent,
        child: SizedBox(
          height: 68,
          child: Column(
            mainAxisSize: MainAxisSize.max,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: selected 
                      ? const Color(0xFF3B82F6).withOpacity(0.1)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  icon,
                  color: selected ? const Color(0xFF3B82F6) : Colors.grey[500],
                  size: 22,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                label,
                style: TextStyle(
                  color: selected ? const Color(0xFF3B82F6) : Colors.grey[500],
                  fontSize: 10,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                  height: 1.0,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNotificationItem(int index) {
    final selected = _currentIndex == index;
    return Expanded(
      child: InkWell(
        onTap: () => setState(() => _currentIndex = index),
        splashColor: const Color(0xFF3B82F6).withOpacity(0.1),
        highlightColor: Colors.transparent,
        child: SizedBox(
          height: 68,
          child: Column(
            mainAxisSize: MainAxisSize.max,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: selected 
                          ? const Color(0xFF3B82F6).withOpacity(0.1)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      selected ? Icons.notifications_rounded : Icons.notifications_outlined,
                      color: selected ? const Color(0xFF3B82F6) : Colors.grey[500],
                      size: 22,
                    ),
                  ),
                  if (notificationController.unreadCount.value > 0)
                    Positioned(
                      right: -2,
                      top: -2,
                      child: Container(
                        padding: const EdgeInsets.all(2.5),
                        constraints: const BoxConstraints(minWidth: 15, minHeight: 15),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFFEF4444), Color(0xFFDC2626)],
                          ),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFFEF4444).withOpacity(0.4),
                              blurRadius: 4,
                              offset: const Offset(0, 1),
                            ),
                          ],
                        ),
                        child: Center(
                          child: Text(
                            notificationController.unreadCount.value > 9
                                ? '9+'
                                : notificationController.unreadCount.value.toString(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 7.5,
                              fontWeight: FontWeight.bold,
                              height: 1.0,
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 3),
              Text(
                "แจ้งเตือน",
                style: TextStyle(
                  color: selected ? const Color(0xFF3B82F6) : Colors.grey[500],
                  fontSize: 10,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                  height: 1.0,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}