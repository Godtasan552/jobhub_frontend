// lib/routes/app_pages.dart

import 'package:get/get.dart';
import 'app_routes.dart';

import '../screens/splash_screen.dart';
import '../screens/login.dart';
import '../screens/regis.dart';
import '../screens/forget_pass.dart';
import '../component/bottom_nav.dart';
import '../screens/profilePage.dart';
import '../screens/dashboard_Screen.dart'; // ✅ แก้ชื่อให้ตรง
import '../screens/notification_screen.dart';


class AppPages {
  AppPages._();

  static final routes = [
    // Splash Screen
    GetPage(
      name: AppRoutes.SPLASH,
      page: () => const SplashScreen(),
      transition: Transition.fadeIn,
      transitionDuration: const Duration(milliseconds: 300),
    ),

    // Login Page
    GetPage(
      name: AppRoutes.LOGIN,
      page: () => const LoginScreen(),
      transition: Transition.fadeIn,
      transitionDuration: const Duration(milliseconds: 300),
    ),

    // Register Page
    GetPage(
      name: AppRoutes.REGISTER,
      page: () => const RegisterScreen(),
      transition: Transition.rightToLeft,
      transitionDuration: const Duration(milliseconds: 300),
    ),

    // Forget Password Page
    GetPage(
      name: AppRoutes.FORGET_PASSWORD,
      page: () => const ForgetPasswordScreen(),
      transition: Transition.cupertino,
      transitionDuration: const Duration(milliseconds: 300),
    ),

    // ✅ Dashboard Route - ใช้ BottomNav เป็นหน้าหลัก
    GetPage(
      name: AppRoutes.DASHBOARD,
      page: () => const BottomNav(),
      transition: Transition.fadeIn,
      transitionDuration: const Duration(milliseconds: 300),
    ),

    // Profile Page
    GetPage(
      name: AppRoutes.PROFILE,
      page: () => const ProfilePage(),
      transition: Transition.rightToLeft,
      transitionDuration: const Duration(milliseconds: 300),
    ),
    GetPage(
      name: AppRoutes.NOTIFICATION,
      page: () => const NotificationScreen(),
      transition: Transition.rightToLeft,
      transitionDuration: const Duration(milliseconds: 300),
    ),

    

  ];
}