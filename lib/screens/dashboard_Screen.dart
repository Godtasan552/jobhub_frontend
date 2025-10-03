// lib/screens/dashboard_screen.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../services/job_service.dart';
import '../services/auth_service.dart';
import '../model/job_model.dart';
import '../utils/navigation_helper.dart';
import '../routes/app_routes.dart';
import 'package:intl/intl.dart';
import '../screens/notification_screen.dart';
import '../screens/profilePage.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  List<JobModel> _jobs = [];
  List<JobModel> _filteredJobs = [];
  bool _isLoading = true;
  String? _errorMessage;
  String _selectedCategory = 'ทั้งหมด';
  String _selectedType = 'ทั้งหมด';

  // Theme Colors
  static const Color primaryColor = Color(0xFF2C6E49);
  static const Color accentColor = Color(0xFFA3CFBB);
  static const Color secondaryColor = Color(0xFF4C956C);
  static const Color backgroundColor = Color(0xFFF8FAF9);

  // 🎨 สีสำหรับแต่ละประเภทงาน
  final Map<String, Color> jobTypeColors = {
    'freelance': const Color(0xFF3B82F6), // น้ำเงิน
    'part-time': const Color(0xFF10B981), // เขียว
    'contract': const Color(0xFFF59E0B), // ส้ม
    'full-time': const Color(0xFFEF4444), // แดง
  };

  // 📋 หมวดหมู่งานครบถ้วนเหมือน Fastwork
  final List<Map<String, dynamic>> categories = [
    {'name': 'ทั้งหมด', 'icon': Icons.apps},
    {'name': 'เทคโนโลยีและโปรแกรม', 'icon': Icons.computer},
    {'name': 'การออกแบบ', 'icon': Icons.palette},
    {'name': 'การตลาดและประชาสัมพันธ์', 'icon': Icons.campaign},
    {'name': 'การเขียนและแปล', 'icon': Icons.edit_note},
    {'name': 'ธุรกิจและการเงิน', 'icon': Icons.account_balance},
    {'name': 'วิดีโอและแอนิเมชัน', 'icon': Icons.movie},
    {'name': 'เสียงและดนตรี', 'icon': Icons.music_note},
    {'name': 'การศึกษาและฝึกอบรม', 'icon': Icons.school},
    {'name': 'การขายและบริการลูกค้า', 'icon': Icons.shopping_cart},
    {'name': 'ช่างและงานฝีมือ', 'icon': Icons.construction},
    {'name': 'ไลฟ์สไตล์และความงาม', 'icon': Icons.face},
    {'name': 'งานบ้านและงานทั่วไป', 'icon': Icons.home_repair_service},
    {'name': 'อื่นๆ', 'icon': Icons.more_horiz},
  ];

  final List<Map<String, dynamic>> jobTypes = [
    {'name': 'ทั้งหมด', 'icon': Icons.work, 'value': 'all'},
    {'name': 'ฟรีแลนซ์', 'icon': Icons.laptop_mac, 'value': 'freelance'},
    {'name': 'พาร์ทไทม์', 'icon': Icons.access_time, 'value': 'part-time'},
    {'name': 'สัญญาจ้าง', 'icon': Icons.description, 'value': 'contract'},
    {'name': 'เต็มเวลา', 'icon': Icons.business_center, 'value': 'full-time'},
  ];

  @override
  void initState() {
    super.initState();
    _loadJobs();
  }

  Future<void> _loadJobs() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final result = await JobService.getAllJobs();

      if (result['success'] == true) {
        setState(() {
          _jobs = result['jobs'];
          _filteredJobs = _jobs;
          _isLoading = false;
        });
        _applyFilters();
      } else {
        setState(() {
          _errorMessage = result['message'];
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

  void _applyFilters() {
    setState(() {
      _filteredJobs = _jobs.where((job) {
        bool categoryMatch =
            _selectedCategory == 'ทั้งหมด' || job.category == _selectedCategory;
        bool typeMatch =
            _selectedType == 'ทั้งหมด' ||
            job.type == _getTypeValue(_selectedType);
        return categoryMatch && typeMatch;
      }).toList();
    });
  }

  String _getTypeValue(String typeName) {
    final type = jobTypes.firstWhere(
      (t) => t['name'] == typeName,
      orElse: () => {'value': 'all'},
    );
    return type['value'];
  }

  // 🎨 ดึงสีตามประเภทงาน
  Color _getTypeColor(String type) {
    return jobTypeColors[type] ?? Colors.grey;
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      body: CustomScrollView(
        slivers: [
          _buildAppBar(),
          SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(),
                _buildCategoryFilter(),
                _buildTypeFilter(),
              ],
            ),
          ),
          _buildJobList(),
        ],
      ),
    );
  }

  Widget _buildAppBar() {
    return SliverAppBar(
      expandedHeight: 150,
      floating: false,
      pinned: true,
      automaticallyImplyLeading: false,
      backgroundColor: Colors.transparent,
      flexibleSpace: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [primaryColor, secondaryColor],
          ),
          borderRadius: const BorderRadius.only(
            bottomLeft: Radius.circular(24),
            bottomRight: Radius.circular(24),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.15),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: SingleChildScrollView(
              // <-- ห่อ Column
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 🔹 แถวบนสุด (โลโก้ + ปุ่ม)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "JobHub",
                        style: const TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          letterSpacing: 1.2,
                        ),
                      ),
                      Row(
                        children: [
                          IconButton(
                            icon: const Icon(
                              Icons.notifications_outlined,
                              color: Colors.white,
                              size: 26,
                            ),
                            onPressed: () {
                              Get.to(() => NotificationScreen());// ไปหน้าแจ้งเตือน
                            },
                          ),
                          const SizedBox(width: 6),
GestureDetector(
  onTap: () {
    // ไปหน้า Profile
    Get.to(() => ProfilePage());

  },
  child: CircleAvatar(
    radius: 18,
    backgroundColor: Colors.white,
    child: Icon(Icons.person, color: primaryColor),
  ),
),

                        ],
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // 🔹 Search bar
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 6,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.search, color: Colors.grey),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextField(
                            decoration: InputDecoration(
                              hintText: "ค้นหางานที่คุณสนใจ...",
                              hintStyle: TextStyle(color: Colors.grey[500]),
                              border: InputBorder.none,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
  return Padding(
    padding: const EdgeInsets.all(20),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // ด้านซ้าย
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'งานทั้งหมดของฉัน',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: primaryColor,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '${_filteredJobs.length} งานที่พร้อมให้คุณสมัคร',
              style: TextStyle(fontSize: 14, color: Colors.grey[600]),
            ),
          ],
        ),

        // ด้านขวา → ปุ่ม
        ElevatedButton(
          onPressed: () => Get.toNamed(AppRoutes.getmyjobpostedPageRoute()),
          child: const Text('งานของฉัน'),
        ),
      ],
    ),
  );
}


  Widget _buildCategoryFilter() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Text(
            'หมวดหมู่งาน',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: primaryColor,
            ),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 100,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: categories.length,
            itemBuilder: (context, index) {
              final category = categories[index];
              final isSelected = _selectedCategory == category['name'];

              return Padding(
                padding: const EdgeInsets.only(right: 12),
                child: InkWell(
                  onTap: () {
                    setState(() {
                      _selectedCategory = category['name'];
                    });
                    _applyFilters();
                  },
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    width: 90,
                    decoration: BoxDecoration(
                      gradient: isSelected
                          ? LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [primaryColor, secondaryColor],
                            )
                          : null,
                      color: isSelected ? null : Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isSelected
                            ? Colors.transparent
                            : accentColor.withOpacity(0.3),
                        width: 1.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: isSelected
                              ? primaryColor.withOpacity(0.3)
                              : Colors.black.withOpacity(0.05),
                          blurRadius: isSelected ? 12 : 6,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? Colors.white.withOpacity(0.2)
                                : accentColor.withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            category['icon'],
                            color: isSelected ? Colors.white : secondaryColor,
                            size: 24,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          category['name'],
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: isSelected ? Colors.white : Colors.grey[800],
                          ),
                          textAlign: TextAlign.center,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 20),
      ],
    );
  }

  Widget _buildTypeFilter() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Text(
            'ประเภทงาน',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: primaryColor,
            ),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 50,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: jobTypes.length,
            itemBuilder: (context, index) {
              final type = jobTypes[index];
              final isSelected = _selectedType == type['name'];

              // 🎨 กำหนดสีตามประเภทงาน
              Color typeColor = type['value'] == 'all'
                  ? secondaryColor
                  : _getTypeColor(type['value']);

              return Padding(
                padding: const EdgeInsets.only(right: 10),
                child: InkWell(
                  onTap: () {
                    setState(() {
                      _selectedType = type['name'];
                    });
                    _applyFilters();
                  },
                  borderRadius: BorderRadius.circular(25),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: isSelected ? typeColor : Colors.white,
                      borderRadius: BorderRadius.circular(25),
                      border: Border.all(
                        color: isSelected
                            ? Colors.transparent
                            : typeColor.withOpacity(0.3),
                        width: 1.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: isSelected
                              ? typeColor.withOpacity(0.3)
                              : Colors.black.withOpacity(0.03),
                          blurRadius: isSelected ? 8 : 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          type['icon'],
                          size: 18,
                          color: isSelected ? Colors.white : typeColor,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          type['name'],
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: isSelected ? Colors.white : Colors.grey[800],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildJobList() {
    if (_isLoading) {
      return const SliverFillRemaining(
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (_errorMessage != null) {
      return SliverFillRemaining(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
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
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      );
    }

    if (_filteredJobs.isEmpty) {
      return SliverFillRemaining(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.work_off, size: 80, color: Colors.grey[300]),
              const SizedBox(height: 16),
              Text(
                'ไม่พบงานที่คุณค้นหา',
                style: TextStyle(
                  fontSize: 18,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'ลองเปลี่ยนตัวกรองดูนะ',
                style: TextStyle(fontSize: 14, color: Colors.grey[400]),
              ),
            ],
          ),
        ),
      );
    }

    return SliverPadding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, index) => _buildJobCard(_filteredJobs[index]),
          childCount: _filteredJobs.length,
        ),
      ),
    );
  }

  Widget _buildJobCard(JobModel job) {
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
          onTap: () {
            Get.toNamed(AppRoutes.getJobDetailRoute(), arguments: job);
          },
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 🔹 Title + Status
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

                // 🔹 Category
                Text(
                  job.category,
                  style: TextStyle(
                    fontSize: 13,
                    color: secondaryColor,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 12),

                // 🔹 Chips: type, budget, deadline
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

                const SizedBox(height: 16),

                // 🔹 Applicants
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
                    const Spacer(), // ดันงบประมาณไปขวาสุด
                    Row(
                      children: [
                        Icon(
                          Icons.attach_money,
                          size: 26,
                          color: Colors.green,
                        ), // ไอคอนใหญ่ขึ้น
                        const SizedBox(width: 4),
                        Text(
                          '฿${formatter.format(job.budget)}',
                          style: TextStyle(
                            fontSize: 22, // ✅ ขยายใหญ่
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
