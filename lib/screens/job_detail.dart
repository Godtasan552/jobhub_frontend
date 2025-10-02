import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../model/job_model.dart';
import 'package:get/get.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class job_detail extends StatefulWidget {
  const job_detail({super.key});

  @override
  State<job_detail> createState() => _job_detailState();
}

class _job_detailState extends State<job_detail>
    with SingleTickerProviderStateMixin {
  JobModel? _job;
  bool _isDataLoaded = false;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  // Theme Colors - เหมือนกับ Dashboard
  static const Color primaryColor = Color(0xFF2C6E49);
  static const Color accentColor = Color(0xFFA3CFBB);
  static const Color secondaryColor = Color(0xFF4C956C);
  static const Color backgroundColor = Color(0xFFF8FAF9);

  static const String _baseUrl = 'http://your-backend-api.com/api/v1/jobs/';

  final Map<String, Color> jobTypeColors = {
    'freelance': const Color(0xFF3B82F6),
    'part-time': const Color(0xFF10B981),
    'contract': const Color(0xFFF59E0B),
    'full-time': const Color(0xFFEF4444),
  };

  Future<String?> _getAuthToken() async {
    return null;
  }

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );
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

  Future<void> _applyJob(
    String jobId,
    String coverLetter,
    int proposedBudget,
  ) async {
    final String url = '$_baseUrl$jobId/apply';
    final String? token = await _getAuthToken();

    if (token == null || token.isEmpty) {
      if (!mounted) return;
      _showSnackBar(
        'กรุณาล็อกอินด้วยบัญชี Worker เพื่อสมัครงาน',
        isError: true,
      );
      return;
    }

    if (!mounted) return;
    _showSnackBar('กำลังส่งใบสมัคร...', isLoading: true);

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

      if (!mounted) return;
      final responseBody = jsonDecode(response.body);

      if (response.statusCode >= 200 && response.statusCode < 300) {
        _showSnackBar('สมัครงานสำเร็จ!', isSuccess: true);
      } else if (response.statusCode == 403) {
        _showSnackBar('คุณยังไม่ได้รับการอนุมัติเป็น Worker', isWarning: true);
      } else {
        String message = responseBody['message'] ?? 'เกิดข้อผิดพลาด';
        _showSnackBar(message, isError: true);
      }
    } catch (e) {
      if (!mounted) return;
      _showSnackBar('ข้อผิดพลาดในการเชื่อมต่อ', isError: true);
    }
  }

  void _showSnackBar(
    String message, {
    bool isError = false,
    bool isSuccess = false,
    bool isWarning = false,
    bool isLoading = false,
  }) {
    Color bgColor = secondaryColor;
    IconData icon = Icons.info;

    if (isSuccess) {
      bgColor = const Color(0xFF4CAF50);
      icon = Icons.check_circle;
    } else if (isError) {
      bgColor = const Color(0xFFF44336);
      icon = Icons.error;
    } else if (isWarning) {
      bgColor = const Color(0xFFFF9800);
      icon = Icons.warning;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(icon, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: bgColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  Future<void> _showApplicationForm(String jobId) async {
    final TextEditingController coverLetterController = TextEditingController();
    final TextEditingController proposedBudgetController =
        TextEditingController();

    final result = await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Padding(
            padding: EdgeInsets.fromLTRB(
              24,
              20,
              24,
              MediaQuery.of(context).viewInsets.bottom + 24,
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'ส่งใบสมัครงาน',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: primaryColor,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'กรอกข้อมูลเพื่อแสดงความสนใจในงานนี้',
                    style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'จดหมายปะหน้า',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                      color: primaryColor,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: coverLetterController,
                    maxLines: 5,
                    decoration: InputDecoration(
                      hintText: 'อธิบายทักษะและประสบการณ์...',
                      hintStyle: TextStyle(color: Colors.grey[400]),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: accentColor),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                          color: accentColor.withOpacity(0.5),
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: secondaryColor, width: 2),
                      ),
                      filled: true,
                      fillColor: backgroundColor,
                      contentPadding: const EdgeInsets.all(16),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'งบประมาณที่เสนอ (บาท)',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                      color: primaryColor,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: proposedBudgetController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      hintText:
                          'ค่าเริ่มต้น: ${NumberFormat('#,##0').format(_job!.budget)} บาท',
                      hintStyle: TextStyle(color: Colors.grey[400]),
                      prefixIcon: Icon(
                        Icons.attach_money,
                        color: secondaryColor,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: accentColor),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                          color: accentColor.withOpacity(0.5),
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: secondaryColor, width: 2),
                      ),
                      filled: true,
                      fillColor: backgroundColor,
                    ),
                  ),
                  const SizedBox(height: 28),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(context),
                          style: OutlinedButton.styleFrom(
                            minimumSize: const Size(0, 50),
                            side: BorderSide(color: Colors.grey[300]!),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text(
                            'ยกเลิก',
                            style: TextStyle(fontSize: 15),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        flex: 2,
                        child: ElevatedButton(
                          onPressed: () {
                            final String coverLetter = coverLetterController
                                .text
                                .trim();
                            final int proposedBudget =
                                int.tryParse(
                                  proposedBudgetController.text.trim(),
                                ) ??
                                _job!.budget.toInt();

                            if (coverLetter.isEmpty) {
                              _showSnackBar(
                                'กรุณากรอกจดหมายปะหน้า',
                                isError: true,
                              );
                              return;
                            }

                            Navigator.pop(context, {
                              'coverLetter': coverLetter,
                              'proposedBudget': proposedBudget,
                            });
                          },
                          style: ElevatedButton.styleFrom(
                            minimumSize: const Size(0, 50),
                            backgroundColor: primaryColor,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text(
                            'ส่งใบสมัคร',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );

    if (result != null && result is Map<String, dynamic>) {
      _applyJob(jobId, result['coverLetter'], result['proposedBudget']);
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'active':
        return const Color(0xFF4CAF50);
      case 'in_progress':
        return const Color(0xFFFF9800);
      case 'completed':
        return const Color(0xFF2196F3);
      case 'closed':
        return Colors.grey;
      case 'cancelled':
        return const Color(0xFFF44336);
      default:
        return Colors.grey;
    }
  }

  String _getStatusText(String status) {
    switch (status) {
      case 'active':
        return 'เปิดรับสมัคร';
      case 'in_progress':
        return 'กำลังดำเนินการ';
      case 'completed':
        return 'เสร็จสิ้น';
      case 'closed':
        return 'ปิดรับสมัคร';
      case 'cancelled':
        return 'ยกเลิก';
      default:
        return status;
    }
  }

  String _getTypeText(String type) {
    switch (type) {
      case 'freelance':
        return 'ฟรีแลนซ์';
      case 'part-time':
        return 'พาร์ทไทม์';
      case 'contract':
        return 'สัญญาจ้าง';
      case 'full-time':
        return 'เต็มเวลา';
      default:
        return type;
    }
  }

  Color _getTypeColor(String type) {
    return jobTypeColors[type] ?? secondaryColor;
  }

  Widget _buildSectionTitle(String title, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(top: 24, bottom: 12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: accentColor.withOpacity(0.3),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 20, color: primaryColor),
          ),
          const SizedBox(width: 12),
          Text(
            title,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: primaryColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoItem(IconData icon, String label, String value) {
    return Column(
      children: [
        Icon(icon, color: Colors.white, size: 20),
        const SizedBox(height: 6),
        Text(
          label,
          style: const TextStyle(color: Colors.white70, fontSize: 11),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_job == null) {
      return Scaffold(
        body: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: [primaryColor, secondaryColor]),
          ),
          child: const Center(
            child: CircularProgressIndicator(color: Colors.white),
          ),
        ),
      );
    }

    final job = _job!;
    final formatter = NumberFormat('#,##0');
    final dateFormatter = DateFormat('dd MMM yyyy');

    return Scaffold(
      backgroundColor: backgroundColor,
      body: Stack(
        children: [
          CustomScrollView(
            slivers: [
              SliverAppBar(
                expandedHeight: 200,
                pinned: true,
                backgroundColor: primaryColor,
                flexibleSpace: FlexibleSpaceBar(
                  background: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [primaryColor, secondaryColor],
                      ),
                    ),
                    child: SafeArea(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(20, 60, 20, 20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Text(
                              job.title,
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 12),
                            Wrap(
                              spacing: 8,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: _getTypeColor(job.type),
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  child: Text(
                                    _getTypeText(job.type),
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  child: Text(
                                    job.category,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                const Color(0xFF4CAF50),
                                const Color(0xFF45A049),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF4CAF50).withOpacity(0.3),
                                blurRadius: 12,
                                offset: const Offset(0, 6),
                              ),
                            ],
                          ),
                          child: Column(
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        const Text(
                                          'งบประมาณ',
                                          style: TextStyle(
                                            color: Colors.white70,
                                            fontSize: 13,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          '฿${formatter.format(job.budget)}',
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 32,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 8,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Container(
                                          width: 6,
                                          height: 6,
                                          decoration: BoxDecoration(
                                            color: _getStatusColor(job.status),
                                            shape: BoxShape.circle,
                                          ),
                                        ),
                                        const SizedBox(width: 6),
                                        Text(
                                          _getStatusText(job.status),
                                          style: TextStyle(
                                            color: _getStatusColor(job.status),
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              Row(
                                children: [
                                  Expanded(
                                    child: _buildInfoItem(
                                      Icons.access_time,
                                      'ระยะเวลา',
                                      job.duration,
                                    ),
                                  ),
                                  Container(
                                    width: 1,
                                    height: 40,
                                    color: Colors.white30,
                                  ),
                                  Expanded(
                                    child: _buildInfoItem(
                                      Icons.calendar_today,
                                      'กำหนดส่ง',
                                      job.deadline != null
                                          ? dateFormatter.format(job.deadline!)
                                          : 'ไม่กำหนด',
                                    ),
                                  ),
                                  Container(
                                    width: 1,
                                    height: 40,
                                    color: Colors.white30,
                                  ),
                                  Expanded(
                                    child: _buildInfoItem(
                                      Icons.people,
                                      'ผู้สมัคร',
                                      '${job.applicants.length}',
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        _buildSectionTitle('รายละเอียดงาน', Icons.description),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.05),
                                blurRadius: 6,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Text(
                            job.description,
                            style: TextStyle(
                              fontSize: 15,
                              height: 1.6,
                              color: Colors.grey[800],
                            ),
                          ),
                        ),
                        if (job.requirements != null &&
                            job.requirements!.isNotEmpty) ...[
                          _buildSectionTitle(
                            'คุณสมบัติที่ต้องการ',
                            Icons.checklist,
                          ),
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.05),
                                  blurRadius: 6,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Column(
                              children: job.requirements!.asMap().entries.map((
                                entry,
                              ) {
                                return Padding(
                                  padding: EdgeInsets.only(
                                    bottom:
                                        entry.key ==
                                            job.requirements!.length - 1
                                        ? 0
                                        : 12,
                                  ),
                                  child: Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Container(
                                        margin: const EdgeInsets.only(top: 2),
                                        padding: const EdgeInsets.all(4),
                                        decoration: BoxDecoration(
                                          color: secondaryColor.withOpacity(
                                            0.2,
                                          ),
                                          borderRadius: BorderRadius.circular(
                                            4,
                                          ),
                                        ),
                                        child: Icon(
                                          Icons.check,
                                          size: 14,
                                          color: secondaryColor,
                                        ),
                                      ),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: Text(
                                          entry.value,
                                          style: TextStyle(
                                            fontSize: 14,
                                            height: 1.5,
                                            color: Colors.grey[700],
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              }).toList(),
                            ),
                          ),
                        ],
                        if (job.attachments != null &&
                            job.attachments!.isNotEmpty) ...[
                          _buildSectionTitle('ไฟล์แนบ', Icons.attach_file),
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.05),
                                  blurRadius: 6,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Column(
                              children: job.attachments!.map((attachment) {
                                return Container(
                                  margin: const EdgeInsets.only(bottom: 8),
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: backgroundColor,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(
                                        Icons.insert_drive_file,
                                        color: secondaryColor,
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Text(
                                          attachment,
                                          style: TextStyle(
                                            fontSize: 14,
                                            color: Colors.grey[700],
                                          ),
                                        ),
                                      ),
                                      Icon(
                                        Icons.download,
                                        size: 20,
                                        color: Colors.grey[600],
                                      ),
                                    ],
                                  ),
                                );
                              }).toList(),
                            ),
                          ),
                        ],
                        if (job.milestones != null &&
                            job.milestones!.isNotEmpty) ...[
                          _buildSectionTitle('เป้าหมายย่อย', Icons.flag),
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.05),
                                  blurRadius: 6,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Column(
                              children: job.milestones!.asMap().entries.map((
                                entry,
                              ) {
                                return Padding(
                                  padding: EdgeInsets.only(
                                    bottom:
                                        entry.key == job.milestones!.length - 1
                                        ? 0
                                        : 12,
                                  ),
                                  child: Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Container(
                                        margin: const EdgeInsets.only(top: 2),
                                        width: 24,
                                        height: 24,
                                        decoration: BoxDecoration(
                                          color: accentColor.withOpacity(0.3),
                                          shape: BoxShape.circle,
                                        ),
                                        child: Center(
                                          child: Text(
                                            '${entry.key + 1}',
                                            style: TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.bold,
                                              color: primaryColor,
                                            ),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Text(
                                          entry.value,
                                          style: TextStyle(
                                            fontSize: 14,
                                            height: 1.5,
                                            color: Colors.grey[700],
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              }).toList(),
                            ),
                          ),
                        ],
                        _buildSectionTitle('ผู้ประกาศงาน', Icons.person),
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.05),
                                blurRadius: 6,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Row(
                            children: [
                              CircleAvatar(
                                radius: 30,
                                backgroundColor: accentColor,
                                backgroundImage:
                                    job.employer?.profilePic != null
                                    ? NetworkImage(job.employer!.profilePic!)
                                    : null,
                                child: job.employer?.profilePic == null
                                    ? Icon(
                                        Icons.person,
                                        size: 32,
                                        color: primaryColor,
                                      )
                                    : null,
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      job.employer?.name ?? 'ไม่ระบุชื่อ',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: primaryColor,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      job.employer?.email ?? '',
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 100),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, -5),
                  ),
                ],
              ),
              child: SafeArea(
                child: ElevatedButton(
                  onPressed: job.status == 'active'
                      ? () => _showApplicationForm(job.id)
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: job.status == 'active'
                        ? primaryColor
                        : Colors.grey[300],
                    foregroundColor: Colors.white,
                    minimumSize: const Size(double.infinity, 54),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        job.status == 'active' ? Icons.send : Icons.block,
                        size: 20,
                      ),
                      const SizedBox(width: 10),
                      Text(
                        job.status == 'active'
                            ? 'สมัครงานนี้'
                            : 'งาน${_getStatusText(job.status)}',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
