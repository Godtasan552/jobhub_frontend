import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:intl/intl.dart';
import 'package:get_storage/get_storage.dart';

class CreateJobScreen extends StatefulWidget {
  const CreateJobScreen({super.key});

  @override
  State<CreateJobScreen> createState() => _CreateJobScreenState();
}

class _CreateJobScreenState extends State<CreateJobScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _budgetController = TextEditingController();
  final TextEditingController _durationController = TextEditingController();
  final TextEditingController _requirementsController = TextEditingController();
  final storage = GetStorage();
  String _selectedType = 'freelance';
  String _selectedCategory = 'technology';
  DateTime? _selectedDeadline;
  bool _isLoading = false;

  final List<String> _jobTypes = [
    'freelance',
    'part-time',
    'contract',
    'full-time',
  ];

  final List<String> _categories = [
    'technology',
    'web development',
    'mobile development',
    'design',
    'marketing',
    'writing',
    'data entry',
    'customer service',
    'sales',
    'other',
  ];

  final Map<String, String> _jobTypeLabels = {
    'freelance': 'งานฟรีแลนซ์',
    'part-time': 'งานพาร์ทไทม์',
    'contract': 'งานสัญญา',
    'full-time': 'งานเต็มเวลา',
  };

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _budgetController.dispose();
    _durationController.dispose();
    _requirementsController.dispose();
    super.dispose();
  }

  Future<void> _selectDeadline() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 7)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: Colors.blue[700]!,
              onPrimary: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _selectedDeadline) {
      setState(() {
        _selectedDeadline = picked;
      });
    }
  }

  Future<void> _createJob() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }


    setState(() {
      _isLoading = true;
    });

    try {
      final token = storage.read('token');
      print("try 1 passed");
      if (token == null || token.isEmpty) {
        Get.snackbar(
          'Error',
          'ไม่พบ Token กรุณาเข้าสู่ระบบใหม่',
          backgroundColor: Colors.red[100],
          colorText: Colors.red[900],
          snackPosition: SnackPosition.TOP,
        );
        setState(() {
          _isLoading = false;
        });
        return;
      }

      final String baseUrl = dotenv.env['BASE_URL'] ?? 'http://localhost:5000';

      // แปลง requirements จาก string เป็น array
      List<String> requirements = _requirementsController.text
          .split(',')
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .toList();

      Map<String, dynamic> requestBody = {
        'title': _titleController.text.trim(),
        'description': _descriptionController.text.trim(),
        'type': _selectedType,
        'category': _selectedCategory,
        'budget': double.parse(_budgetController.text),
        'duration': _durationController.text.trim(),
        'requirements': requirements,
        'attachments': [],
        'deadline': _selectedDeadline!.toIso8601String(),
      };

      print('📤 Sending request body: ${json.encode(requestBody)}');

      final response = await http.post(
        Uri.parse('$baseUrl/api/v1/jobs'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode(requestBody),
      );

      print('📡 Response status: ${response.statusCode}');
      print('📡 Response body: ${response.body}');

      final data = json.decode(response.body);

      if (data['success'] == true) {
        Get.snackbar(
          'สำเร็จ',
          data['message'] ?? 'สร้างงานเรียบร้อยแล้ว',
          backgroundColor: Colors.green[100],
          colorText: Colors.green[900],
          duration: const Duration(seconds: 2),
          snackPosition: SnackPosition.TOP,
        );

        // รีเซ็ตฟอร์ม
        if(mounted){
               _formKey.currentState?.reset();
        _titleController.clear();
        _descriptionController.clear();
        _budgetController.clear();
        _durationController.clear();
        _requirementsController.clear();
        setState(() {
          _selectedDeadline = null;
          _selectedType = 'freelance';
          _selectedCategory = 'technology';
        });
         Get.back();
        }

        // กลับไปหน้า Dashboard หรือ Job List
      } else {
        // แสดง error message จาก API
        String errorMessage = data['message'] ?? 'ไม่สามารถสร้างงานได้';

        // ตรวจสอบ validation errors แบบปลอดภัย
        if (data['data']?['errors'] != null) {
          List<dynamic> errors = data['data']!['errors'] as List<dynamic>;
          if (errors.isNotEmpty) {
            errorMessage = errors.map((e) => e['message']).join(', ');
          }
        }

        Get.snackbar(
          'Error',
          errorMessage,
          backgroundColor: Colors.red[100],
          colorText: Colors.red[900],
          snackPosition: SnackPosition.TOP,
          duration: const Duration(seconds: 4),
        );
      }
    } catch (e) {
      print('Error creating job snackbar bottom: $e');
      Get.snackbar(
        'Error',
        'เกิดข้อผิดพลาด: $e',
        backgroundColor: Colors.red[100],
        colorText: const Color.fromARGB(255, 241, 171, 19),
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(seconds: 4),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('สร้างงานใหม่'), elevation: 0),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.blue[50],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.work, color: Colors.blue[700], size: 32),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'สร้างโพสต์งาน',
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.blue[900],
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'กรอกข้อมูลงานที่ต้องการหาคนทำ',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.blue[700],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Title
                    TextFormField(
                      controller: _titleController,
                      decoration: const InputDecoration(
                        labelText: 'ชื่องาน',
                        hintText: 'เช่น: ต้องการนักพัฒนาเว็บไซต์',
                        prefixIcon: Icon(Icons.title),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'กรุณากรอกชื่องาน';
                        }
                        if (value.trim().length < 5) {
                          return 'ชื่องานต้องมีอย่างน้อย 5 ตัวอักษร';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Description
                    TextFormField(
                      controller: _descriptionController,
                      decoration: const InputDecoration(
                        labelText: 'รายละเอียดงาน',
                        hintText: 'อธิบายงานที่ต้องการให้ทำ',
                        prefixIcon: Icon(Icons.description),
                        alignLabelWithHint: true,
                      ),
                      maxLines: 5,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'กรุณากรอกรายละเอียดงาน';
                        }
                        if (value.trim().length < 20) {
                          return 'รายละเอียดต้องมีอย่างน้อย 20 ตัวอักษร';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Job Type Dropdown
                    DropdownButtonFormField<String>(
                      value: _selectedType,
                      decoration: const InputDecoration(
                        labelText: 'ประเภทงาน',
                        prefixIcon: Icon(Icons.category),
                      ),
                      items: _jobTypes.map((type) {
                        return DropdownMenuItem(
                          value: type,
                          child: Text(_jobTypeLabels[type] ?? type),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          _selectedType = value!;
                        });
                      },
                    ),
                    const SizedBox(height: 16),

                    // Category Dropdown
                    DropdownButtonFormField<String>(
                      value: _selectedCategory,
                      decoration: const InputDecoration(
                        labelText: 'หมวดหมู่',
                        prefixIcon: Icon(Icons.label),
                      ),
                      items: _categories.map((category) {
                        return DropdownMenuItem(
                          value: category,
                          child: Text(category),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          _selectedCategory = value!;
                        });
                      },
                    ),
                    const SizedBox(height: 16),

                    // Budget
                    TextFormField(
                      controller: _budgetController,
                      decoration: const InputDecoration(
                        labelText: 'งบประมาณ (บาท)',
                        hintText: 'เช่น: 5000',
                        prefixIcon: Icon(Icons.attach_money),
                      ),
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'กรุณากรอกงบประมาณ';
                        }
                        final budget = double.tryParse(value);
                        if (budget == null || budget <= 0) {
                          return 'งบประมาณต้องเป็นตัวเลขที่มากกว่า 0';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Duration
                    TextFormField(
                      controller: _durationController,
                      decoration: const InputDecoration(
                        labelText: 'ระยะเวลาทำงาน',
                        hintText: 'เช่น: 1 month, 2 weeks',
                        prefixIcon: Icon(Icons.access_time),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'กรุณากรอกระยะเวลาทำงาน';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Deadline
                    InkWell(
                      onTap: _selectDeadline,
                      child: InputDecorator(
                        decoration: InputDecoration(
                          labelText: 'วันที่สิ้นสุดรับสมัคร',
                          prefixIcon: const Icon(Icons.calendar_today),
                          // เพิ่ม error text ถ้า validation ไม่ผ่าน
                          errorText: _selectedDeadline == null
                              ? 'กรุณาเลือกวันที่สิ้นสุด'
                              : null,
                        ),
                        child: Text(
                          _selectedDeadline == null
                              ? 'เลือกวันที่'
                              : DateFormat(
                                  'dd/MM/yyyy',
                                ).format(_selectedDeadline!),
                          style: TextStyle(
                            color: _selectedDeadline == null
                                ? Colors.grey[600]
                                : Colors.black,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Requirements
                    TextFormField(
                      controller: _requirementsController,
                      decoration: const InputDecoration(
                        labelText: 'คุณสมบัติที่ต้องการ (ไม่บังคับ)',
                        hintText:
                            'เช่น: React, Node.js, MongoDB (คั่นด้วยจุลภาค)',
                        prefixIcon: Icon(Icons.checklist),
                      ),
                      maxLines: 3,
                    ),
                    const SizedBox(height: 32),

                    // Submit Button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _createJob,
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: _isLoading
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    Colors.white,
                                  ),
                                ),
                              )
                            : const Text(
                                'สร้างงาน',
                                style: TextStyle(fontSize: 18),
                              ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Info Box
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.amber[50],
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.amber[200]!),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(Icons.info_outline, color: Colors.amber[700]),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'หมายเหตุ: งานที่สร้างจะแสดงในระบบทันทีและ worker ที่ได้รับอนุมัติแล้วสามารถสมัครได้',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.amber[900],
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
    );
  }
}
