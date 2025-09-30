import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final storage = GetStorage();
  bool _isLoading = true;
  Map<String, dynamic>? _userData;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final token = storage.read('token');
      
      if (token == null) {
        setState(() {
          _errorMessage = 'ไม่พบ Token กรุณาเข้าสู่ระบบใหม่';
          _isLoading = false;
        });
        return;
      }

      final String baseUrl = dotenv.env['BASE_URL'] ?? 'http://localhost:5000';

      final response = await http.get(
        Uri.parse('$baseUrl/api/v1/auth/profile'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      print('Profile Response: ${response.statusCode}');
      print('Profile Body: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        if (data['success'] == true) {
          setState(() {
            _userData = data['data'];
            _isLoading = false;
          });
          
          // อัพเดท storage
          await storage.write('user', data['data']);
        } else {
          setState(() {
            _errorMessage = data['message'] ?? 'ไม่สามารถโหลดข้อมูลได้';
            _isLoading = false;
          });
        }
      } else {
        setState(() {
          _errorMessage = 'เกิดข้อผิดพลาด: ${response.statusCode}';
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading profile: $e');
      setState(() {
        _errorMessage = 'เกิดข้อผิดพลาด: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _logout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('ออกจากระบบ'),
        content: const Text('คุณต้องการออกจากระบบใช่หรือไม่?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('ยกเลิก'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('ออกจากระบบ'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await storage.remove('token');
      await storage.remove('user');
      
      Get.offAllNamed('/login');
      
      Get.snackbar(
        'สำเร็จ',
        'ออกจากระบบแล้ว',
        backgroundColor: Colors.green[100],
        colorText: Colors.green[900],
        snackPosition: SnackPosition.TOP,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_errorMessage != null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('โปรไฟล์'),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
              const SizedBox(height: 16),
              Text(
                _errorMessage!,
                style: const TextStyle(fontSize: 16),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _loadProfile,
                child: const Text('ลองอีกครั้ง'),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('โปรไฟล์'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadProfile,
            tooltip: 'รีเฟรช',
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Header Section
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.blue[700]!, Colors.blue[500]!],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              padding: const EdgeInsets.all(32),
              child: Column(
                children: [
                  // Profile Picture
                  CircleAvatar(
                    radius: 60,
                    backgroundColor: Colors.white,
                    child: _userData?['profilePic'] != null
                        ? ClipOval(
                            child: Image.network(
                              _userData!['profilePic'],
                              width: 120,
                              height: 120,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return Icon(
                                  Icons.person,
                                  size: 60,
                                  color: Colors.blue[700],
                                );
                              },
                            ),
                          )
                        : Icon(
                            Icons.person,
                            size: 60,
                            color: Colors.blue[700],
                          ),
                  ),
                  const SizedBox(height: 16),
                  
                  // Name
                  Text(
                    _userData?['name'] ?? 'ไม่มีชื่อ',
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 8),
                  
                  // Email
                  Text(
                    _userData?['email'] ?? '',
                    style: const TextStyle(
                      fontSize: 16,
                      color: Colors.white70,
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // Role Badges
                  Wrap(
                    spacing: 8,
                    children: [
                      if (_userData?['role'] != null)
                        ...(_userData!['role'] as List).map((role) {
                          return Chip(
                            label: Text(
                              role.toString().toUpperCase(),
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            backgroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                          );
                        }).toList(),
                    ],
                  ),
                ],
              ),
            ),

            // Info Section
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Wallet
                  _buildInfoCard(
                    icon: Icons.account_balance_wallet,
                    title: 'กระเป๋าเงิน',
                    value: '${_userData?['wallet'] ?? 0} บาท',
                    color: Colors.green,
                  ),
                  const SizedBox(height: 16),

                  // Phone
                  if (_userData?['phone'] != null)
                    _buildInfoCard(
                      icon: Icons.phone,
                      title: 'เบอร์โทรศัพท์',
                      value: _userData!['phone'],
                      color: Colors.blue,
                    ),
                  if (_userData?['phone'] != null) const SizedBox(height: 16),

                  // Location
                  if (_userData?['location'] != null)
                    _buildInfoCard(
                      icon: Icons.location_on,
                      title: 'ที่อยู่',
                      value: _userData!['location'],
                      color: Colors.orange,
                    ),
                  if (_userData?['location'] != null) const SizedBox(height: 16),

                  // About
                  if (_userData?['about'] != null)
                    _buildInfoCard(
                      icon: Icons.info,
                      title: 'เกี่ยวกับ',
                      value: _userData!['about'],
                      color: Colors.purple,
                    ),
                  if (_userData?['about'] != null) const SizedBox(height: 16),

                  // Worker Status
                  if (_userData?['role'] != null &&
                      (_userData!['role'] as List).contains('worker'))
                    _buildInfoCard(
                      icon: _userData?['isWorkerApproved'] == true
                          ? Icons.check_circle
                          : Icons.pending,
                      title: 'สถานะ Worker',
                      value: _userData?['isWorkerApproved'] == true
                          ? 'ได้รับการอนุมัติแล้ว'
                          : 'รอการอนุมัติ',
                      color: _userData?['isWorkerApproved'] == true
                          ? Colors.green
                          : Colors.orange,
                    ),
                  const SizedBox(height: 32),

                  // Logout Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _logout,
                      icon: const Icon(Icons.logout),
                      label: const Text('ออกจากระบบ'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red[600],
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard({
    required IconData icon,
    required String title,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
