// lib/screens/my_job_detail_screen.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:get/get.dart';
import '../model/job_model.dart';
import '../services/job_service.dart';
import '../services/wallet_service.dart';
import '../routes/app_routes.dart';
import '../model/application_model.dart';

class MyJobDetailScreen extends StatefulWidget {
  const MyJobDetailScreen({super.key});

  @override
  State<MyJobDetailScreen> createState() => _MyJobDetailScreenState();
}

class _MyJobDetailScreenState extends State<MyJobDetailScreen>
    with SingleTickerProviderStateMixin {
  JobModel? _job;
  List<dynamic> _applications = [];
  bool _isDataLoaded = false;
  bool _isLoadingApplications = false;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

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
        _loadApplications();
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

  Future<void> _loadApplications() async {
    if (_job == null) return;
    setState(() => _isLoadingApplications = true);

    final result = await JobService.getJobApplications(_job!.id);

    if (result['success'] == true) {
      setState(() {
        _applications = (result['applications'] as List)
            .map((app) => ApplicationModel.fromJson(app))
            .toList();
        _isLoadingApplications = false;
      });
    } else {
      setState(() => _isLoadingApplications = false);
      _showSnackBar(result['message'], isError: true);
    }
  }

  Future<void> _deleteJob() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.warning, color: Colors.orange),
            const SizedBox(width: 8),
            const Text('ยืนยันการลบ'),
          ],
        ),
        content: const Text('คุณแน่ใจหรือไม่ที่จะลบงานนี้?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('ยกเลิก'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('ลบ'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final result = await JobService.deleteJob(_job!.id);
      if (result['success'] == true) {
        _showSnackBar('ลบงานสำเร็จ', isSuccess: true);
        Get.back(result: true);
      } else {
        _showSnackBar(result['message'], isError: true);
      }
    }
  }

  Future<void> _assignWorker(String workerId) async {
    Get.dialog(
      const Center(child: CircularProgressIndicator()),
      barrierDismissible: false,
    );

    try {
      final result = await JobService.assignJob(
        jobId: _job!.id,
        workerId: workerId,
      );

      Get.back();

      if (result['success'] == true) {
        _showSnackBar('มอบหมายงานสำเร็จ', isSuccess: true);
        await _refreshJobData();
      } else {
        _showSnackBar(result['message'], isError: true);
      }
    } catch (e) {
      Get.back();
      _showSnackBar('เกิดข้อผิดพลาด: $e', isError: true);
      print('❌ assignWorker Error: $e');
    }
  }

  Future<void> _refreshJobData() async {
    final updatedJob = await JobService.getJobById(_job!.id);
    if (updatedJob['success'] == true) {
      setState(() => _job = updatedJob['job']);
    }
    await _loadApplications();
  }

  Future<void> _showCompleteJobDialog() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.task_alt, color: Colors.green[700]),
            const SizedBox(width: 8),
            const Text('ยืนยันงานเสร็จสิ้น'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('ยืนยันว่างานนี้เสร็จสมบูรณ์แล้ว?'),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.amber[50],
                border: Border.all(color: Colors.amber[200]!),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.amber[700], size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'ระบบจะโอนเงิน ฿${NumberFormat('#,##0').format(_job!.budget)} ให้ผู้รับงานทันที',
                      style: TextStyle(fontSize: 12, color: Colors.amber[900]),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('ยกเลิก'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green[700]),
            child: const Text('ยืนยัน'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await _completeJobAndPay();
    }
  }

  Future<void> _completeJobAndPay() async {
    if (_job?.workerId == null || _job!.workerId!.isEmpty) {
      _showSnackBar('ยังไม่มีการมอบหมายงานให้ใคร', isError: true);
      return;
    }

    // แสดง Mock Payment Flow
    await _showMockPaymentFlow();
  }

  Future<void> _showMockPaymentFlow() async {
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => _MockPaymentDialog(job: _job!),
    );

    _showSnackBar('การทดสอบ: จำลองการชำระเงินสำเร็จ', isSuccess: true);
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

  void _showApplicationsBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.8,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  Text(
                    'ผู้สมัครทั้งหมด (${_applications.length})',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: primaryColor,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            Expanded(
              child: _isLoadingApplications
                  ? const Center(child: CircularProgressIndicator())
                  : _applications.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.inbox, size: 64, color: Colors.grey[300]),
                          const SizedBox(height: 16),
                          Text(
                            'ยังไม่มีผู้สมัคร',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                      itemCount: _applications.length,
                      itemBuilder: (context, index) {
                        final app = _applications[index];
                        return _buildApplicationCard(app);
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildApplicationCard(dynamic application) {
    if (application is! ApplicationModel) {
      return Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.red[50],
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text('ข้อมูลไม่ถูกต้อง: ต้องเป็น ApplicationModel'),
      );
    }

    final app = application as ApplicationModel;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: accentColor.withOpacity(0.3)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 28,
                backgroundColor: accentColor,
                backgroundImage: app.workerProfilePic != null
                    ? NetworkImage(app.workerProfilePic!)
                    : null,
                child: app.workerProfilePic == null
                    ? Icon(Icons.person, color: primaryColor, size: 28)
                    : null,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      app.workerName,
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                        color: primaryColor,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      app.workerEmail,
                      style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: app.status == 'pending'
                      ? Colors.orange[100]
                      : (app.status == 'accepted'
                            ? Colors.green[100]
                            : Colors.grey[100]),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  app.status == 'pending'
                      ? 'รอพิจารณา'
                      : (app.status == 'accepted' ? 'ตอบรับแล้ว' : app.status),
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: app.status == 'pending'
                        ? Colors.orange[800]
                        : (app.status == 'accepted'
                              ? Colors.green[800]
                              : Colors.grey[800]),
                  ),
                ),
              ),
            ],
          ),
          const Divider(height: 24),
          if (app.coverLetter.isNotEmpty &&
              app.coverLetter != 'ไม่มีข้อมูลจดหมายปะหน้า') ...[
            Text(
              'จดหมายปะหน้า',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: primaryColor,
              ),
            ),
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                app.coverLetter,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[800],
                  height: 1.4,
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],
          if (app.proposedBudget > 0) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'งบประมาณที่เสนอ',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[700],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.green[50],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '฿${NumberFormat('#,##0').format(app.proposedBudget)}',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.green[700],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
          ],
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    Navigator.pop(context);
                    Get.toNamed(
                      AppRoutes.getChatRoute(),
                      arguments: {
                        'userId': app.workerId,
                        'userName': app.workerName,
                      },
                    );
                  },
                  icon: const Icon(Icons.chat_bubble_outline, size: 18),
                  label: const Text('แชท'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: primaryColor,
                    side: BorderSide(color: primaryColor),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
              if (_job?.status == 'active') ...[
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          title: Row(
                            children: [
                              Icon(
                                Icons.assignment_turned_in,
                                color: primaryColor,
                              ),
                              const SizedBox(width: 8),
                              const Text('ยืนยันการมอบหมาย'),
                            ],
                          ),
                          content: Text(
                            'คุณต้องการมอบหมายงานนี้ให้ ${app.workerName} ใช่หรือไม่?',
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(ctx),
                              child: const Text('ยกเลิก'),
                            ),
                            ElevatedButton(
                              onPressed: () {
                                Navigator.pop(ctx);
                                Navigator.pop(context);
                                _assignWorker(app.workerId);
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: primaryColor,
                              ),
                              child: const Text('ยืนยัน'),
                            ),
                          ],
                        ),
                      );
                    },
                    icon: const Icon(Icons.check_circle, size: 18),
                    label: const Text('มอบหมายงาน'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ],
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
                actions: [
                  if (job.status == 'in_progress')
                    IconButton(
                      icon: const Icon(Icons.check_circle_outline),
                      tooltip: 'งานเสร็จสิ้น',
                      onPressed: _showCompleteJobDialog,
                    ),
                  PopupMenuButton<String>(
                    icon: const Icon(Icons.more_vert, color: Colors.white),
                    onSelected: (value) async {
                      if (value == 'edit') {
                        final result = await Get.toNamed(
                          AppRoutes.getEditJobRoute(),
                          arguments: _job,
                        );

                        if (result == true) {
                          final updatedJob = await JobService.getJobById(
                            _job!.id,
                          );
                          if (updatedJob['success'] == true) {
                            setState(() {
                              _job = updatedJob['job'];
                            });
                            _showSnackBar(
                              'โหลดข้อมูลใหม่เรียบร้อย',
                              isSuccess: true,
                            );
                          }
                        }
                      } else if (value == 'delete') {
                        _deleteJob();
                      }
                    },
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: 'edit',
                        child: Row(
                          children: [
                            Icon(Icons.edit, size: 20),
                            SizedBox(width: 12),
                            Text('แก้ไขงาน'),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(Icons.delete, size: 20, color: Colors.red),
                            SizedBox(width: 12),
                            Text('ลบงาน', style: TextStyle(color: Colors.red)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
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
                  onPressed: _showApplicationsBottomSheet,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryColor,
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
                      const Icon(Icons.people, size: 20),
                      const SizedBox(width: 10),
                      Text(
                        'ดูผู้สมัคร (${_applications.length})',
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

// Mock Payment Dialog Widget
class _MockPaymentDialog extends StatefulWidget {
  final JobModel job;

  const _MockPaymentDialog({required this.job});

  @override
  State<_MockPaymentDialog> createState() => _MockPaymentDialogState();
}

class _MockPaymentDialogState extends State<_MockPaymentDialog> {
  int _currentStep = 0;

  final List<String> _steps = [
    'กำลังตรวจสอบสถานะงาน...',
    'กำลังอัพเดทสถานะเป็น completed...',
    'กำลังโอนเงินให้ผู้รับงาน...',
    'เสร็จสิ้น',
  ];

  @override
  void initState() {
    super.initState();
    _simulatePayment();
  }

  Future<void> _simulatePayment() async {
    for (int i = 0; i < _steps.length; i++) {
      await Future.delayed(const Duration(milliseconds: 1200));
      if (mounted) {
        setState(() => _currentStep = i);
      }
    }

    await Future.delayed(const Duration(milliseconds: 800));
    if (mounted) {
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isComplete = _currentStep == _steps.length - 1;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isComplete ? Colors.green[50] : Colors.blue[50],
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    isComplete ? Icons.check_circle : Icons.payments,
                    color: isComplete ? Colors.green[700] : Colors.blue[700],
                    size: 32,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isComplete ? 'ชำระเงินสำเร็จ' : 'กำลังดำเนินการ',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        '฿${NumberFormat('#,##0').format(widget.job.budget)}',
                        style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Progress Steps
            ...List.generate(_steps.length, (index) {
              final isDone = index < _currentStep;
              final isCurrent = index == _currentStep;

              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  children: [
                    Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        color: isDone || isCurrent
                            ? (isComplete && index == _steps.length - 1
                                  ? Colors.green[700]
                                  : Colors.blue[700])
                            : Colors.grey[300],
                        shape: BoxShape.circle,
                      ),
                      child: isDone
                          ? const Icon(
                              Icons.check,
                              color: Colors.white,
                              size: 16,
                            )
                          : (isCurrent && !isComplete
                                ? const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: Padding(
                                      padding: EdgeInsets.all(4),
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        valueColor:
                                            AlwaysStoppedAnimation<Color>(
                                              Colors.white,
                                            ),
                                      ),
                                    ),
                                  )
                                : null),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        _steps[index],
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: isCurrent || isDone
                              ? FontWeight.w600
                              : FontWeight.normal,
                          color: isCurrent || isDone
                              ? Colors.black87
                              : Colors.grey[500],
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }),

            const SizedBox(height: 16),

            // Mock Warning
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.orange[200]!),
              ),
              child: Row(
                children: [
                  Icon(Icons.science, color: Colors.orange[700], size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'โหมดทดสอบ - ไม่มีการเรียก API จริง',
                      style: TextStyle(fontSize: 11, color: Colors.orange[900]),
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
}
