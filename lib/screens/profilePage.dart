import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:http_parser/http_parser.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final storage = GetStorage();
  final ImagePicker _picker = ImagePicker();

  bool _isLoading = true;
  bool _isUploading = false;
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

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data['success'] == true) {
          setState(() {
            _userData = data['data'];
            _isLoading = false;
          });

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
      setState(() {
        _errorMessage = 'เกิดข้อผิดพลาด: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _uploadProfilePicture(File imageFile) async {
    try {
      final token = storage.read('token');

      if (token == null) {
        Get.snackbar(
          'Error',
          'ไม่พบ Token กรุณาเข้าสู่ระบบใหม่',
          backgroundColor: Colors.red[100],
          colorText: Colors.red[900],
          snackPosition: SnackPosition.TOP,
        );
        return;
      }

      final String baseUrl = dotenv.env['BASE_URL'] ?? 'http://localhost:5000';

      print('📸 Image path: ${imageFile.path}');
      print('📸 Image size: ${await imageFile.length()} bytes');

      var request = http.MultipartRequest(
        'POST',
        Uri.parse('$baseUrl/api/v1/auth/upload-profile-picture'),
      );

      request.headers['Authorization'] = 'Bearer $token';

      // ตรวจสอบนามสกุลไฟล์และกำหนด content type
      String fileName = imageFile.path.split('/').last;
      String extension = fileName.split('.').last.toLowerCase();

      String contentType;
      if (extension == 'jpg' || extension == 'jpeg') {
        contentType = 'image/jpeg';
      } else if (extension == 'png') {
        contentType = 'image/png';
      } else if (extension == 'gif') {
        contentType = 'image/gif';
      } else {
        // ถ้าไม่รู้จักนามสกุล ให้ใช้ jpeg เป็น default
        contentType = 'image/jpeg';
        fileName = '${fileName.split('.').first}.jpg';
      }

      print('📦 File name: $fileName');
      print('📦 Content type: $contentType');

      // เพิ่มไฟล์พร้อม content type ที่ชัดเจน
      var multipartFile = http.MultipartFile(
        'profilePicture',
        imageFile.readAsBytes().asStream(),
        await imageFile.length(),
        filename: fileName,
        contentType: MediaType.parse(contentType),
      );

      request.files.add(multipartFile);

      print('🚀 Uploading to: ${request.url}');

      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);

      print('📡 Status: ${response.statusCode}');
      print('📡 Body: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data['success'] == true) {
          Get.snackbar(
            'สำเร็จ',
            'อัปโหลดรูปโปรไฟล์สำเร็จ',
            backgroundColor: Colors.green[100],
            colorText: Colors.green[900],
            snackPosition: SnackPosition.TOP,
          );

          await _loadProfile();
        } else {
          Get.snackbar(
            'Error',
            data['message'] ?? 'ไม่สามารถอัปโหลดรูปได้',
            backgroundColor: Colors.red[100],
            colorText: Colors.red[900],
            snackPosition: SnackPosition.TOP,
          );
        }
      } else {
        String errorMsg = 'Error ${response.statusCode}';
        try {
          final data = json.decode(response.body);
          errorMsg = data['message'] ?? data['error'] ?? errorMsg;
        } catch (e) {
          errorMsg = response.body;
        }

        Get.snackbar(
          'Error',
          errorMsg,
          backgroundColor: Colors.red[100],
          colorText: Colors.red[900],
          snackPosition: SnackPosition.TOP,
          duration: const Duration(seconds: 5),
        );
      }
    } catch (e, stackTrace) {
      print('❌ Error: $e');
      print('❌ Stack: $stackTrace');
      Get.snackbar(
        'Error',
        'เกิดข้อผิดพลาด: $e',
        backgroundColor: Colors.red[100],
        colorText: Colors.red[900],
        snackPosition: SnackPosition.TOP,
      );
    }
  }

  Future<void> _pickAndUploadImage(ImageSource source) async {
    try {
      // ขอ permission ก่อน
      PermissionStatus permission;

      if (source == ImageSource.camera) {
        permission = await Permission.camera.request();
      } else {
        // สำหรับ Android 13+ (API 33+) ใช้ photos
        // สำหรับ Android 12 ขึ้นไปแต่ต่ำกว่า 13 ใช้ storage
        if (Platform.isAndroid) {
          final androidInfo = await DeviceInfoPlugin().androidInfo;
          if (androidInfo.version.sdkInt >= 33) {
            permission = await Permission.photos.request();
          } else {
            permission = await Permission.storage.request();
          }
        } else {
          // iOS
          permission = await Permission.photos.request();
        }
      }

      if (permission.isDenied || permission.isPermanentlyDenied) {
        Get.snackbar(
          'ไม่อนุญาต',
          source == ImageSource.camera
              ? 'กรุณาอนุญาตให้เข้าถึงกล้องในการตั้งค่า'
              : 'กรุณาอนุญาตให้เข้าถึงรูปภาพในการตั้งค่า',
          backgroundColor: Colors.orange[100],
          colorText: Colors.orange[900],
          snackPosition: SnackPosition.TOP,
          duration: const Duration(seconds: 3),
          mainButton: TextButton(
            onPressed: () => openAppSettings(),
            child: const Text('เปิดการตั้งค่า'),
          ),
        );
        return;
      }

      final XFile? image = await _picker.pickImage(
        source: source,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );

      if (image == null) return;

      setState(() {
        _isUploading = true;
      });

      await _uploadProfilePicture(File(image.path));
    } catch (e) {
      print('Error picking image: $e');
      Get.snackbar(
        'Error',
        'เกิดข้อผิดพลาด: $e',
        backgroundColor: Colors.red[100],
        colorText: Colors.red[900],
        snackPosition: SnackPosition.TOP,
      );
    } finally {
      setState(() {
        _isUploading = false;
      });
    }
  }

  void _showImageSourceDialog() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'เลือกรูปโปรไฟล์',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),
              ListTile(
                leading: const Icon(Icons.camera_alt, color: Colors.blue),
                title: const Text('ถ่ายรูป'),
                onTap: () {
                  Navigator.pop(context);
                  _pickAndUploadImage(ImageSource.camera);
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library, color: Colors.blue),
                title: const Text('เลือกจากแกลเลอรี่'),
                onTap: () {
                  Navigator.pop(context);
                  _pickAndUploadImage(ImageSource.gallery);
                },
              ),
              const SizedBox(height: 10),
            ],
          ),
        ),
      ),
    );
  }

  //function แสดง ข้อมูลสำหรับ คนที่ appove เป็น worker แล้ว
  Widget buildAboutCard(Map<String, dynamic> userData) {
    final aboutString = userData['about'] ?? '';

    final jsonString = aboutString.replaceFirst("Worker Info: ", "").trim();

    Map<String, dynamic> aboutData = {};
    try {
      aboutData = jsonDecode(jsonString);
    } catch (e) {
      debugPrint("Error parsing about JSON: $e");
    }
    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Column(
        children: [
          ListTile(
            leading: const Icon(Icons.info, color: Colors.deepPurple),
            title: const Text(
              "ข้อมูลเพิ่มเติม",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
          const Divider(height: 1),

          if (_userData?['skills'] != null)
            ListTile(
              leading: const Icon(Icons.build, color: Colors.blue),
              title: Text(
                "ทักษะ: ${(_userData?['skills'] as List).join(', ')}",
              ),
            ),

          if (_userData?['categories'] != null)
            ListTile(
              leading: const Icon(Icons.category, color: Colors.orange),
              title: Text(
                "หมวดหมู่: ${(_userData?['categories'] as List).join(', ')}",
              ),
            ),

          if (aboutData['experience'] != null)
            ListTile(
              leading: const Icon(Icons.work_history, color: Colors.green),
              title: Text("ประสบการณ์: ${aboutData['experience']}"),
            ),

          if (aboutData['portfolio'] != null)
            ListTile(
              leading: const Icon(Icons.link, color: Colors.blueAccent),
              title: InkWell(
                onTap: () {
                  // ใช้ url_launcher เปิดลิงก์
                },
                child: Text(
                  "Portfolio: ${aboutData['portfolio']}",
                  style: const TextStyle(
                    color: Colors.blue,
                    decoration: TextDecoration.underline,
                  ),
                ),
              ),
            ),

          if (aboutData['hourlyRate'] != null)
            ListTile(
              leading: const Icon(Icons.attach_money, color: Colors.teal),
              title: Text("ค่าจ้างต่อชั่วโมง: ${aboutData['hourlyRate']} บาท"),
            ),

          if (aboutData['availability'] != null)
            ListTile(
              leading: const Icon(Icons.schedule, color: Colors.purple),
              title: Text("ความพร้อม: ${aboutData['availability']}"),
            ),
        ],
      ),
    );
  }

  Future<void> _applyWorker() async {
    // เช็คว่าเป็น worker อยู่แล้วหรือยัง
    if (_userData?['role'] != null &&
        (_userData!['role'] as List).contains('worker')) {
      Get.snackbar(
        'แจ้งเตือน',
        _userData?['isWorkerApproved'] == true
            ? 'คุณได้รับการอนุมัติเป็น Worker แล้ว'
            : 'คุณได้สมัครเป็น Worker แล้ว กำลังรอการอนุมัติ',
        backgroundColor: Colors.orange[100],
        colorText: Colors.orange[900],
        snackPosition: SnackPosition.TOP,
      );
      return;
    }

    // แสดง dialog กรอกข้อมูล
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => _WorkerApplicationDialog(),
    );

    if (result == null) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final token = storage.read('token');
      final String baseUrl = dotenv.env['BASE_URL'] ?? 'http://localhost:5000';

      final response = await http.post(
        Uri.parse('$baseUrl/api/v1/auth/apply-worker'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode(result),
      );

      print('📡 Apply worker status: ${response.statusCode}');
      print('📡 Apply worker body: ${response.body}');

      final data = json.decode(response.body);

      if (response.statusCode == 200 && data['success'] == true) {
        Get.snackbar(
          'สำเร็จ',
          'ส่งคำขอสมัคร Worker เรียบร้อยแล้ว กรุณารอการอนุมัติจาก Admin',
          backgroundColor: Colors.green[100],
          colorText: Colors.green[900],
          snackPosition: SnackPosition.TOP,
          duration: const Duration(seconds: 4),
        );

        // โหลดข้อมูลใหม่
        await _loadProfile();
      } else {
        Get.snackbar(
          'Error',
          data['message'] ?? 'ไม่สามารถส่งคำขอได้',
          backgroundColor: Colors.red[100],
          colorText: Colors.red[900],
          snackPosition: SnackPosition.TOP,
        );
      }
    } catch (e) {
      print(' Apply worker error: $e');
      Get.snackbar(
        'Error',
        'เกิดข้อผิดพลาด: $e',
        backgroundColor: Colors.red[100],
        colorText: Colors.red[900],
        snackPosition: SnackPosition.TOP,
      );
    } finally {
      setState(() {
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
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (_errorMessage != null) {
      return Scaffold(
        appBar: AppBar(title: const Text('โปรไฟล์')),
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
                  // Profile Picture with Edit Button
                  Stack(
                    children: [
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

                      // Upload Button Overlay
                      if (_isUploading)
                        Positioned.fill(
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.black54,
                              shape: BoxShape.circle,
                            ),
                            child: const Center(
                              child: CircularProgressIndicator(
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),

                      // Edit Button
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: GestureDetector(
                          onTap: _isUploading ? null : _showImageSourceDialog,
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.blue[700],
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 2),
                            ),
                            child: const Icon(
                              Icons.camera_alt,
                              color: Colors.white,
                              size: 20,
                            ),
                          ),
                        ),
                      ),
                    ],
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
                    style: const TextStyle(fontSize: 16, color: Colors.white70),
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
                  if (_userData?['location'] != null)
                    const SizedBox(height: 16),

                  if (_userData?['isWorkerApproved'] == true)
                    buildAboutCard(_userData!),

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
                  // เพิ่มก่อน Logout Button
                  // Apply Worker Button (แสดงเฉพาะคนที่ยังไม่เป็น worker)
                  if (_userData?['role'] != null &&
                      !(_userData!['role'] as List).contains('worker'))
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _applyWorker,
                        icon: const Icon(Icons.work_outline),
                        label: const Text('สมัครเป็น Worker'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green[600],
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                      ),
                    ),
                  if (_userData?['role'] != null &&
                      !(_userData!['role'] as List).contains('worker'))
                    const SizedBox(height: 16),

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
                  style: TextStyle(fontSize: 14, color: Colors.grey[600]),
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

class _WorkerApplicationDialog extends StatefulWidget {
  @override
  State<_WorkerApplicationDialog> createState() =>
      _WorkerApplicationDialogState();
}

class _WorkerApplicationDialogState extends State<_WorkerApplicationDialog> {
  final _formKey = GlobalKey<FormState>();
  final _skillsController = TextEditingController();
  final _categoriesController = TextEditingController();
  final _experienceController = TextEditingController();
  final _portfolioController = TextEditingController();
  final _hourlyRateController = TextEditingController();
  String _availability = 'full-time';

  @override
  void dispose() {
    _skillsController.dispose();
    _categoriesController.dispose();
    _experienceController.dispose();
    _portfolioController.dispose();
    _hourlyRateController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.work, color: Colors.blue[700], size: 28),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text(
                        'สมัครเป็น Worker',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'กรอกข้อมูลเพื่อสมัครเป็น Worker',
                  style: TextStyle(color: Colors.grey[600]),
                ),
                const SizedBox(height: 24),

                // Skills
                TextFormField(
                  controller: _skillsController,
                  decoration: const InputDecoration(
                    labelText: 'ทักษะ *',
                    hintText: 'เช่น: React, Node.js, Flutter (คั่นด้วยจุลภาค)',
                    prefixIcon: Icon(Icons.stars),
                  ),
                  maxLines: 2,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'กรุณากรอกทักษะ';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Categories
                TextFormField(
                  controller: _categoriesController,
                  decoration: const InputDecoration(
                    labelText: 'หมวดหมู่ *',
                    hintText: 'เช่น: technology, design (คั่นด้วยจุลภาค)',
                    prefixIcon: Icon(Icons.category),
                  ),
                  maxLines: 2,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'กรุณากรอกหมวดหมู่';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Experience
                TextFormField(
                  controller: _experienceController,
                  decoration: const InputDecoration(
                    labelText: 'ประสบการณ์ *',
                    hintText: 'อธิบายประสบการณ์ทำงานของคุณ',
                    prefixIcon: Icon(Icons.work_history),
                  ),
                  maxLines: 3,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'กรุณากรอกประสบการณ์';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Portfolio
                TextFormField(
                  controller: _portfolioController,
                  decoration: const InputDecoration(
                    labelText: 'Portfolio *',
                    hintText: 'URL ของ Portfolio เช่น GitHub, Website',
                    prefixIcon: Icon(Icons.link),
                  ),
                  validator: (value) {
                    // ถ้าไม่กรอกก็ผ่าน
                    if (value == null || value.trim().isEmpty) {
                      return 'กรุณากรอก Portfolio';
                    }
                    // ถ้ากรอกต้องเป็น URL ที่ถูกต้อง
                    if (!value.startsWith('http://') &&
                        !value.startsWith('https://')) {
                      return 'กรุณากรอก URL ที่ขึ้นต้นด้วย https:// หรือ http://';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Hourly Rate
                TextFormField(
                  controller: _hourlyRateController,
                  decoration: const InputDecoration(
                    labelText: 'อัตราค่าจ้างต่อชั่วโมง (บาท) *',
                    hintText: 'เช่น: 300',
                    prefixIcon: Icon(Icons.attach_money),
                  ),
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'กรุณากรอกอัตราค่าจ้าง';
                    }
                    final rate = int.tryParse(value);
                    if (rate == null || rate <= 0) {
                      return 'กรุณากรอกตัวเลขที่มากกว่า 0';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Availability
                DropdownButtonFormField<String>(
                  value: _availability,
                  decoration: const InputDecoration(
                    labelText: 'ความพร้อมในการทำงาน *',
                    prefixIcon: Icon(Icons.schedule),
                  ),
                  items: const [
                    DropdownMenuItem(
                      value: 'full-time',
                      child: Text('Full-time(เต็มเวลา)'),
                    ),
                    DropdownMenuItem(
                      value: 'part-time',
                      child: Text('Part-time(พาร์ทไทม์)'),
                    ),
                    DropdownMenuItem(
                      value: 'fiexible',
                      child: Text('Flexible(ยืดหยุ่น)'),
                    ),
                  ],
                  onChanged: (value) {
                    setState(() {
                      _availability = value!;
                    });
                  },
                ),
                const SizedBox(height: 24),

                // Buttons
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('ยกเลิก'),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: () {
                        if (_formKey.currentState!.validate()) {
                          final result = {
                            'skills': _skillsController.text
                                .split(',')
                                .map((e) => e.trim())
                                .where((e) => e.isNotEmpty)
                                .toList(),
                            'categories': _categoriesController.text
                                .split(',')
                                .map((e) => e.trim())
                                .where((e) => e.isNotEmpty)
                                .toList(),
                            'experience': _experienceController.text.trim(),
                            'portfolio': _portfolioController.text.trim(),
                            'hourlyRate': int.parse(_hourlyRateController.text),
                            'availability': _availability,
                          };
                          if (_portfolioController.text.trim().isNotEmpty) {
                            result['portfolio'] = _portfolioController.text
                                .trim();
                          }
                          Navigator.pop(context, result);
                        }
                      },
                      child: const Text('ส่งคำขอ'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
