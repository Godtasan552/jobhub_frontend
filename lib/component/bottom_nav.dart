import 'package:flutter/material.dart';
import 'package:form_validate/screens/dashboard_Screen.dart';

class BottomNav extends StatefulWidget {
  const BottomNav({super.key});

  @override
  _BottomNavState createState() => _BottomNavState();
}

class _BottomNavState extends State<BottomNav> {
  int _selectedIndex = 0;

  final List<Widget> _pages = [
    const dashboardScreen(),
    Center(child: Text("ค้นหา")),
    Center(child: Text("โปรไฟล์")),
    Center(child: Text("การตั้งค่า")),
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
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: "หน้าแรก",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.search),
            label: "สร้างงาน",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: "โปรไฟล์",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            label: "ตั้งค่า",
          ),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.blue,
        onTap: _onItemTapped,
      ),
    );
  }
}
