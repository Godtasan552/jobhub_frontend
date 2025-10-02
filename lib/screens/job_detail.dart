import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:get_storage/get_storage.dart';
import '../component/bottom_nav.dart';
import 'package:intl/intl.dart';
import '../model/job_model.dart'; 
import 'package:get/get.dart'; 
import 'dart:convert';
import 'package:http/http.dart' as http; // 🎯 ต้องเพิ่ม package:http ใน pubspec.yaml

class job_detail extends StatefulWidget { 
  const job_detail({super.key});

  @override
  State<job_detail> createState() => _job_detailState();
}

class _job_detailState extends State<job_detail> with SingleTickerProviderStateMixin {
  JobModel? _job;
  bool _isDataLoaded = false;
  bool _isWorkerApproved = false; // เพิ่มตัวแปรนี้
  List<String> _userRoles = []; // เพิ่มตัวแปรนี้
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  
  final storage = GetStorage(); // เพิ่ม GetStorage
  final String _baseUrl = dotenv.env['BASE_URL'] ?? 'http://localhost:5000';

  // ดึง Token และข้อมูล User
  Future<String?> _getAuthToken() async {
    return storage.read('token');
  }

  Future<void> _loadUserData() async {
    final token = await _getAuthToken();
    if (token == null) return;

    try {
      // เรียก API ดึงข้อมูล profile
      final response = await http.get(
        Uri.parse('$_baseUrl/api/v1/auth/profile'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          setState(() {
            _userRoles = List<String>.from(data['data']['role'] ?? []);
            _isWorkerApproved = data['data']['isWorkerApproved'] ?? false;
          });
        }
      }
    } catch (e) {
      print('Error loading user data: $e');
    }
  }
  
  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    
    // โหลดข้อมูล user
    _loadUserData();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    
    if (!_isDataLoaded) {
      final jobArgument = Get.arguments; 
      
      if (jobArgument != null && jobArgument is JobModel) {
        setState(() {
          _job = jobArgument;
          _isDataLoaded = true;
        });
        _animationController.forward();
      } else {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('ไม่พบข้อมูลงานที่ต้องการแสดง')),
          );
          Navigator.pop(context);
        });
      }
    }
  }

  // แสดง Dialog สำหรับสมัครงาน
  void _showApplyDialog() async {
    // เช็คว่า login หรือยัง
    final token = await _getAuthToken();
    if (token == null || token.isEmpty) {
      Get.snackbar(
        'กรุณาเข้าสู่ระบบ',
        'คุณต้องเข้าสู่ระบบก่อนสมัครงาน',
        backgroundColor: Colors.red[100],
        colorText: Colors.red[900],
        snackPosition: SnackPosition.TOP,
      );
      return;
    }

    // เช็คว่ามี role worker หรือไม่
    if (!_userRoles.contains('worker')) {
      Get.snackbar(
        'ไม่สามารถสมัครงานได้',
        'คุณต้องสมัครเป็น Worker ก่อนจึงจะสามารถสมัครงานได้',
        backgroundColor: Colors.orange[100],
        colorText: Colors.orange[900],
        snackPosition: SnackPosition.TOP,
        duration: const Duration(seconds: 4),
      );
      return;
    }

    // เช็คว่า worker ได้รับการอนุมัติหรือยัง
    if (!_isWorkerApproved) {
      Get.snackbar(
        'รอการอนุมัติ',
        'บัญชี Worker ของคุณยังไม่ได้รับการอนุมัติจาก Admin กรุณารอการอนุมัติ',
        backgroundColor: Colors.orange[100],
        colorText: Colors.orange[900],
        snackPosition: SnackPosition.TOP,
        duration: const Duration(seconds: 4),
      );
      return;
    }

    // ถ้าผ่านทุก condition แล้ว แสดง dialog สมัครงาน
    final coverLetterController = TextEditingController();
    final budgetController = TextEditingController(
      text: _job?.budget.toString() ?? '0',
    );

    Get.dialog(
      AlertDialog(
        title: const Text('สมัครงาน'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: coverLetterController,
                decoration: const InputDecoration(
                  labelText: 'จดหมายสมัครงาน *',
                  hintText: 'เขียนเหตุผลที่คุณเหมาะสมกับงานนี้',
                  border: OutlineInputBorder(),
                ),
                maxLines: 5,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: budgetController,
                decoration: const InputDecoration(
                  labelText: 'งบประมาณที่เสนอ (บาท) *',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.attach_money),
                ),
                keyboardType: TextInputType.number,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('ยกเลิก'),
          ),
          ElevatedButton(
            onPressed: () async {
              final coverLetter = coverLetterController.text.trim();
              final budgetStr = budgetController.text.trim();

              if (coverLetter.isEmpty) {
                Get.snackbar(
                  'ข้อมูลไม่ครบ',
                  'กรุณากรอกจดหมายสมัครงาน',
                  backgroundColor: Colors.red[100],
                  colorText: Colors.red[900],
                );
                return;
              }

              final budget = int.tryParse(budgetStr);
              if (budget == null || budget <= 0) {
                Get.snackbar(
                  'ข้อมูลไม่ถูกต้อง',
                  'กรุณากรอกงบประมาณที่ถูกต้อง',
                  backgroundColor: Colors.red[100],
                  colorText: Colors.red[900],
                );
                return;
              }

              Get.back(); // ปิด dialog
              await _applyJob(_job!.id, coverLetter, budget);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFA3CFBB),
            ),
            child: const Text('ส่งใบสมัคร'),
          ),
        ],
      ),
    );
  }

  Future<void> _applyJob(String jobId, String coverLetter, int proposedBudget) async {
    final String endpoint = '/api/v1/jobs/';
    final String url = '$_baseUrl$endpoint$jobId/apply';
    final String? token = await _getAuthToken();
    
    Get.snackbar(
      'กำลังส่งใบสมัคร...',
      'กรุณารอสักครู่',
      backgroundColor: Colors.orange[100],
      snackPosition: SnackPosition.TOP,
      duration: const Duration(seconds: 2),
    );

    try {
      final response = await http.post(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'coverLetter': coverLetter,
          'proposedBudget': proposedBudget,
        }),
      );

      print('Apply response status: ${response.statusCode}');
      print('Apply response body: ${response.body}');

      final responseBody = jsonDecode(response.body);

      if (response.statusCode >= 200 && response.statusCode < 300) {
        Get.snackbar(
          'สำเร็จ!',
          'ส่งใบสมัครงานเรียบร้อย นายจ้างจะได้รับแจ้งเตือน',
          backgroundColor: Colors.green[100],
          colorText: Colors.green[900],
          snackPosition: SnackPosition.TOP,
          duration: const Duration(seconds: 3),
        );
      } else {
        String message = responseBody['message'] ?? responseBody['error'] ?? 'เกิดข้อผิดพลาดในการสมัครงาน';
        Get.snackbar(
          'ไม่สำเร็จ',
          message,
          backgroundColor: Colors.red[100],
          colorText: Colors.red[900],
          snackPosition: SnackPosition.TOP,
          duration: const Duration(seconds: 3),
        );
      }
    } catch (e) {
      print('Error applying job: $e');
      Get.snackbar(
        'เกิดข้อผิดพลาด',
        'ไม่สามารถเชื่อมต่อกับเซิร์ฟเวอร์ได้',
        backgroundColor: Colors.red[100],
        colorText: Colors.red[900],
        snackPosition: SnackPosition.TOP,
      );
    }
  }

  // ปุ่มสมัครงาน (ใส่ใน build method)
  Widget _buildApplyButton() {
    return Container(
      width: double.infinity,
      height: 54,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFA3CFBB), Color(0xFF8BC0A8)],
        ),
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFA3CFBB).withOpacity(0.4),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: _showApplyDialog,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.send_rounded, size: 22),
            SizedBox(width: 10),
            Text(
              'สมัครงาน',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.3,
              ),
            ),
          ],
        ),
      ),
    );
  }
  // ----------------------------------------------------
  // ฟังก์ชันสำหรับแสดง Modal Form
  // ----------------------------------------------------
  Future<void> _showApplicationForm(String jobId) async {
    final TextEditingController coverLetterController = TextEditingController();
    final TextEditingController proposedBudgetController = TextEditingController();
    
    final result = await showModalBottomSheet(
      context: context,
      isScrollControlled: true, 
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(25.0)),
      ),
      builder: (BuildContext context) {
        return Padding(
          padding: EdgeInsets.fromLTRB(20, 30, 20, MediaQuery.of(context).viewInsets.bottom + 20), 
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'ส่งใบสมัครงาน',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF1E3A8A)),
                ),
                const Divider(height: 25),

                // 📝 Cover Letter
                const Text('จดหมายปะหน้า/เหตุผลที่สมัคร', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
                const SizedBox(height: 8),
                TextField(
                  controller: coverLetterController,
                  maxLines: 4,
                  decoration: InputDecoration(
                    hintText: 'อธิบายทักษะและประสบการณ์ที่เกี่ยวข้อง',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    filled: true,
                    fillColor: Colors.grey.shade50,
                  ),
                ),
                const SizedBox(height: 20),

                // 💰 Proposed Budget
                const Text('งบประมาณที่คุณเสนอ (เป็นตัวเลข)', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
                const SizedBox(height: 8),
                TextField(
                  controller: proposedBudgetController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    hintText: 'ราคาเสนอ (ค่าเริ่มต้น: ${NumberFormat('#,##0').format(_job!.budget)})',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    filled: true,
                    fillColor: Colors.grey.shade50,
                  ),
                ),
                const SizedBox(height: 30),

                // 🚀 ปุ่มส่งใบสมัคร
                ElevatedButton(
                  onPressed: () {
                    final String coverLetter = coverLetterController.text.trim();
                    // ถ้าไม่กรอก ให้ใช้ budget เดิมของงานเป็นค่า default
                    final int proposedBudget = int.tryParse(proposedBudgetController.text.trim()) ?? _job!.budget.toInt();

                    if (coverLetter.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('กรุณากรอกจดหมายปะหน้า'), backgroundColor: Color(0xFFEF4444)),
                      );
                      return;
                    }
                    
                    // ส่งผลลัพธ์กลับไป
                    Navigator.pop(context, {
                      'coverLetter': coverLetter,
                      'proposedBudget': proposedBudget,
                    });
                  },
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 55),
                    backgroundColor: const Color(0xFF3B82F6),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('ยืนยันและส่งใบสมัคร', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                ),
                const SizedBox(height: 10),
              ],
            ),
          ),
        );
      },
    );

    // หลังจาก Modal ถูกปิด และมีข้อมูลส่งกลับมา
    if (result != null && result is Map<String, dynamic>) {
      _applyJob(
        jobId,
        result['coverLetter'],
        result['proposedBudget'],
      );
    }
  }


  // --- Helper Methods (ใช้โค้ดเดิมของคุณ) ---
  
  Color _getStatusColor(String status) {
    switch (status) {
      case 'active': return const Color(0xFF10B981);
      case 'in_progress': return const Color(0xFFF59E0B);
      case 'completed': return const Color(0xFF3B82F6);
      case 'closed': return const Color(0xFF6B7280);
      case 'cancelled': return const Color(0xFFEF4444);
      default: return Colors.grey;
    }
  }

  String _getStatusText(String status) {
    switch (status) {
      case 'active': return 'เปิดรับสมัคร';
      case 'in_progress': return 'กำลังดำเนินการ';
      case 'completed': return 'เสร็จสิ้น';
      case 'closed': return 'ปิดรับสมัคร';
      case 'cancelled': return 'ยกเลิก';
      default: return status;
    }
  }

  String _getTypeText(String type) {
    switch (type) {
      case 'freelance': return 'ฟรีแลนซ์';
      case 'part-time': return 'พาร์ทไทม์';
      case 'contract': return 'สัญญาจ้าง';
      case 'full-time': return 'เต็มเวลา';
      default: return type;
    }
  }

  Widget _buildInfoChip(IconData icon, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color.withOpacity(0.15), color.withOpacity(0.05)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(25),
        border: Border.all(color: color.withOpacity(0.3), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.2),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(top: 24, bottom: 12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [const Color(0xFF3B82F6), const Color(0xFF1E3A8A)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF3B82F6).withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Icon(icon, size: 24, color: Colors.white),
          ),
          const SizedBox(width: 12),
          Text(
            title,
            style: const TextStyle(
              fontSize: 22, 
              fontWeight: FontWeight.bold, 
              color: Color(0xFF1E3A8A),
              letterSpacing: -0.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, {IconData? icon}) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14.0, horizontal: 16),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: Colors.grey.shade100, width: 1)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          if (icon != null) Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFF3B82F6).withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 20, color: const Color(0xFF3B82F6)),
          ),
          if (icon != null) const SizedBox(width: 12),
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.w600, 
                color: Colors.grey[700], 
                fontSize: 15
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 15, 
                fontWeight: FontWeight.w500,
                color: Color(0xFF1F2937),
              ),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_job == null) {
      return Scaffold(
        body: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFF3B82F6), Color(0xFF1E3A8A)],
            ),
          ),
          child: const Center(
            child: CircularProgressIndicator(color: Colors.white),
          ),
        ),
      );
    }
    
    final job = _job!;
    final formatter = NumberFormat('#,##0');
    final dateFormatter = DateFormat('dd MMM yyyy, HH:mm');

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text(
          job.title,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.white,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF3B82F6), Color(0xFF1E3A8A)],
            ),
          ),
        ),
      ),
        bottomNavigationBar: buildBottomNavigationBar(
      0, // highlight แท็บ Home
      (index) {
        switch (index) {
          case 0:
            Get.back();
            break;
          default:
            // ⚠️ ปรับแก้ตาม navigation logic ของคุณ
            Get.off(() => BottomNav(initialIndex: index)); 
            break;
        }
      },
    ),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                const Color(0xFF3B82F6).withOpacity(0.05),
                Colors.white,
              ],
              stops: const [0.0, 0.3],
            ),
          ),
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 100, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 💰 Hero Section - งบประมาณ
                Container(
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Color(0xFF10B981), Color(0xFF059669)],
                    ),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF10B981).withOpacity(0.4),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'งบประมาณโครงการ',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.white70,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    '฿${formatter.format(job.budget)}',
                                    style: const TextStyle(
                                      fontSize: 36,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                      letterSpacing: -1,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(30),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.1),
                                    blurRadius: 10,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    width: 8,
                                    height: 8,
                                    decoration: BoxDecoration(
                                      color: _getStatusColor(job.status),
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    _getStatusText(job.status),
                                    style: TextStyle(
                                      color: _getStatusColor(job.status),
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        Wrap(
                          spacing: 10,
                          runSpacing: 10,
                          children: [
                            _buildInfoChip(Icons.work_outline, _getTypeText(job.type), Colors.white),
                            _buildInfoChip(Icons.category_outlined, job.category, Colors.white),
                            _buildInfoChip(Icons.access_time, job.duration, Colors.white),
                            _buildInfoChip(Icons.people, '${job.applicants.length} ผู้สมัคร', Colors.white),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                
                const SizedBox(height: 8),

                // 📄 รายละเอียดงาน
                _buildSectionHeader('รายละเอียดงาน', Icons.description),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 15,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Text(
                      job.description,
                      style: TextStyle(
                        fontSize: 16,
                        height: 1.6,
                        color: Colors.grey[800],
                        letterSpacing: 0.2,
                      ),
                    ),
                  ),
                ),
                
                // 🛠️ คุณสมบัติและข้อกำหนด
                if (job.requirements != null && job.requirements!.isNotEmpty) ...[
                  _buildSectionHeader('คุณสมบัติและข้อกำหนด', Icons.checklist_rtl),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 15,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: job.requirements!
                            .map((req) => Padding(
                                  padding: const EdgeInsets.only(bottom: 12.0),
                                  child: Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(4),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFF10B981).withOpacity(0.1),
                                          borderRadius: BorderRadius.circular(6),
                                        ),
                                        child: const Icon(
                                          Icons.check_circle,
                                          size: 20,
                                          color: Color(0xFF10B981),
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Text(
                                          req,
                                          style: const TextStyle(
                                            fontSize: 15,
                                            height: 1.5,
                                            color: Color(0xFF1F2937),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ))
                            .toList(),
                      ),
                    ),
                  ),
                ],

                // 📦 ข้อมูลโครงการ
                _buildSectionHeader('ข้อมูลโครงการ', Icons.info_outline),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 15,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      _buildDetailRow('Job ID', job.id, icon: Icons.fingerprint),
                      _buildDetailRow('Employer ID', job.employerId.toString(), icon: Icons.account_circle),
                      if (job.workerId != null && job.workerId!.isNotEmpty)
                        _buildDetailRow('Worker ID', job.workerId!, icon: Icons.person_pin),
                      
                      if (job.deadline != null)
                        _buildDetailRow(
                          'กำหนดส่งงาน',
                          DateFormat('dd MMM yyyy').format(job.deadline!),
                          icon: Icons.calendar_today,
                        ),
                      _buildDetailRow(
                        'สร้างเมื่อ',
                        dateFormatter.format(job.createdAt),
                        icon: Icons.access_time_outlined,
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(vertical: 14.0, horizontal: 16),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: const Color(0xFF3B82F6).withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(Icons.update, size: 20, color: Color(0xFF3B82F6)),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              flex: 2,
                              child: Text(
                                'อัปเดตล่าสุด',
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  color: Colors.grey[700],
                                  fontSize: 15
                                ),
                              ),
                            ),
                            Expanded(
                              flex: 3,
                              child: Text(
                                dateFormatter.format(job.updatedAt),
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w500,
                                  color: Color(0xFF1F2937),
                                ),
                                textAlign: TextAlign.right,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 40),

                // 🚀 ปุ่มสมัครงาน (แก้ไขให้เรียก Modal Form)
                Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: job.status == 'active' ? [
                      BoxShadow(
                        color: const Color(0xFF3B82F6).withOpacity(0.4),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ] : [],
                  ),
                  child: ElevatedButton(
                    onPressed: job.status == 'active' ? () {
                      // 💡 เรียกฟังก์ชันแสดงฟอร์มสมัครงาน
                      _showApplicationForm(job.id); 
                    } : null, 
                    style: ElevatedButton.styleFrom(
                      backgroundColor: job.status == 'active' 
                          ? const Color(0xFF3B82F6)
                          : Colors.grey.shade300,
                      foregroundColor: Colors.white,
                      minimumSize: const Size(double.infinity, 60),
                      padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 0,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          job.status == 'active' ? Icons.how_to_reg : Icons.block,
                          size: 26,
                        ),
                        const SizedBox(width: 12),
                        Text(
                          job.status == 'active' 
                              ? 'สมัครงานนี้' 
                              : 'งาน${_getStatusText(job.status)}',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }
}