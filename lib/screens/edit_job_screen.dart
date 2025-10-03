import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../model/job_model.dart';
import '../services/job_service.dart';

class EditJobScreen extends StatefulWidget {
  const EditJobScreen({super.key});

  @override
  State<EditJobScreen> createState() => _EditJobScreenState();
}

class _EditJobScreenState extends State<EditJobScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _budgetController = TextEditingController();
  final TextEditingController _durationController = TextEditingController();
  final TextEditingController _requirementsController = TextEditingController();

  JobModel? _job;
  String _selectedType = 'freelance';
  String _selectedCategory = 'เทคโนโลยีและโปรแกรม';
  DateTime? _selectedDeadline;
  bool _isLoading = false;
  bool _isDataLoaded = false;

  final List<String> _jobTypes = [
    'freelance',
    'part-time',
    'contract',
    'full-time',
  ];

  final List<String> _categories = [
    'เทคโนโลยีและโปรแกรม',
    'การออกแบบ',
    'การตลาดและประชาสัมพันธ์',
    'การเขียนและแปล',
    'ธุรกิจและการเงิน',
    'วิดีโอและแอนิเมชัน',
    'เสียงและดนตรี',
    'การศึกษาและฝึกอบรม',
    'การขายและบริการลูกค้า',
    'ช่างและงานฝีมือ',
    'ไลฟ์สไตล์และความงาม',
    'งานบ้านและงานทั่วไป',
    'อื่นๆ',
  ];

  final Map<String, String> _jobTypeLabels = {
    'freelance': 'งานฟรีแลนซ์',
    'part-time': 'งานพาร์ทไทม์',
    'contract': 'งานสัญญา',
    'full-time': 'งานเต็มเวลา',
  };

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadJobData();
    });
  }

  void _loadJobData() {
    final jobArgument = Get.arguments;
    if (jobArgument != null && jobArgument is JobModel) {
      setState(() {
        _job = jobArgument;
        _titleController.text = _job!.title;
        _descriptionController.text = _job!.description;
        _budgetController.text = _job!.budget.toString();
        _durationController.text = _job!.duration;
        _selectedType = _job!.type;
        
        // ✅ ตรวจสอบว่า category จาก API มีใน dropdown หรือไม่
        if (_categories.contains(_job!.category)) {
          _selectedCategory = _job!.category;
        } else {
          // ถ้าไม่มี ให้ใช้ค่าเริ่มต้น
          _selectedCategory = 'เทคโนโลยีและโปรแกรม';
          print('⚠️ Category "${_job!.category}" not found in list, using default');
        }
        
        _selectedDeadline = _job!.deadline;
        
        if (_job!.requirements != null && _job!.requirements!.isNotEmpty) {
          _requirementsController.text = _job!.requirements!.join(', ');
        }
        
        _isDataLoaded = true;
      });
    } else {
      Get.snackbar(
        'Error',
        'ไม่พบข้อมูลงานที่ต้องการแก้ไข',
        backgroundColor: Colors.red[100],
        colorText: Colors.red[900],
        snackPosition: SnackPosition.TOP,
      );
      Get.back();
    }
  }

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
      initialDate: _selectedDeadline ?? DateTime.now().add(const Duration(days: 7)),
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

  Future<void> _updateJob() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_selectedDeadline == null) {
      Get.snackbar(
        'Error',
        'กรุณาเลือกวันที่สิ้นสุดรับสมัคร',
        backgroundColor: Colors.red[100],
        colorText: Colors.red[900],
        snackPosition: SnackPosition.TOP,
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      List<String> requirements = _requirementsController.text
          .split(',')
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .toList();

      Map<String, dynamic> updates = {
        'title': _titleController.text.trim(),
        'description': _descriptionController.text.trim(),
        'type': _selectedType,
        'category': _selectedCategory,
        'budget': double.parse(_budgetController.text),
        'duration': _durationController.text.trim(),
        'requirements': requirements,
        'deadline': _selectedDeadline!.toIso8601String(),
      };

      final result = await JobService.updateJob(_job!.id, updates);

      if (result['success'] == true) {
        Get.back(result: true);
        Get.snackbar(
          'สำเร็จ',
          result['message'] ?? 'แก้ไขงานเรียบร้อยแล้ว',
          backgroundColor: Colors.green[100],
          colorText: Colors.green[900],
          duration: const Duration(seconds: 2),
          snackPosition: SnackPosition.TOP,
        );
      } else {
        Get.snackbar(
          'Error',
          result['message'] ?? 'ไม่สามารถแก้ไขงานได้',
          backgroundColor: Colors.red[100],
          colorText: Colors.red[900],
          snackPosition: SnackPosition.TOP,
          duration: const Duration(seconds: 4),
        );
      }
    } catch (e) {
      Get.snackbar(
        'Error',
        'เกิดข้อผิดพลาด: $e',
        backgroundColor: Colors.red[100],
        colorText: Colors.red[900],
        snackPosition: SnackPosition.TOP,
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
    if (!_isDataLoaded) {
      return Scaffold(
        appBar: AppBar(title: const Text('แก้ไขงาน')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('แก้ไขงาน'),
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.orange[50],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.edit, color: Colors.orange[700], size: 32),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'แก้ไขข้อมูลงาน',
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.orange[900],
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'ปรับปรุงรายละเอียดงานของคุณ',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.orange[700],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

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

                    DropdownButtonFormField<String>(
                      value: _selectedCategory,
                      decoration: const InputDecoration(
                        labelText: 'หมวดหมู่',
                        prefixIcon: Icon(Icons.label),
                      ),
                      isExpanded: true,
                      items: _categories.map((category) {
                        return DropdownMenuItem(
                          value: category,
                          child: Text(
                            category,
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                          ),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          _selectedCategory = value!;
                        });
                      },
                    ),
                    const SizedBox(height: 16),

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

                    InkWell(
                      onTap: _selectDeadline,
                      child: InputDecorator(
                        decoration: const InputDecoration(
                          labelText: 'วันที่สิ้นสุดรับสมัคร',
                          prefixIcon: Icon(Icons.calendar_today),
                        ),
                        child: Text(
                          _selectedDeadline == null
                              ? 'เลือกวันที่ (บังคับ)'
                              : DateFormat('dd/MM/yyyy').format(_selectedDeadline!),
                          style: TextStyle(
                            color: _selectedDeadline == null
                                ? Colors.grey[600]
                                : Colors.black,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    TextFormField(
                      controller: _requirementsController,
                      decoration: const InputDecoration(
                        labelText: 'คุณสมบัติที่ต้องการ (ไม่บังคับ)',
                        hintText: 'เช่น: React, Node.js, MongoDB (คั่นด้วยจุลภาค)',
                        prefixIcon: Icon(Icons.checklist),
                      ),
                      maxLines: 3,
                    ),
                    const SizedBox(height: 32),

                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _updateJob,
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          backgroundColor: Colors.orange[700],
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
                                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                ),
                              )
                            : const Text(
                                'บันทึกการแก้ไข',
                                style: TextStyle(
                                  fontSize: 18,
                                  color: Colors.white,
                                ),
                              ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.blue[50],
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.blue[200]!),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(Icons.info_outline, color: Colors.blue[700]),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'หมายเหตุ: การแก้ไขจะมีผลทันทีและผู้สมัครจะเห็นข้อมูลใหม่',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.blue[900],
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