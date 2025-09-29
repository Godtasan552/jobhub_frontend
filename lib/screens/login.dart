import 'package:flutter/material.dart';
import '../utils/navigation_helper.dart';
import '../services/auth_service.dart';
import '../routes/app_routes.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _phoneController = TextEditingController(); // 🔹 เพิ่ม
  final _locationController = TextEditingController(); // 🔹 เพิ่ม

  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _isLoading = false;
  bool _acceptTerms = false;

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _phoneController.dispose(); // 🔹 เพิ่ม
    _locationController.dispose(); // 🔹 เพิ่ม
    super.dispose();
  }

  Future<void> _handleRegister() async {
    if (!_formKey.currentState!.validate()) return;

    if (!_acceptTerms) {
      NavigationHelper.showWarningSnackBar('กรุณายอมรับเงื่อนไขการใช้งาน');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final result = await AuthService.register(
        name: "${_firstNameController.text.trim()} ${_lastNameController.text.trim()}",
        email: _emailController.text.trim(),
        password: _passwordController.text,
        phone: _phoneController.text.trim(), // 🔹 ส่งข้อมูลจริง
        location: _locationController.text.trim(), // 🔹 ส่งข้อมูลจริง
      );

      if (result['success'] == true) {
        NavigationHelper.showSuccessSnackBar('สมัครสมาชิกสำเร็จ');
        await Future.delayed(const Duration(milliseconds: 1500));
        Navigator.pushReplacementNamed(context, AppRoutes.getLoginRoute());
      } else {
        NavigationHelper.showErrorSnackBar(
          result['message'] ?? 'เกิดข้อผิดพลาด',
        );
      }
    } catch (e) {
      NavigationHelper.showErrorSnackBar('สมัครสมาชิกไม่สำเร็จ: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('สมัครสมาชิก')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 20),

                Text(
                  'สร้างบัญชีใหม่',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Colors.blue[700],
                      ),
                ),
                const SizedBox(height: 8),
                Text(
                  'กรุณากรอกข้อมูลให้ครบถ้วน',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 32),

                // First Name
                TextFormField(
                  controller: _firstNameController,
                  decoration: const InputDecoration(
                    labelText: 'ชื่อ',
                    prefixIcon: Icon(Icons.person_outlined),
                    isDense: true,
                  ),
                  validator: (value) =>
                      value == null || value.trim().isEmpty ? 'กรุณากรอกชื่อ' : null,
                ),
                const SizedBox(height: 16),

                // Last Name
                TextFormField(
                  controller: _lastNameController,
                  decoration: const InputDecoration(
                    labelText: 'นามสกุล',
                    prefixIcon: Icon(Icons.person_outlined),
                    isDense: true,
                  ),
                  validator: (value) =>
                      value == null || value.trim().isEmpty ? 'กรุณากรอกนามสกุล' : null,
                ),
                const SizedBox(height: 16),

                // Email
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(
                    labelText: 'อีเมล',
                    prefixIcon: Icon(Icons.email_outlined),
                    isDense: true,
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'กรุณากรอกอีเมล';
                    }
                    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
                      return 'กรุณากรอกอีเมลให้ถูกต้อง';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // 🔹 Phone Number
                TextFormField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(
                    labelText: 'เบอร์โทรศัพท์',
                    prefixIcon: Icon(Icons.phone_outlined),
                    isDense: true,
                    hintText: '08x-xxx-xxxx',
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'กรุณากรอกเบอร์โทรศัพท์';
                    }
                    if (!RegExp(r'^0[0-9]{9}$').hasMatch(value.trim())) {
                      return 'กรุณากรอกเบอร์โทรศัพท์ให้ถูกต้อง (10 หลัก)';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // 🔹 Location
                TextFormField(
                  controller: _locationController,
                  decoration: const InputDecoration(
                    labelText: 'ที่อยู่',
                    prefixIcon: Icon(Icons.location_on_outlined),
                    isDense: true,
                    hintText: 'จังหวัด, อำเภอ',
                  ),
                  validator: (value) =>
                      value == null || value.trim().isEmpty ? 'กรุณากรอกที่อยู่' : null,
                ),
                const SizedBox(height: 16),

                // Password
                TextFormField(
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  decoration: InputDecoration(
                    labelText: 'รหัสผ่าน',
                    prefixIcon: const Icon(Icons.lock_outlined),
                    isDense: true,
                    suffixIcon: IconButton(
                      icon: Icon(_obscurePassword
                          ? Icons.visibility_off
                          : Icons.visibility),
                      onPressed: () =>
                          setState(() => _obscurePassword = !_obscurePassword),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'กรุณากรอกรหัสผ่าน';
                    }
                    if (value.length < 6) {
                      return 'รหัสผ่านต้องมีอย่างน้อย 6 ตัวอักษร';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Confirm Password
                TextFormField(
                  controller: _confirmPasswordController,
                  obscureText: _obscureConfirmPassword,
                  decoration: InputDecoration(
                    labelText: 'ยืนยันรหัสผ่าน',
                    prefixIcon: const Icon(Icons.lock_outlined),
                    isDense: true,
                    suffixIcon: IconButton(
                      icon: Icon(_obscureConfirmPassword
                          ? Icons.visibility_off
                          : Icons.visibility),
                      onPressed: () => setState(() =>
                          _obscureConfirmPassword = !_obscureConfirmPassword),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'กรุณายืนยันรหัสผ่าน';
                    }
                    if (value != _passwordController.text) {
                      return 'รหัสผ่านไม่ตรงกัน';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 24),

                // Terms & Conditions
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Checkbox(
                      value: _acceptTerms,
                      onChanged: (value) =>
                          setState(() => _acceptTerms = value ?? false),
                      activeColor: Colors.blue,
                    ),
                    Expanded(
                      child: GestureDetector(
                        onTap: () =>
                            setState(() => _acceptTerms = !_acceptTerms),
                        child: Padding(
                          padding: const EdgeInsets.only(top: 12.0),
                          child: RichText(
                            text: TextSpan(
                              style: Theme.of(context).textTheme.bodyMedium,
                              children: [
                                const TextSpan(text: 'ยอมรับ'),
                                TextSpan(
                                  text: 'เงื่อนไขการใช้งาน',
                                  style: TextStyle(
                                    color: Colors.blue[600],
                                    decoration: TextDecoration.underline,
                                  ),
                                ),
                                const TextSpan(text: ' และ '),
                                TextSpan(
                                  text: 'นโยบายความเป็นส่วนตัว',
                                  style: TextStyle(
                                    color: Colors.blue[600],
                                    decoration: TextDecoration.underline,
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
                const SizedBox(height: 24),

                // Register Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _handleRegister,
                    child: _isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor:
                                  AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : const Text('สร้างบัญชี'),
                  ),
                ),
                const SizedBox(height: 24),

                // ไปหน้า Login
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('มีบัญชีอยู่แล้ว? ',
                        style: Theme.of(context).textTheme.bodyMedium),
                    TextButton(
                      onPressed: () {
                        Navigator.pushReplacementNamed(
                            context, AppRoutes.getLoginRoute());
                      },
                      child: const Text('เข้าสู่ระบบ'),
                    ),
                  ],
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