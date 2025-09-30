import 'package:get/get.dart';
import 'app_routes.dart';

import '../screens/splash_screen.dart';
import '../screens/login.dart';
import '../screens/regis.dart';
import '../screens/forget_pass.dart';
import '../screens/dashboard_Screen.dart';
import '../component/bottom_nav.dart';
import '../screens/job_detail.dart';
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
    GetPage(
      name: AppRoutes.DASHBOARD,
      page: () => const BottomNav(),
      transition: Transition.fadeIn,
      transitionDuration: const Duration(milliseconds: 300),

    ),
    GetPage(
      name: AppRoutes.DASHBOARD,
      page: () => const DashboardScreen(),  // ✅ เปลี่ยนชื่อ
      transition: Transition.fadeIn,
      transitionDuration: const Duration(milliseconds: 300),

    ),

    // Detail Page
   GetPage(
      name: AppRoutes.JOB_DETAIL,
      page: () => const job_detail(),
      transition: Transition.rightToLeft,
      transitionDuration: const Duration(milliseconds: 300),
        
    ),
    // อนาคตสามารถเพิ่ม routes อื่นๆ ได้ที่นี่
    /*
    GetPage(
      name: AppRoutes.HOME,
      page: () => const HomeScreen(),
      transition: Transition.zoom,
      transitionDuration: const Duration(milliseconds: 300),
    ),
    
    GetPage(
      name: AppRoutes.PROFILE,
      page: () => const ProfileScreen(),
      transition: Transition.rightToLeft,
      transitionDuration: const Duration(milliseconds: 300),
    ),
    */
  ];
}
