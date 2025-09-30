
import 'package:flutter/material.dart';
import 'package:form_validate/screens/create_job.dart';
import 'package:form_validate/screens/dashboard_Screen.dart';
import 'package:get/get.dart';

class BottomNav extends StatefulWidget {
  final int initialIndex; // เพิ่มพารามิเตอร์นี้
  
  const BottomNav({super.key, this.initialIndex = 0});

  @override
      State<BottomNav> createState() => _BottomNavState(); // แก้ตรงนี้ด้วย
}

class _BottomNavState extends State<BottomNav> {
  late int _selectedIndex;

  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.initialIndex; // ใช้ค่าที่ส่งมา
  }

  final List<Widget> _pages = [
    const DashboardScreen(),
    const CreateJobScreen(),
    const Center(child: Text("Chat")),
    const Center(child: Text("Notification")),
    const Center(child: Text("Notification")),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_selectedIndex],
      bottomNavigationBar: buildBottomNavigationBar(_selectedIndex, _onItemTapped),
    );
  }
}

// สร้าง static method สำหรับสร้าง BottomNavigationBar
BottomNavigationBar buildBottomNavigationBar(int currentIndex, Function(int) onTap) {
  return BottomNavigationBar(
    type: BottomNavigationBarType.fixed,
    currentIndex: currentIndex,
    selectedItemColor: Colors.blue,
    unselectedItemColor: Colors.grey,
    onTap: onTap,
    items: const [
      BottomNavigationBarItem(
        icon: Icon(Icons.home),
        label: "หน้าแรก",
      ),
      BottomNavigationBarItem(
        icon: Icon(Icons.add_circle_outline),
        label: "สร้างงาน",
      ),
      BottomNavigationBarItem(
        icon: Icon(Icons.chat),
        label: "แชท",
      ),
      BottomNavigationBarItem(
        icon: Icon(Icons.notifications),
        label: "แจ้งเตือน",
      ),
      BottomNavigationBarItem(
        icon: Icon(Icons.person),
        label: "โปรไฟล์",
      ),
    ],
  );
}