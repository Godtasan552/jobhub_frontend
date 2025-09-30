import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../model/job_model.dart'; 
import 'package:get/get.dart'; 

class job_detail extends StatefulWidget { 
  const job_detail({super.key});

  @override
  State<job_detail> createState() => _job_detailState();
}

class _job_detailState extends State<job_detail> {
  JobModel? _job;
  bool _isDataLoaded = false; 

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
      case 'active': return Colors.green;
      case 'in_progress': return Colors.orange;
      case 'completed': return Colors.blue;
      case 'closed': return Colors.grey;
      case 'cancelled': return Colors.red;
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
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: color,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  // NEW: Widget สำหรับแสดงหัวข้อ
  Widget _buildSectionHeader(String title, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(top: 16, bottom: 8),
      child: Row(
        children: [
          Icon(icon, size: 24, color: Theme.of(context).primaryColor),
          const SizedBox(width: 8),
          Text(
            title,
            style: const TextStyle(
              fontSize: 20, 
              fontWeight: FontWeight.bold, 
              // ใช้สีเดียวกับ primary color เพื่อความสวยงาม
              color: Color(0xFF1E3A8A) 
            ),
          ),
        ],
      ),
    );
  }

  // IMPROVED: Detail Row Widget
  Widget _buildDetailRow(String label, String value, {IconData? icon}) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 10),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: Colors.grey.shade200, width: 1)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          if (icon != null) Icon(icon, size: 20, color: Colors.blueGrey.shade400),
          if (icon != null) const SizedBox(width: 10),
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: TextStyle(fontWeight: FontWeight.w600, color: Colors.grey[700], fontSize: 15),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              value,
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.normal),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }

  // -------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    if (_job == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }
    
    final job = _job!;
    final formatter = NumberFormat('#,##0');
    final dateFormatter = DateFormat('dd MMM yyyy, HH:mm');

    return Scaffold(
      appBar: AppBar(
        title: Text(job.title),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 💰 ส่วนหัว: งบประมาณ และ สถานะ (ใน Card)
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('งบประมาณโครงการ:', style: TextStyle(fontSize: 14, color: Colors.grey)),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '฿${formatter.format(job.budget)}',
                          style: const TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            color: Colors.green,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                          decoration: BoxDecoration(
                            color: _getStatusColor(job.status).withOpacity(0.2),
                            borderRadius: BorderRadius.circular(25),
                            border: Border.all(color: _getStatusColor(job.status), width: 1),
                          ),
                          child: Text(
                            _getStatusText(job.status),
                            style: TextStyle(
                              color: _getStatusColor(job.status),
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8, runSpacing: 8,
                      children: [
                        _buildInfoChip(Icons.work_outline, _getTypeText(job.type), Colors.blue),
                        _buildInfoChip(Icons.category_outlined, job.category, Colors.purple),
                        _buildInfoChip(Icons.access_time, job.duration, Colors.orange),
                        _buildInfoChip(Icons.people, '${job.applicants.length} ผู้สมัคร', Colors.teal),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 24),

            // 📄 ส่วนที่ 1: คำอธิบายงาน
            _buildSectionHeader('รายละเอียดงาน', Icons.description),
            Card(
              elevation: 1,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              margin: EdgeInsets.zero,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  job.description,
                  style: TextStyle(fontSize: 16, height: 1.5, color: Colors.grey[800]),
                ),
              ),
            ),
            
            const SizedBox(height: 24),

            // 🛠️ ส่วนที่ 2: ข้อกำหนด (Requirements)
            if (job.requirements != null && job.requirements!.isNotEmpty) ...[
              _buildSectionHeader('คุณสมบัติและข้อกำหนด', Icons.checklist_rtl),
              Card(
                elevation: 1,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                margin: EdgeInsets.zero,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: job.requirements!
                        .map((req) => Padding(
                              padding: const EdgeInsets.only(bottom: 8.0),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Icon(Icons.check_circle, size: 18, color: Colors.lightGreen),
                                  const SizedBox(width: 8),
                                  Expanded(child: Text(req, style: const TextStyle(fontSize: 15, height: 1.4))),
                                ],
                              ),
                            ))
                        .toList(),
                  ),
                ),
              ),
              const SizedBox(height: 24),
            ],

            // 📦 ส่วนที่ 3: ข้อมูลระบบ (ID, Date/Time)
            _buildSectionHeader('ข้อมูลโครงการ', Icons.info_outline),
            Card(
              elevation: 1,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              margin: EdgeInsets.zero,
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
                  // ไม่มีเส้นคั่นด้านล่างสำหรับรายการสุดท้าย
                  Container(
                     padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 10),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          const Icon(Icons.update, size: 20, color: Colors.blueGrey),
                          const SizedBox(width: 10),
                          Expanded(
                            flex: 2,
                            child: Text(
                              'อัปเดตล่าสุด',
                              style: TextStyle(fontWeight: FontWeight.w600, color: Colors.grey[700], fontSize: 15),
                            ),
                          ),
                          Expanded(
                            flex: 3,
                            child: Text(
                              dateFormatter.format(job.updatedAt),
                              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.normal),
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

            // 🚀 ปุ่มดำเนินการ (Sticky Footer/Action Button)
            Center(
              child: ElevatedButton.icon(
                onPressed: job.status == 'active' ? () {
                  // TODO: Implement Apply Job Logic
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('กำลังดำเนินการสมัครงาน...')),
                  );
                } : null, 
                icon: const Icon(Icons.how_to_reg, size: 24),
                label: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: Text(
                      job.status == 'active' ? 'สมัครงานนี้' : 'งาน ${ _getStatusText(job.status)}', 
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: job.status == 'active' ? Colors.blue.shade600 : Colors.grey.shade400,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 50),
                  padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 10),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  elevation: 5,
                ),
              ),
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }
}