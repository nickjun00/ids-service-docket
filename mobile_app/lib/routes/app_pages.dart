import 'package:get/get.dart';

import '../views/auth/login_screen.dart';
import '../views/home/home_screen.dart';

class AppPages {
  static const initial = '/login';

  static final routes = [
    GetPage(name: '/login', page: () => const LoginScreen()),
    GetPage(name: '/home', page: () => const HomeScreen()),
  ];
}
