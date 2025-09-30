import 'package:flutter/material.dart';
import '../component/bottom_nav.dart';
import 'package:intl/intl.dart';
import '../model/job_model.dart'; 
import 'package:get/get.dart'; 

class job_detail extends StatefulWidget { 
  const job_detail({super.key});

  @override
  State<job_detail> createState() => _job_detailState();
}

class _job_detailState extends State<job_detail> with SingleTickerProviderStateMixin {
  JobModel? _job;
  bool _isDataLoaded = false;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

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

  // --- Helper Methods ---
  
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

                // 🚀 ปุ่มสมัครงาน
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
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: const Text('กำลังดำเนินการสมัครงาน...'),
                          backgroundColor: const Color(0xFF10B981),
                          behavior: SnackBarBehavior.floating,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      );
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