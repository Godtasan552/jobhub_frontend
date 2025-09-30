abstract class AppRoutes {
  AppRoutes._();

  // กำหนดชื่อ routes ทั้งหมด
  static const SPLASH = '/'; // เปลี่ยนให้ splash เป็น initial route
  static const LOGIN = '/login';
  static const REGISTER = '/register';
  static const FORGET_PASSWORD = '/forget-password';
  static const HOME = '/home'; // สำหรับในอนาคต
  static const PROFILE = '/profile'; // สำหรับในอนาคต
  static const String DASHBOARD = '/dashboard';
  static const String JOB_DETAIL = '/job-detail';
  static const String CHAT = '/chat';

  // Helper methods สำหรับการนำทาง
  static String getSplashRoute() => SPLASH;
  static String getLoginRoute() => LOGIN;
  static String getRegisterRoute() => REGISTER;
  static String getForgetPasswordRoute() => FORGET_PASSWORD;
  static String getHomeRoute() => HOME;
  static String getProfileRoute() => PROFILE;
  static String getDashboardRoute() => DASHBOARD;
  static String getJobDetailRoute() => JOB_DETAIL;
  static String getChatRoute() => CHAT;
}
