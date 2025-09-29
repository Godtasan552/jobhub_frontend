import 'package:flutter/material.dart';
import '../utils/navigation_helper.dart';
import '../services/auth_service.dart';
import '../routes/app_routes.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final result = await AuthService.login(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );

      if (result['success'] == true) {
        NavigationHelper.showSuccessSnackBar('เข้าสู่ระบบสำเร็จ');
        await Future.delayed(const Duration(milliseconds: 1000));
        NavigationHelper.toHome(clearStack: true);
      } else {
        NavigationHelper.showErrorSnackBar(
            result['message'] ?? 'เข้าสู่ระบบไม่สำเร็จ');
      }
    } catch (e) {
      NavigationHelper.showErrorSnackBar('เกิดข้อผิดพลาด: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('เข้าสู่ระบบ')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(height: 40),

                // Logo หรือ Title
                Icon(
                  Icons.lock_person,
                  size: 80,
                  color: Colors.blue[700],
                ),
                const SizedBox(height: 24),

                Text(
                  'ยินดีต้อนรับกลับมา',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Colors.blue[700],
                      ),
                ),
                const SizedBox(height: 8),
                Text(
                  'เข้าสู่ระบบเพื่อดำเนินการต่อ',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 40),

                // Email Field
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(
                    labelText: 'อีเมล',
                    prefixIcon: Icon(Icons.email_outlined),
                    isDense: true,
                  ),
                  validator: (v) =>
                      v == null || v.trim().isEmpty ? 'กรุณากรอกอีเมล' : null,
                ),
                const SizedBox(height: 16),

                // Password Field
                TextFormField(
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  decoration: InputDecoration(
                    labelText: 'รหัสผ่าน',
                    prefixIcon: const Icon(Icons.lock_outline),
                    isDense: true,
                    suffixIcon: IconButton(
                      icon: Icon(_obscurePassword
                          ? Icons.visibility_off
                          : Icons.visibility),
                      onPressed: () =>
                          setState(() => _obscurePassword = !_obscurePassword),
                    ),
                  ),
                  validator: (v) =>
                      v == null || v.isEmpty ? 'กรุณากรอกรหัสผ่าน' : null,
                ),
                const SizedBox(height: 24),

                // Login Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _handleLogin,
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
                        : const Text('เข้าสู่ระบบ'),
                  ),
                ),
                const SizedBox(height: 20),

                // ปุ่มไปหน้า Register
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'ยังไม่มีบัญชี? ',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.pushNamed(context, AppRoutes.getRegisterRoute());
                      },
                      child: const Text('สมัครสมาชิก'),
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
}