// lib/screens/my_jobs_screen.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../model/job_model.dart';
import '../services/job_service.dart';
import '../routes/app_routes.dart';

class MyJobsScreen extends StatefulWidget {
  const MyJobsScreen({super.key});

  @override
  State<MyJobsScreen> createState() => _MyJobsScreenState();
}

class _MyJobsScreenState extends State<MyJobsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<JobModel> _appliedJobs = [];
  List<JobModel> _createdJobs = [];
  bool _isLoadingApplied = true;
  bool _isLoadingCreated = true;

  // Theme Colors
  static const Color primaryColor = Color(0xFF2C6E49);
  static const Color accentColor = Color(0xFFA3CFBB);
  static const Color secondaryColor = Color(0xFF4C956C);
  static const Color backgroundColor = Color(0xFFF8FAF9);

  final Map<String, Color> jobTypeColors = {
    'freelance': const Color(0xFF3B82F6),
    'part-time': const Color(0xFF10B981),
    'contract': const Color(0xFFF59E0B),
    'full-time': const Color(0xFFEF4444),
  };

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadAppliedJobs();
    _loadCreatedJobs();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadAppliedJobs() async {
    setState(() => _isLoadingApplied = true);
    final result = await JobService.getMyAppliedJobs();
    if (result['success'] == true) {
      setState(() {
        _appliedJobs = result['jobs'];
        _isLoadingApplied = false;
      });
    } else {
      setState(() => _isLoadingApplied = false);
      _showSnackBar(result['message'], isError: true);
    }
  }

  Future<void> _loadCreatedJobs() async {
    setState(() => _isLoadingCreated = true);
    final result = await JobService.getMyCreatedJobs();
    if (result['success'] == true) {
      setState(() {
        _createdJobs = result['jobs'];
        _isLoadingCreated = false;
      });
    } else {
      setState(() => _isLoadingCreated = false);
      _showSnackBar(result['message'], isError: true);
    }
  }

  void _showSnackBar(
    String message, {
    bool isError = false,
    bool isSuccess = false,
  }) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              isSuccess
                  ? Icons.check_circle
                  : (isError ? Icons.error : Icons.info),
              color: Colors.white,
            ),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: isSuccess
            ? const Color(0xFF4CAF50)
            : (isError ? const Color(0xFFF44336) : secondaryColor),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: const Text(
          'งานของฉัน',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          indicatorWeight: 3,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          labelStyle: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.bold,
          ),
          tabs: const [
            Tab(icon: Icon(Icons.work_outline), text: 'งานที่สมัคร'),
            Tab(icon: Icon(Icons.post_add), text: 'งานที่โพส'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [_buildAppliedJobsTab(), _buildCreatedJobsTab()],
      ),
    );
  }

  Widget _buildAppliedJobsTab() {
    if (_isLoadingApplied) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_appliedJobs.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.work_off, size: 80, color: Colors.grey[300]),
            const SizedBox(height: 16),
            Text(
              'คุณยังไม่ได้สมัครงาน',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadAppliedJobs,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _appliedJobs.length,
        itemBuilder: (context, index) => _buildJobCard(_appliedJobs[index]),
      ),
    );
  }

  Widget _buildCreatedJobsTab() {
    if (_isLoadingCreated) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_createdJobs.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.post_add, size: 80, color: Colors.grey[300]),
            const SizedBox(height: 16),
            Text(
              'คุณยังไม่ได้ประกาศงาน',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadCreatedJobs,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _createdJobs.length,
        itemBuilder: (context, index) =>
            _buildJobCard(_createdJobs[index], isCreator: true),
      ),
    );
  }

  Widget _buildJobCard(JobModel job, {bool isCreator = false}) {
    final formatter = NumberFormat('#,##0');

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () async {
            if (isCreator) {
              // ✅ รอผลลัพธ์จากหน้า detail
              final result = await Get.toNamed(
                AppRoutes.getmyjobdetailpostedPageRoute(),
                arguments: job,
              );

              // ✅ ถ้าลบงานสำเร็จ (result = true) ให้โหลดข้อมูลใหม่
              if (result == true) {
                _loadCreatedJobs();
              }
            } else {
              Get.toNamed(AppRoutes.getJobDetailRoute(), arguments: job);
            }
          },
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        job.title,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: primaryColor,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: _getStatusColor(job.status).withOpacity(0.15),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: _getStatusColor(job.status).withOpacity(0.3),
                          width: 1,
                        ),
                      ),
                      child: Text(
                        _getStatusText(job.status),
                        style: TextStyle(
                          color: _getStatusColor(job.status),
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  job.category,
                  style: TextStyle(
                    fontSize: 13,
                    color: secondaryColor,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _buildInfoChip(
                      Icons.work_outline,
                      _getTypeText(job.type),
                      _getTypeColor(job.type),
                    ),
                    _buildInfoChip(
                      Icons.calendar_month,
                      job.deadline != null
                          ? DateFormat('dd/MM/yyyy').format(job.deadline!)
                          : 'ไม่มีกำหนด',
                      Colors.redAccent,
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Icon(Icons.people, size: 18, color: primaryColor),
                    const SizedBox(width: 6),
                    Text(
                      '${job.applicants.length} ผู้สมัคร',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: primaryColor,
                      ),
                    ),
                    const Spacer(),
                    Row(
                      children: [
                        const SizedBox(width: 4),
                        Text(
                          '${formatter.format(job.budget)} THB',
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Colors.green,
                          ),
                        ),
                      ],
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

  Widget _buildInfoChip(IconData icon, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.3), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
